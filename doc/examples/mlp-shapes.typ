#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-mlp((
  mlp-layer(3, shape: "square"),
  mlp-layer(4, shape: "split", activation: "relu"),
  mlp-layer(2),
), node-size: 0.24,
   node-stroke: (paint: rgb("#363636"), thickness: 1pt))
