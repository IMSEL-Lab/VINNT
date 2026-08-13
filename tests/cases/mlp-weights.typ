#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

// target-major matrices: matrix l is counts[l+1] rows x counts[l] columns
#let w = (
  ((0.8, -0.3), (-1.0, 0.5), (0.2, 0.9)),
  ((0.6, -0.7, 0.1), (-0.4, 1.0, -0.9)),
)

// default encoding: color + thickness
#draw-mlp((2, 3, 2), weights: w)

#v(8mm)

// thickness only, against a fixed saturation range
#draw-mlp((2, 3, 2), weights: w, weight-encode: ("thickness",), weight-range: 2.0)

#v(8mm)

// color + opacity, custom sign colors
#draw-mlp((2, 3, 2), weights: w, weight-encode: ("color", "opacity"),
  weight-colors: (positive: rgb("#65780B"), negative: rgb("#73000A")))
