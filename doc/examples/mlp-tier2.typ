#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-mlp((
  mlp-layer(4,  label: "input"),
  mlp-layer(8,  label: "h1", activation: "relu"),
  mlp-layer(8,  label: "h2", activation: "relu"),
  mlp-layer(3,  label: "output", activation: "softmax"),
), bias: true, cutoff: 6)
