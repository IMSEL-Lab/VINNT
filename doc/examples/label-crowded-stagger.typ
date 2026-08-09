#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#let b = (height: 3, depth: 3, widths: (0.3,), offset: 0.6)
#draw-network((
  conv(label: "convolution", ..b),
  conv(label: "downsample", label-dy: -0.55, ..b),
  conv(label: "projection", ..b),
))
