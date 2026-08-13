#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

// a partial dict overlays the default palette
#draw-mlp((3, 4, 2), palette: (hidden: rgb("#CED318"), output: rgb("#A49137")))

#v(8mm)

// named palette plus a per-layer fill override on the hidden layer
#draw-mlp((3, mlp-layer(4, fill: rgb("#FFF2E3")), 2), palette: "cold")

#v(8mm)

#draw-mlp((3, 4, 2), palette: "warm")

#v(8mm)

// the monochrome ladder, its teal-accented variant, and the lilaq cycle
#draw-mlp((3, 4, 2), palette: "greys")

#v(8mm)

#draw-mlp((3, 4, 2), palette: "teal")

#v(8mm)

#draw-mlp((3, 4, 2), palette: "lilaq")

#v(8mm)

// every fill white: the uncolored textbook line-art figure
#draw-mlp((3, 4, 2), palette: "white")
