#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

// perceptron style: labelled stub arrows replace the layer-1 nodes
#draw-mlp((3, 4, 2), input-style: "arrows")

#v(8mm)

// io-stubs on the input side are suppressed under input arrows; arrowheads on
#draw-mlp((2, 3, 2), input-style: "arrows", io-stubs: true, arrows: "all")
