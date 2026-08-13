#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-mlp((
  mlp-layer(4, name: "in"),
  mlp-layer(6, name: "h1"),
  mlp-layer(6, name: "h2"),
  mlp-layer(4, name: "out"),
), edges: (
  mlp-edge(from: "in", to: "h2", sum: true, label: "identity"),
))
