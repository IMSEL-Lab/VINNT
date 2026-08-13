#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-mlp((
  mlp-layer(4, label: "features", sub: [$28 times 28$, flattened]),
  mlp-layer(6, label: "hidden", sub: "fully connected"),
  mlp-layer(3, label: "classes"),
))
