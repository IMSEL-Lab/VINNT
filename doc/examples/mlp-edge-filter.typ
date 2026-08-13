#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-mlp((4, 4, 4),
  edge-filter: (l, i, j) => l == 1 or i == j)
