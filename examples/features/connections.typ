#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

#draw-network((
  input(label: "A", name: "a", show-connection: true),
  conv(label: "B", name: "b", offset: 2),
  conv(label: "C", name: "c", offset: 2),
  conv(label: "D", name: "d", offset: 2, show-connection: false),
  conv(label: "E", name: "e", offset: 2),
), connections: (
  connection(from: "a", to: "c", type: "skip", mode: "depth", label: "depth mode", pos: 6),
  connection(from: "b", to: "d", type: "skip", mode: "flat", label: "flat mode", pos: 5),
  connection(from: "c", to: "e", type: "skip", mode: "air", label: "air mode (+touch layer instead of arrow)", pos: 5, touch-layer: true),
),
palette: "cold", // There is a "warm" and a "cold" color palette.
show-relu: true // visualize relu using darker color on convolution layers
)