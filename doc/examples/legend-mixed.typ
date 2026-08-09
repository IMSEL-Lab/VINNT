#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network(
  (
    conv(name: "a", legend: "convolution"),
    convres(name: "b", legend: "residual conv"),
    conv(name: "c"),
  ),
  connections: (
    connection(from: "a", to: "c", color: rgb("#73000A"), legend: "shortcut"),
    connection(from: "b", to: "c", color: rgb("#466A9F"), dash: "dashed",
     legend: "auxiliary"),
  ),
  show-legend: true,
  main-legend: "forward pass",
)
