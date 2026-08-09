#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 4mm)

// Sum node overrides -- `fill`, `stroke` and `symbol` are each independently
// settable, so a figure that wants the old filled look can still have it.
//
// Expected, left to right:
//   1. default          white disc, black ring, "+"
//   2. fill only        garnet disc, black ring
//   3. stroke only      white disc, garnet ring and symbol
//   4. symbol override  white disc, black ring, "x"

#draw-network((
  input(label: "input", height: 3, depth: 3, show-connection: true),
  sum(label: "default", offset: 1.2),
  sum(label: "fill", fill: rgb("#73000A"), offset: 1.2),
  sum(label: "stroke", stroke: rgb("#73000A"), offset: 1.2),
  sum(label: "symbol", symbol: "x", offset: 1.2),
  output(label: "output", height: 3, offset: 1.2),
))
