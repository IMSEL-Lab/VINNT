#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 6mm)

// TensorFlow-Playground look. Deterministic random weights encoded in edge
// color (blue positive, rose negative) and thickness, stub arrows carrying
// the inputs in and the prediction out, and role-based node labels.
#draw-mlp((4, 6, 6, 2),
  weights: "random",
  seed: 7,
  io-stubs: true,
  stub-labels: none,
  node-label: auto,
  node-size: 0.24,
  node-pitch: 0.66,
  layer-labels: auto,
  title: [Random initialization, seed 7],
)
