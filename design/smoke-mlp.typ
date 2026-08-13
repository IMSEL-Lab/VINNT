// Scratch smoke sheet for the draw-mlp implementation. Deleted before release.
#import "../src/lib.typ": draw-mlp, mlp-layer, mlp-gap, mlp-edge, mlp-palettes

#set page(width: auto, height: auto, margin: 6mm)

// Tier 0 - bare counts
#draw-mlp((4, 6, 6, 3))

// Tier 1 - figure-wide options
#draw-mlp((4, 16, 16, 3), activation: "relu", bias: true, cutoff: 8)

// Tier 2 - per-layer constructors (the fig5 target)
#draw-mlp((
  mlp-layer(4,  label: "input"),
  mlp-layer(8,  label: "h1", activation: "relu"),
  mlp-layer(8,  label: "h2", activation: "relu"),
  mlp-layer(3,  label: "output", activation: "softmax"),
), bias: true, cutoff: 6)

// Tier 3 - hooks and data
#draw-mlp((4, 8, 3),
  weights: (l, i, j) => calc.sin(l * 7 + i * 3 + j * 1.7),
  node-label: (l, i) => $a_#i^((#l))$,
  edge-style: (l, i, j) => if i == j { (dash: "dashed") },
)
