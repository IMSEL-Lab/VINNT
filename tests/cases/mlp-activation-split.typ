#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

// split style forces the Sigma-then-glyph shape on layers with an activation
#draw-mlp((2, 3, 2), activation: "relu", activation-style: "split")

#v(8mm)

// softmax under split has no curve: circle nodes plus the bracket
#draw-mlp((
  mlp-layer(2),
  mlp-layer(3, activation: "tanh"),
  mlp-layer(3, activation: "softmax"),
), activation-style: "split")
