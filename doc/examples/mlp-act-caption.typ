#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-mlp((
  3,
  mlp-layer(5, activation: "tanh"),
  mlp-layer(2, activation: [linear, clipped]),
))
