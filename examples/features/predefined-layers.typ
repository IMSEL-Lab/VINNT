#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

#let layers = (
  input(
    label: "input"
  ),conv(
    widths: (0.3, 0.3),
    label: "conv"
  ),pool(
    label: "pool",
    offset: 1
  ),convres(
    widths: (0.3, 0.3),
    label: "convres",
    offset: 1
  ),unpool(
    label: "unpool",
    offset: 1
  ),deconv(
    label: "deconv",
    offset: 1
  ),concat(
    label: "concat",
    offset: 1.4
  ),gap(
    label: "gap"
  ),fc(
    label: "fc",
    offset: 0.7
  ),convsoftmax(
    label: "convsoftmax",
    offset: 0.6
  ),sum(
    symbol: "+",
    channels: (""),
    offset: 0.7
  ),softmax(
    label: "softmax",
    offset: 0.6
  ),output(
    label: "output",
    offset: 1
  ),custom(
    widths: (0.3, 0.3),
    height: 3,
    depth: 3,
    label: "custom",
    legend: "Custom Layer",
    offset: 0.6
  ),custom(
    // A custom layer shows an activation band only when it asks for one, either
    // by declaring a bandfill or by opting in with show-relu. Without that it
    // stays flat, even when the network sets show-relu globally.
    widths: (0.3, 0.3),
    height: 3,
    depth: 3,
    label: "custom+relu",
    legend: "Custom Layer + activation",
    show-relu: true,
    offset: 1.8
  ),
)

#draw-network(layers,
show-relu: true,
show-legend: true,
palette: "warm"
)

#draw-network(layers,
show-relu: true,
show-legend: true,
palette: "cold"
)