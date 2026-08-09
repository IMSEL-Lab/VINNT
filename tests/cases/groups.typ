#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

#let layer(n, h) = conv(widths: (0.4,), height: h, depth: h,
  name: "l" + str(n), label: "l" + str(n), offset: 1.2,
)

#draw-network(
  (layer(1, 3), layer(2, 3), layer(3, 2), layer(4, 2)),
  groups: (
    group(from: "l1", to: "l2", label: "encoder"),
    group(from: "l3", to: "l4", label: "decoder"),
  ),
)

#v(9mm)

#draw-network(
  (layer(1, 3), layer(2, 3), layer(3, 3), layer(4, 2), layer(5, 2)),
  groups: (
    group(from: "l1", to: "l1", label: "stem"),
    group(from: "l2", to: "l3", label: "middle"),
    group(from: "l4", to: "l5", label: "head"),
    group(from: "l1", to: "l5", label: "whole network", offset: 2.3),
  ),
)
