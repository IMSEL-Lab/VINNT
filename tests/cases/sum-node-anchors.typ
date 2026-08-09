#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 4mm)

// A sum node as a connection endpoint: its anchors sit on the flat circle,
// with no depth-lean.
//
// Expected in both rows: one arrowhead per gap, the coloured route leaving from
// the trunk line just behind the head, and the bracket ending at the circle.

#let blk(n, l) = conv(widths: (0.4,), height: 3, depth: 2, label: l, offset: 1.8, name: n)

// Departing the sum, and arriving at it.
#draw-network((
  input(height: 3, depth: 2, label: "in", show-connection: true, name: "i"),
  sum(label: "sum", radius: 0.42, name: "s", offset: 1.6),
  blk("b1", "b1"), blk("b2", "b2"), blk("b3", "b3"),
), groups: (
  group(from: "i", to: "s", label: "through the sum"),
), connections: (
  connection(from: "s", to: "b3", type: "skip", mode: "air", pos: 2.5, color: rgb("#466A9F")),
  connection(from: "i", to: "s", type: "skip", mode: "flat", pos: 2.5, color: rgb("#CC2E40")),
))

#v(8mm)

// The same, with the sum immediately after a branch rejoin.
#draw-network((
  branch(spread: 6, branches: (
    (input(height: 3, depth: 2, label: "a", show-connection: true),),
    (input(height: 3, depth: 2, label: "b", show-connection: true),),
  )),
  sum(label: "sum", radius: 0.42, name: "s", offset: 1.6),
  blk("b1", "b1"), blk("b2", "b2"), blk("b3", "b3"),
), connections: (
  connection(from: "s", to: "b3", type: "skip", mode: "air", pos: 2.5, color: rgb("#466A9F")),
))
