#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

// a partial dict overlays the brand palette
#draw-mlp((3, 4, 2), palette: (hidden: rgb("#CED318"), output: rgb("#A49137")))

#v(8mm)

// named palette plus a per-layer fill override on the hidden layer
#draw-mlp((3, mlp-layer(4, fill: rgb("#FFF2E3")), 2), palette: "cold")

#v(8mm)

#draw-mlp((3, 4, 2), palette: "warm")
