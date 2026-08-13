#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-mlp((
  4,
  mlp-layer(6, activation: "relu"),
  mlp-gap(label: "× 6 identical layers", pitch: 1.4),
  mlp-layer(6, activation: "relu"),
  3,
))
