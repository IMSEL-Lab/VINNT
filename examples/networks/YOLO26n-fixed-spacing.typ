#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

#let sppf-color = rgb("#466A9F")
#let lateral-color = rgb("#466A9F")
#let pan-color = rgb("#A49137")
#let head-feed-color = rgb("#1F414D")
#let attn-color = rgb("#65780B")
#let head-color = rgb("#CC2E40")

// Gaps are sized to the depth of the layer being left: layers with more
// isometric shear (depth 5 convs) need more clearance than shallow ones
// (depth 3 concats, depth ~1.4 detect heads), so shrinking every gap to one
// constant either overlaps the deep layers or leaves the shallow ones too
// loose. Each gap below is named for the layer type it follows.
#let gap-conv = 1.3    // after a depth-5 conv/convres/custom block
#let gap-unpool = 0.75 // after a depth-4 unpool block
#let gap-concat = 0.5  // after a depth-3 concat block
#let gap-detect = 0.3  // after a depth-1.4 detect block
#let input-gap = 1.8

#draw-network((
  input(image: "default", shape: (3, 640, 640), name: "input"),

  conv(shape: (16, 320, 320), name: "p1", offset: input-gap),
  conv(shape: (32, 160, 160), name: "p2", offset: gap-conv),
  convres(shape: (64, 160, 160), name: "c2", offset: gap-conv),

  conv(shape: (64, 80, 80), name: "p3d", offset: gap-conv),
  convres(shape: (128, 80, 80), name: "p3", offset: gap-conv),

  conv(shape: (128, 40, 40), name: "p4d", offset: gap-conv),
  convres(shape: (256, 40, 40), name: "p4", offset: gap-conv),

  conv(shape: (256, 20, 20), name: "p5d", offset: gap-conv),
  convres(shape: (256, 20, 20), name: "c5", offset: gap-conv),

  custom(shape: (256, 20, 20),
    fill: sppf-color, opacity: 0.9, legend: "SPPF", name: "sppf", offset: gap-conv),
  custom(shape: (256, 20, 20),
    fill: attn-color, opacity: 0.9, legend: "C2PSA (attention)", name: "p5", offset: gap-conv),

  unpool(shape: (256, 40, 40), name: "u4", offset: gap-conv),
  concat(shape: (384, 40, 40), name: "cat4", offset: gap-unpool),
  convres(shape: (128, 40, 40), name: "n4", offset: gap-concat),

  unpool(shape: (128, 80, 80), name: "u3", offset: gap-conv),
  concat(shape: (192, 80, 80), name: "cat3", offset: gap-unpool),
  convres(shape: (64, 80, 80), name: "n3", offset: gap-concat),

  conv(shape: (64, 40, 40), name: "d4", offset: gap-conv),
  concat(shape: (192, 40, 40), name: "cat4b", offset: gap-conv),
  convres(shape: (128, 40, 40), name: "n4b", offset: gap-concat),

  conv(shape: (128, 20, 20), name: "d5", offset: gap-conv),
  concat(shape: (384, 20, 20), name: "cat5", offset: gap-conv),
  convres(shape: (256, 20, 20), name: "n5", offset: gap-concat),

  branch(spread: 7, lead: 3.0, rejoin-lead: 4.6, spread-mode: "depth", branches: (
    (custom(width: 0.5, height: 2.6, depth: 1.4,
      fill: head-color, opacity: 0.9, show-relu: false, legend: "Detect (NMS-free)", name: "hp3"),),
    (custom(width: 0.5, height: 2.6, depth: 1.4,
      fill: head-color, opacity: 0.9, show-relu: false, name: "hp4"),),
    (custom(width: 0.5, height: 2.6, depth: 1.4,
      fill: head-color, opacity: 0.9, show-relu: false, name: "hp5"),),
  )),
  output(height: 4, depth: 0.3, name: "out", offset: gap-detect),
), groups: (
  group(from: "p1", to: "c2", label: "stem"),
  group(from: "p3d", to: "p3", label: "P3 stage"),
  group(from: "p4d", to: "p4", label: "P4 stage"),
  group(from: "p5d", to: "c5", label: "P5 stage"),
  group(from: "sppf", to: "p5", label: "context"),
  group(from: "u4", to: "n3", label: "top-down"),
  group(from: "d4", to: "n5", label: "bottom-up"),
  group(from: "hp5", to: "out", label: "detect"),

  group(from: "p1", to: "p5", label: "Backbone", offset: 2.5),
  group(from: "u4", to: "n5", label: "Neck (PAN-FPN)", offset: 2.5),
  group(from: "hp5", to: "out", label: "Head", offset: 2.5),
), connections: (
  connection(from: "p4", to: "cat4", type: "skip", mode: "air", pos: 2.6, color: lateral-color, legend: "backbone feed"),
  connection(from: "p3", to: "cat3", type: "skip", mode: "air", pos: 4.0, color: lateral-color),
  connection(from: "n4", to: "cat4b", type: "skip", mode: "flat", pos: 4.6, color: pan-color, legend: "bottom-up feed"),
  connection(from: "p5", to: "cat5", type: "skip", mode: "flat", pos: 6.2, color: pan-color),
  connection(from: "n3", to: "hp3", type: "skip", mode: "air", pos: 4.2, color: head-feed-color, legend: "head feed"),
  connection(from: "n4b", to: "hp4", type: "skip", mode: "air", pos: 3.0, color: head-feed-color),
),
show-legend: true,
legend-title: "YOLO26-n",
main-legend: "forward pass",
show-relu: true,
)
