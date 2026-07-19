#!/usr/bin/env python3
"""Guard active followup state around Codex compaction lifecycle hooks."""

from __future__ import annotations

import json
import os
import hashlib
import sys
import time
from pathlib import Path
from typing import Any


ACTIVE_DIR = Path("docs/followup/active")
STATE_DIR = ACTIVE_DIR / ".state"
MARKER_FILE = STATE_DIR / "followup-compact-guard.json"
MARKER_TTL_SECONDS = 15 * 60


def load_hook_input() -> dict[str, Any]:
    raw = sys.stdin.read()
    if not raw.strip():
        return {}
    try:
        value = json.loads(raw)
    except json.JSONDecodeError:
        return {}
    return value if isinstance(value, dict) else {}


def find_repo_root(cwd: str | None = None) -> Path:
    start = Path(cwd or os.getcwd()).resolve()
    for candidate in (start, *start.parents):
        if (candidate / ".git").exists():
            return candidate
    return start


def active_files(root: Path) -> list[Path]:
    active_dir = root / ACTIVE_DIR
    if not active_dir.exists():
        return []
    return sorted(
        path
        for path in active_dir.glob("*.md")
        if path.name != ".gitkeep" and not path.name.startswith(".")
    )


def relative(path: Path, root: Path) -> str:
    try:
        return path.relative_to(root).as_posix()
    except ValueError:
        return path.as_posix()


def file_digest(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def file_fingerprint(path: Path, root: Path) -> dict[str, Any]:
    result: dict[str, Any] = {
        "path": relative(path, root),
        "exists": path.exists(),
    }
    if not path.exists():
        return result
    if not path.is_file():
        result["type"] = "non_file"
        return result
    stat = path.stat()
    result.update(
        {
            "type": "file",
            "size": stat.st_size,
            "mtime_ns": stat.st_mtime_ns,
            "sha256": file_digest(path),
        }
    )
    return result


def scope_file_for(active_file: Path) -> Path:
    return active_file.with_suffix(".scope")


def load_scope_paths(root: Path, active_file: Path) -> tuple[Path | None, list[Path], str | None]:
    scope_file = scope_file_for(active_file)
    if not scope_file.exists():
        return None, [], None
    if not scope_file.is_file():
        return scope_file, [], "scope path is not a file"

    watched: list[Path] = []
    try:
        lines = scope_file.read_text(encoding="utf-8").splitlines()
    except OSError as exc:
        return scope_file, [], f"scope file cannot be read: {exc}"

    for raw_line in lines:
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        candidate = Path(line)
        if candidate.is_absolute():
            try:
                candidate.resolve().relative_to(root)
            except ValueError:
                return scope_file, [], f"scope path is outside repository: {line}"
            watched.append(candidate.resolve())
            continue
        watched.append((root / candidate).resolve())

    return scope_file, watched, None


def watched_fingerprints(root: Path, active_file: Path) -> tuple[Path | None, list[dict[str, Any]], str | None]:
    scope_file, watched_paths, error = load_scope_paths(root, active_file)
    if error:
        return scope_file, [], error

    paths = [active_file]
    if scope_file is not None:
        paths.append(scope_file)
    paths.extend(watched_paths)

    unique: dict[str, Path] = {}
    for path in paths:
        unique[relative(path, root)] = path
    return scope_file, [file_fingerprint(path, root) for path in unique.values()], None


def emit_hook(payload: dict[str, Any]) -> int:
    print(json.dumps(payload, ensure_ascii=False))
    return 0


def marker_status(root: Path, active_file: Path) -> tuple[bool, str]:
    marker = root / MARKER_FILE
    try:
        data = json.loads(marker.read_text(encoding="utf-8"))
    except (FileNotFoundError, json.JSONDecodeError, OSError):
        return False, "marker missing or unreadable"

    marked_at = data.get("marked_at_epoch")
    if not isinstance(marked_at, int) or int(time.time()) - marked_at > MARKER_TTL_SECONDS:
        return False, "marker expired"

    if data.get("active_file") != relative(active_file, root):
        return False, "active followup changed"

    scope_file, current_fingerprints, error = watched_fingerprints(root, active_file)
    if error:
        return False, error

    if data.get("scope_file") != (relative(scope_file, root) if scope_file else None):
        return False, "scope file changed"
    if data.get("watched_files") != current_fingerprints:
        return False, "active followup scope changed"

    return True, "marked"


def marker_valid(root: Path, active_file: Path) -> bool:
    return marker_status(root, active_file)[0]


def write_marker(root: Path, active_file: Path) -> None:
    scope_file, fingerprints, error = watched_fingerprints(root, active_file)
    if error:
        raise RuntimeError(error)

    marker = root / MARKER_FILE
    marker.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "active_file": relative(active_file, root),
        "scope_file": relative(scope_file, root) if scope_file else None,
        "watched_files": fingerprints,
        "marked_at_epoch": int(time.time()),
        "meaning": "active followup and its scope were checked against the current recovery state",
    }
    marker.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def status(root: Path) -> int:
    files = active_files(root)
    if not files:
        print("active followup: none")
        return 0
    if len(files) > 1:
        print("active followup: multiple")
        for path in files:
            print(f"- {relative(path, root)}")
        return 1

    active_file = files[0]
    valid, reason = marker_status(root, active_file)
    state = "marked" if valid else f"unmarked: {reason}"
    print(f"active followup: {relative(active_file, root)} ({state})")
    return 0


def mark(root: Path) -> int:
    files = active_files(root)
    if not files:
        print("active followup: none; nothing to mark")
        return 0
    if len(files) > 1:
        print("active followup: multiple; resolve to one active file before marking")
        for path in files:
            print(f"- {relative(path, root)}")
        return 1

    try:
        write_marker(root, files[0])
    except RuntimeError as exc:
        print(f"active followup cannot be marked: {exc}")
        return 1
    print(f"active followup marked: {relative(files[0], root)}")
    return 0


def hook_response(mode: str, root: Path) -> int:
    files = active_files(root)
    if not files:
        return emit_hook({"continue": True})

    if len(files) > 1:
        paths = ", ".join(relative(path, root) for path in files)
        return emit_hook(
            {
                "continue": False,
                "stopReason": "multiple active followup files",
                "systemMessage": (
                    "active followup 파일이 여러 개입니다. 새 작업을 진행하기 전에 "
                    f"`docs/followup/active/`를 하나의 active 파일로 정리하세요: {paths}"
                ),
            }
        )

    active_file = files[0]
    active_path = relative(active_file, root)

    if mode == "pre-compact":
        valid, reason = marker_status(root, active_file)
        if valid:
            return emit_hook({"continue": True})
        if "outside repository" in reason or "not a file" in reason or "cannot be read" in reason:
            return emit_hook(
                {
                    "continue": False,
                    "stopReason": "active followup scope is invalid",
                    "systemMessage": (
                        "context compact 전에 active followup scope 상태를 확인할 수 없습니다. "
                        f"`{active_path}`와 같은 이름의 `.scope` 파일을 정리한 뒤 "
                        "`followup-handoff` 절차로 복구 상태를 확인하고 "
                        "`python3 .codex/hooks/followup_compact_guard.py mark`를 실행하세요. "
                        f"사유: {reason}"
                    ),
                }
            )
        return emit_hook(
            {
                "continue": True,
                "stopReason": "active followup should be checked before compact",
                "systemMessage": (
                    "context compact 전에 active followup 또는 scope 대상이 최신 marker와 다릅니다. "
                    f"`{active_path}`를 `followup-handoff` 절차로 확인하고, 현재 목표·제약·상태·다음 작업이 "
                    "복구 가능한지 대조한 뒤 필요하면 갱신하세요. "
                    "복구 상태가 맞으면 `python3 .codex/hooks/followup_compact_guard.py mark`를 실행하세요. "
                    f"사유: {reason}"
                ),
            }
        )

    if mode == "post-compact":
        return emit_hook(
            {
                "continue": True,
                "systemMessage": (
                    "context compact 이후에는 작업 도구를 사용하기 전에 "
                    f"`{active_path}`를 먼저 읽고, 압축 요약과 목표·제약·현재 상태·다음 작업을 대조하세요."
                ),
            }
        )

    if mode == "session-start":
        message = (
            "세션 시작 또는 재개 시 active followup이 있습니다. 작업 도구를 사용하기 전에 "
            f"`{active_path}`를 먼저 읽고, 현재 세션 요약과 목표·제약·현재 상태·다음 작업을 대조하세요."
        )
        return emit_hook(
            {
                "continue": True,
                "systemMessage": message,
                "hookSpecificOutput": {
                    "hookEventName": "SessionStart",
                    "additionalContext": message,
                },
            }
        )

    return emit_hook({"continue": True})


def main() -> int:
    mode = sys.argv[1] if len(sys.argv) > 1 else "status"
    hook_input = load_hook_input()
    root = find_repo_root(hook_input.get("cwd"))

    if mode == "status":
        return status(root)
    if mode == "mark":
        return mark(root)
    if mode in {"pre-compact", "post-compact", "session-start"}:
        return hook_response(mode, root)

    print(f"unknown mode: {mode}", file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
