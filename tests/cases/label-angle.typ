#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

// label-angle rotates a label. All three rows have identical geometry and
// labels; only the angle differs.

#let row(a) = (
  conv(widths: (0.3,), height: 3, depth: 3, label: "convolution", ..a),
  conv(widths: (0.3,), height: 3, depth: 3, label: "downsample", offset: 0.4, ..a),
  conv(widths: (0.3,), height: 3, depth: 3, label: "projection", offset: 0.4, ..a),
  conv(widths: (0.3,), height: 3, depth: 3, label: "bottleneck", offset: 0.4, ..a),
)

// Horizontal: unreadable at this spacing.
#draw-network(row((:)))

#v(8mm)

// 45 degrees, anchored east so the labels hang back from their layers.
#draw-network(row((label-angle: 45deg, label-anchor: "base-east")))

#v(8mm)

// 90 degrees, fully vertical.
#draw-network(row((label-angle: 90deg, label-anchor: "base-east")))
