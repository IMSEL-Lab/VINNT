#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  conv(label: "in"),
  branch(spread: 4, branches: (
    (conv(label: "a"),),
    (conv(label: "b"),),
    (conv(label: "c"),),
  )),
  concat(label: "concat"),
))
