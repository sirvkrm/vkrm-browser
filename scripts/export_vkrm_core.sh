#!/usr/bin/env bash
set -euo pipefail
SRC_ROOT=${SRC_ROOT:-/vkrmbrowser/src}
CORE_ROOT=${CORE_ROOT:-/vkrmbrowser/publish/vkrm-core}
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT
cd "$SRC_ROOT"
git diff --name-only > "$TMPDIR/changed.txt"
git ls-files --others --exclude-standard > "$TMPDIR/untracked.txt"
mkdir -p "$CORE_ROOT/manifests"
cp "$TMPDIR/changed.txt" "$CORE_ROOT/manifests/changed-files.txt"
cp "$TMPDIR/untracked.txt" "$CORE_ROOT/manifests/untracked-files.txt"
python3 - "$SRC_ROOT" "$CORE_ROOT" "$TMPDIR/changed.txt" "$TMPDIR/untracked.txt" <<'PY'
from pathlib import Path
import shutil, sys
src=Path(sys.argv[1]); dst=Path(sys.argv[2])
paths=[]
for listfile in sys.argv[3:]:
    for line in Path(listfile).read_text().splitlines():
        if line.strip():
            paths.append(line.strip())
seen=set()
for rel in paths:
    if rel in seen: continue
    seen.add(rel)
    sp=src/rel
    if not sp.exists():
        continue
    dp=dst/rel
    dp.parent.mkdir(parents=True, exist_ok=True)
    if sp.is_dir():
        shutil.copytree(sp, dp, dirs_exist_ok=True)
    else:
        shutil.copy2(sp, dp)
PY
