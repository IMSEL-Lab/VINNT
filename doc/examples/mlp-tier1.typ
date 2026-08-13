#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-mlp((4, 16, 16, 3), activation: "relu", bias: true, cutoff: 8)
