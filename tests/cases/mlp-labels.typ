#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

// role-based auto node labels, auto layer captions, a title
#draw-mlp((3, 4, 2), node-label: auto, layer-labels: auto, title: [A small MLP])

#v(8mm)

// io stubs both sides, matrix labels in the gaps, a sub caption line
#draw-mlp((
  mlp-layer(3, label: "in", sub: [$RR^3$]),
  mlp-layer(4),
  mlp-layer(2),
), io-stubs: true, matrix-labels: true)

#v(8mm)

// per-layer node-label functions placed beside the nodes
#draw-mlp((
  mlp-layer(2, node-label: i => $u_#i$, node-label-pos: "left"),
  mlp-layer(3),
  mlp-layer(2, node-label: i => $z_#i$, node-label-pos: "right"),
))

#v(8mm)

// in-node ink: an explicit hidden-text on the untouched dark hidden fill,
// while the dark blues outputs take the automatic white flip
#draw-mlp((3, 4, 2), palette: (hidden: rgb("#1F414D"), hidden-text: rgb("#CED318")), node-label: auto)
