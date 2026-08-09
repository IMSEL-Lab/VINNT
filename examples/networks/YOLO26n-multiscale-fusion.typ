#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

// YOLO26-n with multi-scale (per-level) RGB-IR fusion. Both modalities keep a
// complete backbone and the streams are concatenated at every pyramid level
// the neck consumes. Atlantic marks the visible laterals, Rose the thermal.

#let fusion-color = rgb("#73000A")
#let sppf-color = rgb("#466A9F")
#let rgb-color = rgb("#466A9F")
#let ir-color = rgb("#CC2E40")
#let pan-color = rgb("#A49137")
#let head-feed-color = rgb("#1F414D")
#let attn-color = rgb("#65780B")
#let head-color = rgb("#CC2E40")

#let lbl = (label-orient: "diagonal")

// Separation between the two backbones, and each one's offset from the trunk.
#let sep = 15
#let dy(top) = if top { sep / 2 } else { -sep / 2 }

// Fusion laterals arrive on the block's own edge, spaced evenly.
#let land = (touch-layer: true, arrive-offset: auto)

// One modality's complete backbone, through the P5 stage. `shift` nudges the
// two stage labels a downward departure riser would otherwise cross.
#let backbone(p, img, label, shift: 0) = (
  input(image: img, shape: (3, 640, 640), label: label, channels: (3, 640), name: p + "in", label-orient: "horizontal"),
  conv(shape: (16, 320, 320), label: "P1/2", channels: (16, 320), name: p + "p1", offset: auto, ..lbl),
  conv(shape: (32, 160, 160), label: "P2/4", channels: (32, 160), name: p + "p2", offset: auto, ..lbl),
  convres(shape: (64, 160, 160), label: "C3k2", channels: (64, 160), name: p + "c2", offset: auto, ..lbl),

  conv(shape: (64, 80, 80), label: "P3/8", channels: (64, 80), name: p + "p3d", offset: auto, ..lbl),
  convres(shape: (128, 80, 80), label: "C3k2", channels: (128, 80), name: p + "p3", offset: auto, ..lbl),

  conv(shape: (128, 40, 40), label: "P4/16", channels: (128, 40), name: p + "p4d", offset: auto, label-dx: shift, ..lbl),
  convres(shape: (256, 40, 40), label: "C3k2", channels: (256, 40), name: p + "p4", offset: auto, ..lbl),

  conv(shape: (256, 20, 20), label: "P5/32", channels: (256, 20), name: p + "p5d", offset: auto, label-dx: shift, ..lbl),
  convres(shape: (256, 20, 20), label: "C3k2", channels: (256, 20), name: p + "p5", offset: auto, ..lbl),
)

#draw-network((
  // ---- Two complete, modality-specific backbones ----
  branch(spread: sep, lead: 2.5, branches: (
    backbone("r-", "default", "RGB"),
    backbone("i-", image("bird-ir.jpg"), "IR ×3", shift: 0.5),
  )),

  // ---- Fusion at P5: the two coarse maps meet where the branches rejoin ----
  concat(shape: (512, 20, 20), name: "f5cat", label: "concat", offset: auto, label-dx: 0.7, ..lbl),
  custom(shape: (256, 20, 20), label: "1×1 fuse P5", channels: (256, 20),
    fill: fusion-color, opacity: 0.9, legend: "Per-level fusion (1×1)", name: "f5", offset: auto, ..lbl),

  custom(shape: (256, 20, 20), label: "SPPF", channels: (256, 20),
    fill: sppf-color, opacity: 0.9, legend: "SPPF", name: "sppf", offset: auto, ..lbl),
  custom(shape: (256, 20, 20), label: "C2PSA", channels: (256, 20),
    fill: attn-color, opacity: 0.9, legend: "C2PSA (attention)", name: "c2psa", offset: auto, ..lbl),

  // ---- Top-down (FPN). Each lateral concat is a fusion point: it takes the
  // upsampled trunk plus both modalities' features at that level. ----
  unpool(shape: (256, 40, 40), label: "upsample", name: "u4", offset: auto, label-orient: "horizontal", label-dx: 0.55),
  concat(shape: (768, 40, 40), name: "cat4", label: "fuse P4", offset: auto, label-dx: -0.45, ..lbl),
  convres(shape: (128, 40, 40), label: "C3k2", channels: (128, 40), name: "n4", offset: auto, ..lbl),

  unpool(shape: (128, 80, 80), label: "upsample", name: "u3", offset: auto, label-orient: "horizontal", label-dx: 0.55),
  concat(shape: (384, 80, 80), name: "cat3", label: "fuse P3", offset: auto, label-dx: -0.45, ..lbl),
  convres(shape: (64, 80, 80), label: "C3k2", channels: (64, 80), name: "n3", offset: auto, ..lbl),

  // ---- Bottom-up (PAN) ----
  conv(shape: (64, 40, 40), label: "down", channels: (64, 40), name: "d4", offset: auto, ..lbl),
  concat(shape: (192, 40, 40), name: "cat4b", label: "concat", offset: auto, label-dx: 0.5, ..lbl),
  convres(shape: (128, 40, 40), label: "C3k2", channels: (128, 40), name: "n4b", offset: auto, ..lbl),

  conv(shape: (128, 20, 20), label: "down", channels: (128, 20), name: "d5", offset: auto, ..lbl),
  concat(shape: (384, 20, 20), name: "cat5", label: "concat", offset: auto, label-dx: 0.45, ..lbl),
  convres(shape: (256, 20, 20), label: "C3k2", channels: (256, 20), name: "n5", offset: auto, ..lbl),

  // ---- Head ----
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
  group(from: "r-in", to: "i-p5", label: "one backbone per modality"),
  group(from: "f5cat", to: "c2psa", label: "P5 fusion + context"),
  group(from: "u4", to: "n3", label: "top-down (fuses P4 and P3)"),
  group(from: "d4", to: "n5", label: "bottom-up"),
  group(from: "hp5", to: "out", label: "detect"),

  group(from: "r-in", to: "i-p5", label: "Backbone ×2", offset: 2.5),
  group(from: "f5cat", to: "n5", label: "Neck (PAN-FPN) — fusion at P5, P4, P3", offset: 2.5),
  group(from: "hp5", to: "out", label: "Head", offset: 2.5),
), connections: (
  // The visible laterals route above and land on the top edge, the thermal
  // ones route below and land on the bottom edge; the trunk arrow keeps the
  // middle. Air lanes are measured from the trunk axis, so the visible
  // backbone's offset is folded into its lane.
  connection(from: "r-p4", to: "cat4", type: "skip", mode: "air", pos: 2.6 + dy(true), color: rgb-color, legend: "RGB lateral", ..land),
  connection(from: "r-p3", to: "cat3", type: "skip", mode: "air", pos: 4.4 + dy(true), color: rgb-color, ..land),
  connection(from: "i-p4", to: "cat4", type: "skip", mode: "flat", pos: 4.6, color: ir-color, legend: "IR lateral", ..land),
  connection(from: "i-p3", to: "cat3", type: "skip", mode: "flat", pos: 6.0, color: ir-color, ..land),

  connection(from: "n4", to: "cat4b", type: "skip", mode: "flat", pos: 4.6, color: pan-color, legend: "bottom-up feed"),
  connection(from: "c2psa", to: "cat5", type: "skip", mode: "flat", pos: 6.2, color: pan-color),
  connection(from: "n3", to: "hp3", type: "skip", mode: "air", pos: 4.2, color: head-feed-color, legend: "head feed"),
  connection(from: "n4b", to: "hp4", type: "skip", mode: "air", pos: 3.0, color: head-feed-color),
),
show-legend: true,
legend-title: "YOLO26-n · multi-scale fusion",
main-legend: "forward pass",
show-relu: true,
)
