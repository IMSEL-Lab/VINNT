#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network(
  (conv(name: "a"), conv(name: "b"), conv(name: "c")),
  connections: (connection(from: "a", to: "c", mode: "flat"),),
  groups: (group(from: "a", to: "c", label: "backbone"),),
)
