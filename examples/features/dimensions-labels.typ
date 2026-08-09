#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

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
