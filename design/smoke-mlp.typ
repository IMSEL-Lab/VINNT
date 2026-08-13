// Scratch smoke sheet for the draw-mlp implementation. Deleted before release.
#import "../src/mlp/ctor.typ": mlp-layer, mlp-gap, mlp-edge
#import "../src/mlp/validate.typ" as mval

#set page(width: auto, height: auto, margin: 6mm)

#let l = mlp-layer(8, label: "h1", activation: "relu", dropped: (2,))
#let g = mlp-gap(label: [x 6])
#let e = mlp-edge(from: "l1.2", to: "l3.1", label: $w$)
#repr(l.type) — #repr(g.type) — #repr(e.type)
