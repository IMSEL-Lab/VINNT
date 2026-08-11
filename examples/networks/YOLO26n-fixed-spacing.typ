#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

#let sppf-color = rgb("#466A9F")
#let lateral-color = rgb("#466A9F")
#let pan-color = rgb("#A49137")
#let head-feed-color = rgb("#1F414D")
#let attn-color = rgb("#65780B")
#let head-color = rgb("#CC2E40")

// Every gap is a fixed fraction of the depth (isometric shear) of the layer
// being left, using the library's own spatial-to-depth curve, so the ratio
// of gap to block size stays constant across the whole diagram instead of
// jumping between hand-picked tiers. k < the library's own depth-multiplier
// (0.3) means consecutive blocks lightly touch rather than clearing with a
// gap; that's intentional here for compactness.
#let k = 0.25
#let from-spatial(v) = calc.max(1.2 * calc.log(calc.max(v, 1), base: 2) - 3.2, 0.4)
#let g(spatial-width) = from-spatial(spatial-width) * k
#let gd(depth) = depth * k
#let input-gap = 1.8

#draw-network((
  input(image: "default", shape: (3, 640, 640), name: "input"),

  conv(shape: (16, 320, 320), name: "p1", offset: input-gap),
  conv(shape: (32, 160, 160), name: "p2", offset: g(320)),
  convres(shape: (64, 160, 160), name: "c2", offset: g(160)),

  conv(shape: (64, 80, 80), name: "p3d", offset: g(160)),
  convres(shape: (128, 80, 80), name: "p3", offset: g(80)),

  conv(shape: (128, 40, 40), name: "p4d", offset: g(80)),
  convres(shape: (256, 40, 40), name: "p4", offset: g(40)),

  conv(shape: (256, 20, 20), name: "p5d", offset: g(40)),
  convres(shape: (256, 20, 20), name: "c5", offset: g(20)),

  custom(shape: (256, 20, 20),
    fill: sppf-color, opacity: 0.9, legend: "SPPF", name: "sppf", offset: g(20)),
  custom(shape: (256, 20, 20),
    fill: attn-color, opacity: 0.9, legend: "C2PSA (attention)", name: "p5", offset: g(20)),

  unpool(shape: (256, 40, 40), name: "u4", offset: g(20)),
  concat(shape: (384, 40, 40), name: "cat4", offset: g(40)),
  convres(shape: (128, 40, 40), name: "n4", offset: g(40)),

  unpool(shape: (128, 80, 80), name: "u3", offset: g(40)),
  concat(shape: (192, 80, 80), name: "cat3", offset: g(80)),
  convres(shape: (64, 80, 80), name: "n3", offset: g(80)),

  conv(shape: (64, 40, 40), name: "d4", offset: g(80)),
  concat(shape: (192, 40, 40), name: "cat4b", offset: g(40)),
  convres(shape: (128, 40, 40), name: "n4b", offset: g(40)),

  conv(shape: (128, 20, 20), name: "d5", offset: g(40)),
  concat(shape: (384, 20, 20), name: "cat5", offset: g(20)),
  convres(shape: (256, 20, 20), name: "n5", offset: g(20)),

  branch(spread: 7, lead: 1.0, rejoin-lead: 4.6, spread-mode: "depth", branches: (
    (custom(width: 0.5, height: 2.6, depth: 1.4,
      fill: head-color, opacity: 0.9, show-relu: false, legend: "Detect (NMS-free)", name: "hp3"),),
    (custom(width: 0.5, height: 2.6, depth: 1.4,
      fill: head-color, opacity: 0.9, show-relu: false, name: "hp4"),),
    (custom(width: 0.5, height: 2.6, depth: 1.4,
      fill: head-color, opacity: 0.9, show-relu: false, name: "hp5"),),
  )),
  output(height: 4, depth: 0.3, name: "out", offset: gd(1.4)),
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
