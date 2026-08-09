#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

// Per-connection stroke styling: color, dash, thickness (multiplies the
// palette width) and legend (drawn as a line sample). All four skips have
// identical geometry, so any difference is the style. Arrowheads take the
// line colour.

#let garnet = rgb("#73000A")
#let atlantic = rgb("#466A9F")

#let layer(n) = conv(widths: (0.3,), height: 2.5, depth: 2.5, name: "l" + str(n), offset: 1.0)

#draw-network(
  range(1, 10).map(layer),
  connections: (
    connection(from: "l1", to: "l3", type: "skip", pos: 2.2, label: "default", legend: "plain skip"),
    connection(from: "l3", to: "l5", type: "skip", pos: 2.2, label: "dashed", dash: "dashed", legend: "auxiliary"),
    connection(from: "l5", to: "l7", type: "skip", pos: 2.2, label: "colour", color: garnet, legend: "residual add"),
    connection(from: "l7", to: "l9", type: "skip", pos: 2.2, label: "thick + dotted",
      color: atlantic, dash: "dotted", thickness: 2, legend: "attention route"),
  ),
  show-legend: true,
  legend-title: "Connections",
  main-legend: "forward pass",
)
