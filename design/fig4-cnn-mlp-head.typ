// FIGURE 4 — CNN backbone flattening into an MLP classifier head.
//
// The mixed-vocabulary case. Two renderers, one figure, one arrow crossing
// between them, one shared baseline.
//
// TARGET API — mlp() as a LAYER CONSTRUCTOR, not a separate drawing function:
//
//   #draw-network((
//     input(image: "default", name: "img"),
//     conv(shape: (64, 128, 128), name: "c1"),
//     pool(name: "p1"),
//     conv(shape: (256, 32, 32), name: "c2"),
//     gap(name: "gap"),
//     mlp(layers: (128, 64, 10), name: "head", label: "classifier"),
//   ))
//
// This is the strongest argument for the composable design. If `draw-mlp` were
// a separate top-level function with its own canvas, this figure would require
// aligning two independent outputs by hand — exactly what people do today in
// Inkscape, and exactly what the library should abolish.
//
// Consequence: `draw-mlp()` should be the thin wrapper (fig 5), and `mlp()` the
// primitive. Not the other way round.
//
// Open question this figure raises: the neuron column has no depth, so what
// does it mean for it to sit on the isometric baseline? Below, the columns are
// centred on the trunk axis and the connecting arrow lands on the first column.
// That reads acceptably. Whether it survives a taller backbone is untested.

#import "@preview/cetz:0.5.2": canvas
#import "mock.typ": *

#set page(width: auto, height: auto, margin: 6mm)

#canvas(length: 1cm, {
  let y = 0

  // ---- isometric trunk ----
  prism(0.0, y, w: 0.35, h: 2.4, d: 0.85, fill: rgb("#CDEDFE"), label: "conv1", sub: "64")
  prism(1.3, y, w: 0.3, h: 2.0, d: 0.7, fill: rgb("#af78e6"), label: "pool")
  prism(2.5, y, w: 0.55, h: 1.7, d: 0.6, fill: rgb("#CDEDFE"), label: "conv2", sub: "128")
  prism(4.0, y, w: 0.3, h: 1.4, d: 0.5, fill: rgb("#af78e6"), label: "pool")
  prism(5.2, y, w: 0.75, h: 1.15, d: 0.4, fill: rgb("#CDEDFE"), label: "conv3", sub: "256")
  prism(7.0, y, w: 0.25, h: 0.6, d: 0.22, fill: rgb("#FF69B4"), label: "gap")

  for (a, b) in ((0.75, 1.25), (2.05, 2.45), (3.4, 3.95), (4.75, 5.15), (6.4, 6.95)) {
    line((a, y), (b, y), stroke: (paint: black, thickness: 0.8pt), mark: stealth(black))
  }

  // ---- the crossing ----
  line((7.5, y), (8.5, y), stroke: (paint: c-garnet, thickness: 1.1pt), mark: stealth(c-garnet))
  content((8.0, y + 0.32), text(size: 6.5pt, fill: c-garnet)[flatten])

  // ---- graph head ----
  let xs = (9.0, 10.7, 12.4)
  let counts = (128, 64, 10)
  let labels = ("fc1", "fc2", "logits")
  let fills = (c-10black, c-10black, c-atlantic.lighten(65%))

  let cols = counts.map(c => neuron-slots(c, cutoff: 6).nodes)
  for i in range(xs.len() - 1) {
    connect-columns(xs.at(i), cols.at(i), xs.at(i + 1), cols.at(i + 1))
  }
  for (i, x) in xs.enumerate() {
    neuron-column(x, counts.at(i), cutoff: 6, fill: fills.at(i), label: labels.at(i))
  }
  for (i, x) in xs.enumerate() {
    content((x, -1.85), text(size: 6pt, fill: c-70black)[#counts.at(i)])
  }

  content((10.7, 1.85), text(size: 7.5pt, fill: c-70black)[classifier head])
})
