#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 6mm)

// The Goodfellow/AIMA textbook orientation. Information flows upward, the
// input layer is drawn as squares, the palette is monochrome, and each
// inter-layer gap carries its weight-matrix annotation.
#draw-mlp((4, 5, 3),
  direction: "up",
  input-style: "square",
  palette: (
    input: white,
    hidden: rgb("#ECECEC"),
    output: rgb("#C7C7C7"),
    bias: white,
    accent: black,
  ),
  matrix-labels: true,
  node-label: auto,
  node-size: 0.24,
  node-pitch: 0.66,
  layer-labels: auto,
)
