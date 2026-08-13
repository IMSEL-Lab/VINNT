#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-mlp((3, 4, 2), layer-pitch: 2.6, edges: (
  mlp-edge(from: "l1.2", to: "l2.3", paint: rgb("#73000A"),
    thickness: 1.1pt, opacity: 100%, label: $w_(32)$),
  mlp-edge(from: "l1.3", to: "l3.2", style: "arc-below",
    dash: "dashed"),
))
