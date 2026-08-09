#!/usr/bin/env bash
# Assemble the Typst Universe submission bundle.
#
# Universe is a monorepo you open a pull request against, not a registry you
# push to. A package lives at packages/preview/<name>/<version>/, and that path
# *is* the import: packages/preview/vinnt/0.1.0 becomes
# `#import "@preview/vinnt:0.1.0"`. Nothing else configures it.
#
# What gets published is the package, not the repository. This script builds it:
#
#   dist/packages/preview/vinnt/<version>/
#   ├── typst.toml
#   ├── LICENSE
#   ├── README.md      <- rewritten, see below
#   └── src/
#
# The manual, gallery, examples, tests and tools stay out. Universe asks
# explicitly that README images and PDF documentation be excluded so downloads
# stay small, and the repository is ~67 MB against a bundle of a few hundred KB.
#
# The README is rewritten rather than copied. It renders on the Universe website
# and not on GitHub, so every relative path in it resolves to nothing there:
# `gallery/networks/YOLO26n.png` would be a broken image on the package page.
# The rewrite makes those absolute, pinned to a tag rather than to a branch --
# a published version's page must not change appearance because a file moved on
# main six months later.
#
#   tools/bundle.sh              build from the tag matching the manifest version
#   tools/bundle.sh main         build against a branch instead (for previewing)
#
# Nothing here publishes. It produces a directory to copy into a checkout of
# typst/packages and open a PR from.
set -euo pipefail

cd "$(dirname "$0")/.."

NAME=$(grep '^name' typst.toml | head -1 | cut -d'"' -f2)
VERSION=$(grep '^version' typst.toml | head -1 | cut -d'"' -f2)
REPO="j-vaught/VINNT"
REF="${1:-v$VERSION}"
RAW="https://raw.githubusercontent.com/$REPO/$REF"
BLOB="https://github.com/$REPO/blob/$REF"

OUT="dist/packages/preview/$NAME/$VERSION"
rm -rf dist
mkdir -p "$OUT"

cp typst.toml LICENSE "$OUT/"
cp -R src "$OUT/"

# Relative links become absolute, so they resolve on the Universe package page.
python3 - "$OUT/README.md" "$RAW" "$BLOB" <<'PY'
import pathlib, re, sys
out, raw, blob = sys.argv[1], sys.argv[2], sys.argv[3]
s = pathlib.Path("README.md").read_text()

# <img src="gallery/..."> and friends -> raw.githubusercontent
s = re.sub(r'(<img[^>]*\bsrc=")(?!https?://)([^"]+)', lambda m: m.group(1) + raw + "/" + m.group(2), s)
# markdown ![alt](path)
s = re.sub(r'(!\[[^\]]*\]\()(?!https?://)([^)]+)\)', lambda m: m.group(1) + raw + "/" + m.group(2) + ")", s)
# <a href="doc/..."> and [text](path) -> blob view
s = re.sub(r'(<a[^>]*\bhref=")(?!https?://|#)([^"]+)', lambda m: m.group(1) + blob + "/" + m.group(2), s)
s = re.sub(r'(?<!!)(\[[^\]]+\]\()(?!https?://|#)([^)]+)\)', lambda m: m.group(1) + blob + "/" + m.group(2) + ")", s)

pathlib.Path(out).write_text(s)
PY

# The bundle has to stand alone: no import may reach outside it.
if grep -rn '\.\./' "$OUT/src" >/dev/null 2>&1; then
  echo "FAIL: src/ imports outside the package" >&2
  exit 1
fi

# And it has to actually work when imported the way a user will import it.
SMOKE=$(mktemp -d)
cp -R "$OUT" "$SMOKE/pkg"
cat > "$SMOKE/smoke.typ" <<'TYP'
#import "pkg/src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
#draw-network((
  input(image: "default"),
  conv(shape: (64, 128, 128), label: "conv"),
  pool(),
  branch(spread: 6, branches: ((conv(label: "a"),), (conv(label: "b"),))),
  concat(label: "concat"),
), show-legend: true)
TYP
if typst compile --root "$SMOKE" "$SMOKE/smoke.typ" "$SMOKE/smoke.pdf" 2>"$SMOKE/err"; then
  echo "smoke test: ok"
else
  echo "FAIL: bundle does not compile standalone" >&2
  sed 's/^/  /' "$SMOKE/err" >&2
  exit 1
fi
rm -rf "$SMOKE"

# Anything still pointing at a relative path would be broken on Universe.
if grep -qE '(src|href)="(?!https?)[^"]*"' "$OUT/README.md" 2>/dev/null; then
  echo "warning: README may still contain relative links" >&2
fi

echo
echo "$OUT"
echo "  files: $(find "$OUT" -type f | wc -l | tr -d ' ')   size: $(du -sh "$OUT" | cut -f1)   ref: $REF"
echo
echo "To submit: copy dist/packages/ into a checkout of github.com/typst/packages"
echo "and open a pull request. Tag $REF must exist and be pushed first."
