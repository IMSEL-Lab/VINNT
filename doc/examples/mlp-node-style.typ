#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-mlp((
  4,
  mlp-layer(6, node-style: i => if i == 3 {
    (fill: rgb("#CED318"), size: 0.24)
  }),
  3,
))
