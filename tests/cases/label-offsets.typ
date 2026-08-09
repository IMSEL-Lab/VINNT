#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

#let row(mid) = (
  conv(widths: (0.3,), height: 3, depth: 3, label: "convolution"),
  conv(widths: (0.3,), height: 3, depth: 3, label: "downsample", offset: 0.58, ..mid),
  conv(widths: (0.3,), height: 3, depth: 3, label: "projection", offset: 0.58),
)

#draw-network(row((:)))

#v(6mm)

#draw-network(row((label-dy: -0.55)))
