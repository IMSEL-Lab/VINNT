#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

#draw-network((
    input(image: "default"),
    conv(offset: 2),
    conv(offset: 2),
    pool(),
    conv(widths: (1, 1), offset: 3)
))

#draw-network((
    convres(
      widths: (1, 2),
      channels: (32, 64, 128),
      height: 6,
      depth: 8,
      label: "residual convolution",
    ),pool(
      channels: ("", "text also works"),
      height: 4,
      depth: 6,
      connection-label: "connection label",
    ),conv(
      widths: (1.5, 1.5),
      height: 2,
      depth: 3,
      label: "whole block label",
      legend: "CUSTOM NAME",
      offset: 4,
    ),fc(
      channels: (10,),
      height: 5,
      depth: 0,
      label: "2D layer",
      offset: 2,
    ),
),
show-legend: true,
)

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
palette: "cold",
show-relu: true
)

#draw-network((
  custom(
    width: 0.3, height: 5, depth: 5,
    label: "custom..",
    fill: rgb("#FF6B6B"),
    opacity: 0.9,
    legend: "Custom Color",
  ),custom(
    width: 0.3, height: 5, depth: 5,
    label: "..colors !",
    fill: rgb("#FF6B6B"),
    opacity: 0.9,
    offset: 1.7,
    image: [hi]
  ),custom(
    widths: (0.3, 0.4, 0.3), height: 5, depth: 5,
    label: "custom color+bandfill", 
    fill: rgb("#4ECDC4"),
    bandfill: rgb("#FFE66D"),
    show-relu: true,
    offset: 2,
    legend: "Custom Color+Bandfill",
  ),
),
show-legend: true,
legend-title: "My new layers"
)
