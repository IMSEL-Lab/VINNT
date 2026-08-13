#!/usr/bin/env python3
"""Error-contract harness for vinnt.

Every file in tests/error-cases/ must fail to compile, and must fail for the
declared reason: its first line is a comment `// EXPECT: <substring of the
error message>`. The harness compiles each case, asserts a nonzero exit
status, and asserts the substring appears in the compiler's stderr. Typos are
errors, not silence; this suite is what holds the package to that.

Kept separate from regress.py so the golden harness stays a pure pixel diff.
Plain stdlib only, so it runs under python3 with or without uv.

Usage:
    python3 tests/check_errors.py                # check every error case
    python3 tests/check_errors.py typo-option    # check a subset by name

Exit status is 0 when every case fails the way it declares, 1 otherwise.
"""

import pathlib
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
CASES = ROOT / "tests" / "error-cases"
MARKER = "// EXPECT:"


def cases(selectors):
    found = sorted(CASES.glob("*.typ"))
    if selectors:
        found = [p for p in found if p.stem in selectors]
        missing = set(selectors) - {p.stem for p in found}
        for name in sorted(missing):
            print(f"  no such case: {name}")
    return found


def first_error_line(stderr):
    for line in stderr.splitlines():
        if line.startswith("error:"):
            return line
    return stderr.strip().splitlines()[0] if stderr.strip() else "(empty stderr)"


def check(src, outdir):
    """Compile one case and hold it to its declaration. Returns (status, detail)."""
    first = src.read_text().splitlines()[0]
    if not first.startswith(MARKER):
        return "BADCASE", f"first line must be `{MARKER} <substring>`"
    expect = first[len(MARKER):].strip()
    if not expect:
        return "BADCASE", f"`{MARKER}` declares an empty substring"

    out = pathlib.Path(outdir) / f"{src.stem}.png"
    proc = subprocess.run(
        ["typst", "compile", "--root", str(ROOT), "--format", "png",
         str(src), str(out)],
        capture_output=True, text=True,
    )
    if proc.returncode == 0:
        return "COMPILED", "expected a compile error, but compilation succeeded"
    if expect not in proc.stderr:
        return "MISMATCH", f"error lacks expected substring; got: {first_error_line(proc.stderr)}"
    return "OK", ""


def main():
    srcs = cases(set(sys.argv[1:]))
    if not srcs:
        print("no error cases matched")
        return 1

    width = max(len(s.stem) for s in srcs)
    failures = 0
    with tempfile.TemporaryDirectory() as outdir:
        for src in srcs:
            status, detail = check(src, outdir)
            if status != "OK":
                failures += 1
            print(f"  {status:<8} {src.stem:<{width}}  {detail}".rstrip())

    print()
    print(f"{len(srcs) - failures}/{len(srcs)} fail as declared")
    if failures:
        print("Each case must exit nonzero with its `// EXPECT:` substring in stderr.")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
