#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#let big = (height: 6, depth: 6, widths: (0.5,))

#draw-network((
  conv(label: "a", ..big),
  conv(label: "b", ..big),
  conv(label: "c", ..big),
))
