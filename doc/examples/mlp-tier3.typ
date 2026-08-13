#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-mlp((4, 8, 3),
  weights: json("w.json"),
  node-label: (l, i) => $a_#i^((#l))$,
  edge-style: (l, i, j) => if i == j { (dash: "dashed") },
)
