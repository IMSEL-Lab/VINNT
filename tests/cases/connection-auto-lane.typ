#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

#let layer(n) = conv(widths: (0.3,), height: 2.5, depth: 2.5, name: "l" + str(n), offset: 1.0)

#draw-network(
  range(1, 9).map(layer),
  connections: (
    connection(from: "l1", to: "l8", type: "skip", pos: auto),
    connection(from: "l2", to: "l4", type: "skip", pos: auto),
    connection(from: "l5", to: "l7", type: "skip", pos: auto),
    connection(from: "l3", to: "l6", type: "skip", pos: auto),
  ),
)

#v(8mm)

#draw-network(range(1, 8).map(layer), connections: (
  connection(from: "l1", to: "l4", type: "skip", pos: auto),
  connection(from: "l3", to: "l6", type: "skip", pos: auto),
))
