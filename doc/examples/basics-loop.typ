#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#let stage(n) = conv(
  label: "stage " + str(n),
  shape: (32 * n, 128 / n, 128 / n),
)

#draw-network(range(1, 5).map(stage))
