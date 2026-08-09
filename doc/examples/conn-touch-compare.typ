#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network(
  (
    conv(name: "a", label: "a"),
    conv(name: "b", label: "b"),
    concat(name: "cat", label: "concat", depth: 5),
  ),
  connections: (
    connection(from: "a", to: "cat"),
    connection(from: "b", to: "cat", touch-layer: true),
  ),
)
