#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network(
  (
    conv(name: "a", label: "a"), conv(name: "b", label: "b"),
    conv(name: "c", label: "c"),
    concat(name: "cat", label: "concat", depth: 6),
  ),
  connections: (
    connection(from: "a", to: "cat", touch-layer: true),
    connection(from: "b", to: "cat", touch-layer: true),
    connection(from: "c", to: "cat", touch-layer: true),
  ),
)
