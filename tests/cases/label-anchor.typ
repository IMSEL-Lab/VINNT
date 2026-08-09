#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

// label-anchor pins an edge of the text box to the label position; with
// label-dx it fans crowded labels sideways. Both rows have identical geometry.

#let row(a, b, c) = (
  conv(widths: (0.3,), height: 3, depth: 3, label: "convolution", ..a),
  conv(widths: (0.3,), height: 3, depth: 3, label: "downsample", offset: 0.4, ..b),
  conv(widths: (0.3,), height: 3, depth: 3, label: "projection", offset: 0.4, ..c),
)

// Centred on each layer, the default.
#draw-network(row((:), (:), (:)))

#v(6mm)

// Outer labels anchored by their inner edges and pushed outward.
#draw-network(row(
  (label-anchor: "base-east", label-dx: -0.3),
  (:),
  (label-anchor: "base-west", label-dx: 0.3),
))
