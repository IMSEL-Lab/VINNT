#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network(
  (
    conv(name: "a"), conv(name: "b"), conv(name: "c"),
    conv(name: "d"), conv(name: "e"),
  ),
  connections: (
    connection(from: "a", to: "e"),
    connection(from: "b", to: "d"),
    connection(from: "c", to: "d"),
  ),
)
