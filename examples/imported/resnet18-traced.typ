#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

#let data = json("resnet18.json")

#let shortcut-color = rgb("#73000A")
#let identity-color = rgb("#466A9F")

#let shortcuts = ("layer2_0_downsample_0", "layer3_0_downsample_0", "layer4_0_downsample_0")

#let residual(from, to, projected) = connection(
  from: from, to: to, type: "skip", mode: "air", pos: auto,
  color: if projected { shortcut-color } else { identity-color },
  legend: if projected { "projected shortcut (1×1)" } else { "identity shortcut" },
)

#draw-network(
  from-shapes(data, label: "leaf", drop: shortcuts),
  groups: groups-from-shapes(data, drop: shortcuts),
  connections: (
    residual("maxpool", "layer1_0_conv2", false),
    residual("layer1_0_conv2", "layer1_1_conv2", false),
    residual("layer1_1_conv2", "layer2_0_conv2", true),
    residual("layer2_0_conv2", "layer2_1_conv2", false),
    residual("layer2_1_conv2", "layer3_0_conv2", true),
    residual("layer3_0_conv2", "layer3_1_conv2", false),
    residual("layer3_1_conv2", "layer4_0_conv2", true),
    residual("layer4_0_conv2", "layer4_1_conv2", false),
  ),
  show-legend: true,
  legend-title: "ResNet-18 (imported)",
  main-legend: "forward pass",
  show-relu: true,
)
