#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 6mm)

// The Rosenblatt perceptron. Inputs enter as labelled stub arrows, the bias
// rides above them, and the single unit is drawn split: summation on the
// left, the step nonlinearity on the right.
#draw-mlp((
  mlp-layer(4, label: "inputs"),
  mlp-layer(1, label: "step unit", activation: "step", node-size: 0.42),
),
  activation-style: "split",
  input-style: "arrows",
  bias: true,
  io-stubs: "out",
  layer-pitch: 2.6,
)
