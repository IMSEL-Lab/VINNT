#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

#let row(a) = (
  conv(widths: (0.3,), height: 3, depth: 3, label: "convolution", ..a),
  conv(widths: (0.3,), height: 3, depth: 3, label: "downsample", offset: 0.4, ..a),
  conv(widths: (0.3,), height: 3, depth: 3, label: "projection", offset: 0.4, ..a),
  conv(widths: (0.3,), height: 3, depth: 3, label: "bottleneck", offset: 0.4, ..a),
)

#draw-network(row((:)))

#v(8mm)

#draw-network(row((label-angle: 45deg, label-anchor: "base-east")))

#v(8mm)

#draw-network(row((label-angle: 90deg, label-anchor: "base-east")))
