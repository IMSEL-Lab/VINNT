// FIGURE 5 — a standalone MLP for a lecture slide.
//
// TARGET API — the MLP-only convenience form:
//
//   #draw-mlp((
//     layer(4,   label: "input"),
//     layer(8,   label: "h1", activation: "ReLU"),
//     layer(8,   label: "h2", activation: "ReLU"),
//     layer(3,   label: "output", activation: "softmax"),
//   ), bias: true, ellipsis-cutoff: 6)
//
// Design notes.
//   - `ellipsis-cutoff` is figure-wide, borrowed from nndiagram's `size.cutoff`.
//     Layers wider than the cutoff collapse automatically. Compare the 8-wide
//     hidden layers below against the 4-wide input: no per-layer flag was set.
//   - `bias: true` adds the bias node row. neuralnetwork.sty treats this as
//     first-class (`toprow`, `biaspos`) and it is a nuisance to add later.
//   - Open question: is this a separate entry point, or is it
//     `draw-network((mlp(layers: (4,8,8,3)),), view: "graph")`? See fig 4.

#import "@preview/cetz:0.5.2": canvas
#import "mock.typ": *

#set page(width: auto, height: auto, margin: 6mm)

#canvas(length: 1cm, {
  let xs = (0, 2.2, 4.4, 6.6)
  let counts = (4, 8, 8, 3)
  let labels = ("input", "h1", "h2", "output")
  let fills = (c-sand, c-10black, c-10black, c-atlantic.lighten(65%))

  let cols = counts.map(c => neuron-slots(c, cutoff: 6).nodes)

  // edges first, so the nodes paint over them
  for i in range(xs.len() - 1) {
    connect-columns(xs.at(i), cols.at(i), xs.at(i + 1), cols.at(i + 1))
  }

  for (i, x) in xs.enumerate() {
    neuron-column(x, counts.at(i), cutoff: 6, fill: fills.at(i), label: labels.at(i))
  }

  // activation annotations
  content((2.2, 1.85), text(size: 6.5pt, fill: c-70black)[ReLU])
  content((4.4, 1.85), text(size: 6.5pt, fill: c-70black)[ReLU])
  content((6.6, 1.85), text(size: 6.5pt, fill: c-70black)[softmax])

  // width badges, since the collapsed columns no longer show true counts
  for (i, x) in xs.enumerate() {
    content((x, -1.9), text(size: 6pt, fill: c-70black)[#counts.at(i)])
  }
})
