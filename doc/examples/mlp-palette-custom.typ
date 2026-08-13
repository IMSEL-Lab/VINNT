#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-mlp((
  mlp-layer(4),
  mlp-layer(6, fill: rgb("#CED318").lighten(45%)),
  mlp-layer(3),
), palette: (
  output: rgb("#65780B").lighten(55%),
  accent: rgb("#65780B"),
))
