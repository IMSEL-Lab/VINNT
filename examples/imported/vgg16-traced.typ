#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

#let data = json("vgg16.json")

#draw-network(
  from-shapes(data, label: "leaf", defaults: (label-orient: "diagonal")),
  groups: groups-from-shapes(data),
  show-legend: true,
  legend-title: "VGG-16 (imported)",
  main-legend: "forward pass",
  show-relu: true,
)
