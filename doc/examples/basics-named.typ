#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network(
  (
    conv(name: "a", label: "a"),
    conv(name: "b", label: "b"),
    conv(name: "c", label: "c"),
  ),
  connections: (connection(from: "a", to: "c"),),
  groups: (group(from: "a", to: "b", label: "pair"),),
)
