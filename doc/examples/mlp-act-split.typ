#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-mlp((
  3,
  mlp-layer(4, activation: "relu"),
  mlp-layer(2, activation: "sigmoid"),
), activation-style: "split")
