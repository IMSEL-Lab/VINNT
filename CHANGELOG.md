# Changelog

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
