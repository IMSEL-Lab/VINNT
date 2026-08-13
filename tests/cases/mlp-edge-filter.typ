#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

// connectivity predicate: gap 1 keeps the diagonal only; one auto edge label
#draw-mlp((3, 3, 3),
  edge-filter: (l, i, j) => l == 2 or i == j,
  edge-labels: ((l: 1, i: 2, j: 2, label: auto),),
)

#v(8mm)

// the edge-style hook has the last word; custom label content
#draw-mlp((3, 3),
  edge-style: (l, i, j) => if i == j { (dash: "dashed", paint: rgb("#73000A"), opacity: 100%) },
  edge-labels: ((l: 1, i: 3, j: 1, label: $w_(1 3)$),),
)
