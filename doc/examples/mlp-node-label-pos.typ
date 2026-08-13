#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-mlp((
  mlp-layer(3, node-label: i => $x_#i$, node-label-pos: "left"),
  mlp-layer(4),
  mlp-layer(2, node-label: i => $p_#i$, node-label-pos: "right"),
))
