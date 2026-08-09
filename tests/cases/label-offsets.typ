#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

// label-dy shifts a single label vertically. Both rows have identical
// geometry; only the middle layer of the second row sets label-dy.

#let row(mid) = (
  conv(widths: (0.3,), height: 3, depth: 3, label: "convolution"),
  conv(widths: (0.3,), height: 3, depth: 3, label: "downsample", offset: 0.58, ..mid),
  conv(widths: (0.3,), height: 3, depth: 3, label: "projection", offset: 0.58),
)

// Collides: three labels compete for the same band of space.
#draw-network(row((:)))

#v(6mm)

// Resolved: only the middle label moves, the layers do not.
#draw-network(row((label-dy: -0.55)))
