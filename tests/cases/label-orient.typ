#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

// label-orient: the three common orientations, each with its matching anchor
// set automatically. For any other angle use label-angle with your own
// label-anchor; setting both is an error.

#let row(o) = (
  conv(widths: (0.3,), height: 3, depth: 3, label: "convolution", ..o),
  conv(widths: (0.3,), height: 3, depth: 3, label: "downsample", offset: 0.4, ..o),
  conv(widths: (0.3,), height: 3, depth: 3, label: "projection", offset: 0.4, ..o),
  conv(widths: (0.3,), height: 3, depth: 3, label: "bottleneck", offset: 0.4, ..o),
)

// horizontal (the default): unreadable at this spacing, shown for comparison.
#draw-network(row((label-orient: "horizontal")))

#v(8mm)

// diagonal: each label's end points at its own layer.
#draw-network(row((label-orient: "diagonal")))

#v(8mm)

// vertical: each label hangs centred beneath its own layer.
#draw-network(row((label-orient: "vertical")))
