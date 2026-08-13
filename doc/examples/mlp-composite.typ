#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-mlp((
  mlp-layer(4,  label: "input"),
  mlp-layer(12, label: "dense", activation: "relu"),
  mlp-layer(12, label: "dense", activation: "relu"),
  mlp-layer(3,  label: "softmax"),
), cutoff: 8, bias: true, weights: "random",
   io-stubs: true, title: "A classifier, weights shown")
