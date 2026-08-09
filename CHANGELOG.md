# Changelog

## 0.1.1

### Breaking

- Plain dictionaries are no longer accepted as layers, connections or groups.
  Every layer is written with its constructor, so `(type: "conv", label: "a")`
  becomes `conv(label: "a")`, and connections and groups are written as
  `connection(from: .., to: ..)` and `group(from: .., to: ..)`. A dictionary in
  any of those positions is now an error naming the constructor to use. A
  dictionary of options still spreads into a constructor as `conv(..opts)`,
  which is the intended form for generated figures.

### Internal

- `src/lib.typ` is split into focused modules (keys, validate, ctor, theme,
  geom, primitives, layers, routing, legend, import, draw), with `lib.typ` as
  a thin re-export. The public surface and every rendered figure are unchanged;
  the golden-image suite is pixel-identical against 0.1.0.

## 0.1.0

First release. Layered neural network architectures drawn as isometric block
diagrams, sized from their tensor shapes.

### Design decisions

- Arrows and connections are black.
- The sum node is a flat white disc with a black outline.
- `offset`, `pos` and `arrive-offset` default to `auto`, so spacing, lane
  heights and arrival points are computed from the drawing rather than stated.
- A `custom` layer shows an activation band only when it declares a `bandfill`
  or opts in with `show-relu`.
- Layer labels anchor on their baseline, so descenders do not shift a label out
  of line.
