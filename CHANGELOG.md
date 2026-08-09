# Changelog

## 0.1.1

### Breaking

- Layers, connections and groups are written with their constructors only.
  `(type: "conv", label: "a")` becomes `conv(label: "a")`; connections and
  groups become `connection(from: .., to: ..)` and `group(from: .., to: ..)`.
  A plain dictionary in any of those positions is an error. A dictionary of
  options still spreads into a constructor as `conv(..opts)`.

### Internal

- `src/lib.typ` is split into focused modules with `lib.typ` as a thin
  re-export. Rendered output is unchanged.

## 0.1.0

First release.
