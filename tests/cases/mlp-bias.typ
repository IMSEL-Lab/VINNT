#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

#draw-mlp((3, 4, 2), bias: true)

#v(8mm)

// per-layer opt-out on layer 2, custom bias label; never on the last layer
#draw-mlp((3, mlp-layer(4, bias: false), 4, 2), bias: true, bias-label: $b$)
