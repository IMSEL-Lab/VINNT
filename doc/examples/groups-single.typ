#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network(
  (conv(name: "a"), conv(name: "b"), conv(name: "c")),
  groups: (group(from: "b", to: "b", label: "just this one"),),
)
