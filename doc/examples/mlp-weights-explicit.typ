#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-mlp((2, 3, 2),
  weights: (
    ((0.9, -0.4), (0.2, 0.8), (-0.7, 0.3)),
    ((1.0, -0.5, 0.6), (0.3, 0.9, -0.8)),
  ),
  weight-colors: (positive: rgb("#65780B"), negative: rgb("#73000A")),
  weight-thickness: (0.3pt, 1.6pt),
  node-size: 0.22, layer-pitch: 2.6)
