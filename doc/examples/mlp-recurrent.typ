#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-mlp((
  mlp-layer(3, name: "x"),
  mlp-layer(5, name: "h"),
  mlp-layer(2, name: "y"),
), edges: (mlp-edge(from: "h", to: "h", style: "loop"),))
