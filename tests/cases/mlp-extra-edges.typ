#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

// layer-level skip arc into a sum node, a recurrent loop, and one restyled
// adjacent edge with a label
#draw-mlp((3, 4, 4, 4, 3), edges: (
  mlp-edge(from: "l2", to: "l2"),
  mlp-edge(from: "l3", to: "l5", sum: true),
  mlp-edge(from: (1, 2), to: (2, 1), paint: rgb("#CC2E40"), thickness: 1.2pt, label: $w$),
))

#v(8mm)

// node-level skip routed below the network
#draw-mlp((3, 4, 3), edges: (
  mlp-edge(from: "l1.3", to: "l3.3", style: "arc-below"),
))
