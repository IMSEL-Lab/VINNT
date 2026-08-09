#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

#let layers = (
  input(
    image: "default",
    height: 8,
    depth: 8,
    label: "input",
    channels: (3, 224),
  ),
  conv(
    widths: (0.3, 0.3),
    height: 8,
    depth: 8,
    label: "conv1",
    channels: (64, 64, 224),
    offset: 1.9,
  ),
  pool(
    height: 6,
    depth: 6,
  ),
  conv(
    widths: (0.4,0.4,),
    height: 6,
    depth: 6,
    label: "conv2",
    channels: (128, 128, 112),
  ),
  pool(
    height: 4,
    depth: 4,
  ),
  conv(
    widths: (0.5, 0.5),
    height: 4,
    depth: 4,
    label: "conv3",
    channels: (256, 256, 56),
  ),
  pool(
    height: 2,
    depth: 2,
  ),
  conv(
    widths: (0.6, 0.6, 0.6, 0.6),
    height: 2,
    depth: 2,
    label: "conv4",
    channels: (512, 512, 512, 512, 28),
    offset: 1,
  ),
  pool(
    height: 1,
    depth: 1,
  ),
  conv(
    widths: (0.6, 0.8, 0.8, 0.8),
    height: 1,
    depth: 1,
    label: "conv5",
    channels: (512, 512, 512, 512, 14),
    offset: 0.8,
  ),
  pool(
    height: 0.5,
    depth: 0.5,
  ),
  fc(
    label: "fc",
    channels: (4096,),
    height: 5,
    depth: 0.3,
    offset: 0.8,
  ),
  fc(
    label: "fc",
    channels: (4096,),
    height: 5,
    depth: 0.3,
    offset: 0.5,
  ),
  fc(
    label: "fc",
    channels: (1000,),
    height: 4,
    depth: 0.3,
    offset: 0.5,
  ),
  softmax(
    label: "softmax",
    height: 4,
    depth: 0.3,
    offset: 0.9,
  ),
)

#draw-network(
  layers,
  show-relu: true,
)
