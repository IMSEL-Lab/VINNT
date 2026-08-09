#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

#let sppf-color = rgb("#466A9F")
#let lateral-color = rgb("#466A9F")
#let pan-color = rgb("#A49137")
#let head-feed-color = rgb("#1F414D")
#let attn-color = rgb("#65780B")
#let head-color = rgb("#CC2E40")
#let gate-color = rgb("#65780B")
#let fusion-color = rgb("#73000A")

#let lbl = (label-orient: "diagonal")

#let stream(p, img, label) = (
  input(image: img, shape: (3, 640, 640), label: label, channels: (3, 640), name: p + "in", label-orient: "horizontal"),
  conv(shape: (16, 320, 320), label: "P1/2", channels: (16, 320), name: p + "p1", offset: auto, ..lbl),
  conv(shape: (32, 160, 160), label: "P2/4", channels: (32, 160), name: p + "p2", offset: auto, ..lbl),
  convres(shape: (64, 160, 160), label: "C3k2", channels: (64, 160), name: p + "c2", offset: auto, ..lbl),
  conv(shape: (64, 80, 80), label: "P3/8", channels: (64, 80), name: p + "p3d", offset: auto, ..lbl),
  convres(shape: (128, 80, 80), label: "C3k2", channels: (128, 80), name: p + "p3", offset: auto, ..lbl),
)

#let gate = (
  input(image: "default", shape: (3, 56, 56), label: "RGB ↓56", channels: (3, 56), name: "g-in", label-orient: "horizontal"),
  conv(shape: (16, 28, 28), label: "conv", channels: (16, 28), name: "g-c1", offset: 2.2, label-orient: "horizontal", label-dy: -0.3),
  conv(shape: (32, 14, 14), label: "conv", channels: (32, 14), name: "g-c2", offset: 2.6, label-orient: "horizontal", label-dy: -0.3),
  custom(width: 0.4, height: 1.2, depth: 1.0, label: "GAP + FC", channels: (128,),
    fill: gate-color, opacity: 0.9, legend: "Illumination subnet", name: "g-fc", offset: 3.0, label-orient: "horizontal", label-dy: -0.3),
  custom(width: 0.3, height: 0.8, depth: 0.7, label: "softmax", channels: (2,),
    fill: gate-color, opacity: 0.9, show-relu: false, name: "g-w", offset: 3.4, label-orient: "horizontal", label-dy: -0.3),
)

#draw-network((
  branch(spread: 18, lead: 2.5, rejoin-lead: 3.4, branches: (
    stream("r-", "default", "RGB"),
    gate,
    stream("i-", image("bird-ir.jpg"), "IR ×3"),
  )),

  sum(label: "weighted sum", radius: 0.42, stroke: fusion-color,
    legend: "Illumination-gated sum", name: "fuse", offset: 1.6, label-orient: "horizontal"),

  conv(shape: (128, 40, 40), label: "P4/16", channels: (128, 40), name: "p4d", offset: 1.8, ..lbl),
  convres(shape: (256, 40, 40), label: "C3k2", channels: (256, 40), name: "p4", offset: auto, ..lbl),

  conv(shape: (256, 20, 20), label: "P5/32", channels: (256, 20), name: "p5d", offset: auto, ..lbl),
  convres(shape: (256, 20, 20), label: "C3k2", channels: (256, 20), name: "c5", offset: auto, ..lbl),

  custom(shape: (256, 20, 20), label: "SPPF", channels: (256, 20),
    fill: sppf-color, opacity: 0.9, legend: "SPPF", name: "sppf", offset: auto, ..lbl),
  custom(shape: (256, 20, 20), label: "C2PSA", channels: (256, 20),
    fill: attn-color, opacity: 0.9, legend: "C2PSA (attention)", name: "p5", offset: auto, ..lbl),

  unpool(shape: (256, 40, 40), label: "upsample", name: "u4", offset: auto, label-orient: "horizontal", label-dx: 0.55),
  concat(shape: (384, 40, 40), name: "cat4", label: "concat", offset: auto, ..lbl),
  convres(shape: (128, 40, 40), label: "C3k2", channels: (128, 40), name: "n4", offset: auto, ..lbl),

  unpool(shape: (128, 80, 80), label: "upsample", name: "u3", offset: auto, label-orient: "horizontal", label-dx: 0.55),
  concat(shape: (192, 80, 80), name: "cat3", label: "concat", offset: auto, label-dx: 0.75, ..lbl),
  convres(shape: (64, 80, 80), label: "C3k2", channels: (64, 80), name: "n3", offset: auto, ..lbl),

  conv(shape: (64, 40, 40), label: "down", channels: (64, 40), name: "d4", offset: auto, ..lbl),
  concat(shape: (192, 40, 40), name: "cat4b", label: "concat", offset: auto, label-dx: 0.5, ..lbl),
  convres(shape: (128, 40, 40), label: "C3k2", channels: (128, 40), name: "n4b", offset: auto, ..lbl),

  conv(shape: (128, 20, 20), label: "down", channels: (128, 20), name: "d5", offset: auto, ..lbl),
  concat(shape: (384, 20, 20), name: "cat5", label: "concat", offset: auto, label-dx: 0.45, ..lbl),
  convres(shape: (256, 20, 20), label: "C3k2", channels: (256, 20), name: "n5", offset: auto, ..lbl),

  branch(spread: 7, lead: 3.0, rejoin-lead: 4.6, spread-mode: "depth", branches: (
    (custom(width: 0.5, height: 2.6, depth: 1.4, label: "Detect P3", channels: (256, 80),
      fill: head-color, opacity: 0.9, show-relu: false, legend: "Detect (NMS-free)", name: "hp3", label-orient: "horizontal"),),
    (custom(width: 0.5, height: 2.6, depth: 1.4, label: "Detect P4", channels: (256, 40),
      fill: head-color, opacity: 0.9, show-relu: false, name: "hp4", label-orient: "horizontal"),),
    (custom(width: 0.5, height: 2.6, depth: 1.4, label: "Detect P5", channels: (256, 20),
      fill: head-color, opacity: 0.9, show-relu: false, name: "hp5", label-orient: "horizontal"),),
  )),
  output(label: "boxes + cls", height: 4, depth: 0.3, name: "out", offset: auto, ..lbl),
), groups: (
  group(from: "r-in", to: "i-p3", label: "modal stems + gate"),
  group(from: "p4d", to: "p4", label: "P4 stage"),
  group(from: "p5d", to: "c5", label: "P5 stage"),
  group(from: "sppf", to: "p5", label: "context"),
  group(from: "u4", to: "n3", label: "top-down"),
  group(from: "d4", to: "n5", label: "bottom-up"),
  group(from: "hp5", to: "out", label: "detect"),

  group(from: "r-in", to: "i-p3", label: "Backbone ×2 + illumination gate", offset: 2.5),
  group(from: "p4d", to: "p5", label: "Shared backbone", offset: 2.5),
  group(from: "u4", to: "n5", label: "Neck (PAN-FPN)", offset: 2.5),
  group(from: "hp5", to: "out", label: "Head", offset: 2.5),
), connections: (
  connection(from: "p4", to: "cat4", type: "skip", mode: "air", pos: 2.6, color: lateral-color, legend: "backbone feed"),
  connection(from: "fuse", to: "cat3", type: "skip", mode: "air", pos: 4.0, color: lateral-color),
  connection(from: "n4", to: "cat4b", type: "skip", mode: "flat", pos: 4.6, color: pan-color, legend: "bottom-up feed"),
  connection(from: "p5", to: "cat5", type: "skip", mode: "flat", pos: 6.2, color: pan-color),
  connection(from: "n3", to: "hp3", type: "skip", mode: "air", pos: 4.2, color: head-feed-color, legend: "head feed"),
  connection(from: "n4b", to: "hp4", type: "skip", mode: "air", pos: 3.0, color: head-feed-color),
),
show-legend: true,
legend-title: "YOLO26-n · illumination-gated fusion",
main-legend: "forward pass",
show-relu: true,
)
