#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

#let layers = (
  input(
    name: "I",
    image: image("mnist-img-sample.jpg", scaling: "pixelated"),
    height: 5,
    depth: 5,
    label: "input",
    channels: (1, 32),
    show-connection: true,
  ),
  conv(
    name: "C1",
    widths: (0.5,),
    height: 4.8,
    depth: 4.8,
    label: "f = 5",
    channels: (6, 28),
    offset: 1.9,
    legend: "Convolution+ReLU",
  ),
  pool(
    height: 2.4,
    depth: 2.4,
  ),
  conv(
    widths: (1.2,),
    height: 2,
    depth: 2,
    label: "f = 5",
    channels: (16, 10),
  ),
  pool(
    height: 1,
    depth: 1,
  ),
  fc(
    label: "",
    channels: (120,),
    height: 4,
    depth: 0.3,
    offset: 0.8,
    legend: "Fully Connected+ReLU",
  ),
  fc(
    label: "",
    channels: (84,),
    height: 3,
    depth: 0.3,
    offset: 0.5,
  ),
  fc(
    label: "",
    channels: (10,),
    height: 2,
    depth: 0.3,
    offset: 0.5,
  ),
  softmax(
    label: "softmax",
    height: 2,
    depth: 0.3,
    offset: 0.9,
  ),
)

#draw-network(
  layers,
  show-legend: true,
  show-relu: true,
)
