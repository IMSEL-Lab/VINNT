#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-mlp((
  mlp-layer(4),
  mlp-layer(6, dropped: (2,), dimmed: (4,),
               highlighted: (5,), exclude: (6,)),
  mlp-layer(3),
))
