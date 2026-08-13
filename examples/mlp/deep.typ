#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 6mm)

// A deep stack drawn shallow. The gap column elides four identical blocks,
// a long residual skip rejoins through a summation node, and the first
// block feeds itself through a recurrent loop.
#draw-mlp((
  mlp-layer(4, label: "input", name: "in"),
  mlp-layer(8, label: "block 1", name: "b1"),
  mlp-gap(label: [$times 4$ blocks]),
  mlp-layer(8, label: "block 6", name: "b6"),
  mlp-layer(3, label: "output", name: "out"),
),
  cutoff: 6,
  edges: (
    mlp-edge(from: "in", to: "b6", style: "arc-below", sum: true,
      label: [residual]),
    mlp-edge(from: "b1", to: "b1", label: [recurrent]),
  ),
)
