#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-mlp((
  4,
  mlp-layer(6, activation: "relu"),
  mlp-layer(3, activation: "softmax", label: "classes"),
), activation-style: "glyph", node-size: 0.22)
