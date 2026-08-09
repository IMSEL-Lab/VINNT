#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

#let row(o) = (
  conv(widths: (0.3,), height: 3, depth: 3, label: "convolution", ..o),
  conv(widths: (0.3,), height: 3, depth: 3, label: "downsample", offset: 0.4, ..o),
  conv(widths: (0.3,), height: 3, depth: 3, label: "projection", offset: 0.4, ..o),
  conv(widths: (0.3,), height: 3, depth: 3, label: "bottleneck", offset: 0.4, ..o),
)

#draw-network(row((label-orient: "horizontal")))

#v(8mm)

#draw-network(row((label-orient: "diagonal")))

#v(8mm)

#draw-network(row((label-orient: "vertical")))
