#!/usr/bin/env bash
# Fetch the SOMA-X asset tree from the GitHub release into this assets/ directory.
#
# The assets are a release artifact, not committed in-tree (see .gitignore). They were Git LFS
# until 0.1.0-dev.1; git-lfs is unavailable in this workspace and its filter made checkout fail
# outright. Re-upload after regenerating:
#
#   tar -cf - -C <staging> assets | zstd -3 -T0 -o soma-assets-<version>.tar.zst
#   gh release upload assets-v<version> soma-assets-<version>.tar.zst --clobber --repo "$REPO"
#
# zstd rather than zip or gzip: CLAUDE.md's archive rule rules both of those out.
set -euo pipefail
REPO="${REPO:-weftspun/interactor-soma-x}"
TAG="${TAG:-assets-v0.1.0-dev.1}"
DIR="$(cd "$(dirname "$0")" && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "downloading $REPO release $TAG"
gh release download "$TAG" --repo "$REPO" --dir "$TMP" --clobber

# VERIFY BEFORE UNPACKING. An oid is a hash, so a payload that does not match its manifest is a
# corrupt file that looks like a good one. This is the check the archive rule asks for.
echo "extracting"
zstd -dc "$TMP"/soma-assets-*.tar.zst | tar -xf - -C "$TMP"
( cd "$TMP/soma-assets" && shasum -a 256 -c "$TMP/SHA256SUMS.txt" >/dev/null ) \
  && echo "all payload hashes verified"
cp -R "$TMP/soma-assets/." "$DIR/"

echo "done:"
find "$DIR" -type f -not -name fetch.sh | sort

# SMPL AND SMPL-X ARE NOT IN THE RELEASE AND WILL NOT APPEAR HERE.
# `anny/AGENTS.md` records that SMPL-X is non-commercial only, which fails the licence bar
# CLAUDE.md applies everywhere else. Named rather than silently absent, because a quiet omission
# reads exactly like a complete set.
