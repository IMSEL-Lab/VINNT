#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

// an elision column: three dots, faded stubs, caption in the label row
#draw-mlp((4, mlp-layer(6), mlp-gap(label: [$times$ 6 layers]), mlp-layer(6), 3))

#v(8mm)

// custom gap pitch; the layer before a gap draws no bias node
#draw-mlp((3, mlp-layer(4), mlp-gap(pitch: 2.0), 4, 2), bias: true)
