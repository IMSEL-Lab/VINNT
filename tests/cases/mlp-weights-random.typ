#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

// deterministic LCG weights; the golden pins the exact hash sequence
#draw-mlp((3, 5, 4, 2), weights: "random")

#v(8mm)

// a different seed must give a different figure
#draw-mlp((3, 5, 4, 2), weights: "random", seed: 7)
