#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

// pos: auto clears the tallest layer and takes each route's height from its
// ranked reach, so longer routes arc over shorter ones.
//
// The spans below cover the three interval relationships:
//   l1 -> l8   spans everything
//   l2 -> l4   nested inside it
//   l5 -> l7   nested, and disjoint from l2 -> l4, so it may reuse that lane
//   l3 -> l6   partially overlaps both of the nested pair
//
// Reaches are 2, 2, 3 and 7, so the two reach-2 routes share a height.

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

// Two routes of equal reach and overlapping span: the second goes to the
// opposite side of the axis at the same height.
#draw-network(range(1, 8).map(layer), connections: (
  connection(from: "l1", to: "l4", type: "skip", pos: auto),
  connection(from: "l3", to: "l6", type: "skip", pos: auto),
))
