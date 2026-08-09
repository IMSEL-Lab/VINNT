#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

#let approx(a, b) = calc.abs(a - b) < 1e-9

#assert(approx(depth-shear(4.5), 1.35), message: "depth-shear(4.5) should be 1.35")
#assert(approx(depth-shear(6), 1.8), message: "depth-shear(6) should be 1.8")
#assert(approx(depth-shear(6, depth-multiplier: 0.5), 3.0), message: "multiplier must be honoured")
#assert(approx(min-clear-offset(6), 3.6), message: "min-clear-offset is twice the shear")

#let fig(off) = draw-network((
  conv(widths: (0.3,), height: 4, depth: 6, label: "source", name: "src"),
  conv(widths: (0.3,), height: 4, depth: 6, label: "a", offset: 3, name: "a"),
  conv(widths: (0.3,), height: 4, depth: 6, label: "b", offset: off, name: "b"),
), connections: (
  connection(from: "src", to: "b", type: "skip", mode: "air", pos: 2),
))

#fig(depth-shear(6))

#v(8mm)

#fig(min-clear-offset(6))
