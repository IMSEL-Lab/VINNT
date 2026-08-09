#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

#let row(a, b, c) = (
  conv(widths: (0.3,), height: 3, depth: 3, label: "convolution", ..a),
  conv(widths: (0.3,), height: 3, depth: 3, label: "downsample", offset: 0.4, ..b),
  conv(widths: (0.3,), height: 3, depth: 3, label: "projection", offset: 0.4, ..c),
)

#draw-network(row((:), (:), (:)))

#v(6mm)

#draw-network(row(
  (label-anchor: "base-east", label-dx: -0.3),
  (:),
  (label-anchor: "base-west", label-dx: 0.3),
))
