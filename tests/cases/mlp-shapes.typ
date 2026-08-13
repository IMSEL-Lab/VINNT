#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

// per-layer shapes: square input, split hidden (f in the right half), circle out
#draw-mlp((
  mlp-layer(3, shape: "square"),
  mlp-layer(4, shape: "split"),
  mlp-layer(2),
))

#v(8mm)

// input-style square renders layer 1 as squares (AIMA)
#draw-mlp((3, 4, 2), input-style: "square")

#v(8mm)

// figure-wide square nodes
#draw-mlp((3, 3), node-shape: "square")
