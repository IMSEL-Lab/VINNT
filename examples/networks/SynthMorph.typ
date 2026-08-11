// SynthMorph (Hoffmann et al., IEEE TMI 2021) drawn with VINNT.
#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 12pt)

#let garnet = rgb("#73000A")
#let atlantic = rgb("#466A9F")
#let congaree = rgb("#1F414D")
#let honeycomb = rgb("#A49137")

#draw-network(
  (
    branch(spread: 8, rejoin-lead: 3.5, branches: (
      (input(name: "mov", label: "moving m", shape: (1, 160, 160)),),
      (input(name: "fix", label: "fixed f", shape: (1, 160, 160)),),
    )),
    concat(name: "cat", label: "concat", shape: (2, 160, 160)),

    // Encoder: 3x3x3 conv (64) + LeakyReLU, then max-pool /2, four times.
    conv(name: "e1", shape: (64, 160, 160), channels: (64,)),
    pool(shape: (64, 80, 80)),
    conv(name: "e2", shape: (64, 80, 80), channels: (64,)),
    pool(shape: (64, 40, 40)),
    conv(name: "e3", shape: (64, 40, 40)),
    pool(shape: (64, 20, 20)),
    conv(name: "e4", shape: (64, 20, 20)),
    pool(shape: (64, 10, 10)),
    conv(name: "bott", shape: (64, 10, 10)),

    // Decoder: upsample x2, concat skip, conv 64.
    unpool(shape: (64, 20, 20)),
    conv(name: "d4", shape: (64, 20, 20)),
    unpool(shape: (64, 40, 40)),
    conv(name: "d3", shape: (64, 40, 40)),
    unpool(shape: (64, 80, 80)),
    conv(name: "d2", shape: (64, 80, 80), channels: (64,)),
    unpool(shape: (64, 160, 160)),
    conv(name: "d1", shape: (64, 160, 160), channels: (64, 64)),

    // 1x1x1 conv to a 3-channel stationary velocity field.
    conv(name: "svf", label: "SVF v", shape: (3, 160, 160), channels: (3,),
         fill: atlantic, legend: "velocity field (3 ch)"),

    // Scaling-and-squaring integration, then the spatial transformer.
    custom(name: "int", label: "integrate", width: 0.35, fill: congaree,
           legend: "scaling and squaring"),
    custom(name: "warp", label: "warp", width: 0.35, fill: honeycomb,
           legend: "spatial transformer"),
    output(name: "out", label: "moved m", shape: (1, 160, 160)),
  ),
  connections: (
    connection(from: "e4", to: "d4", touch-layer: true, color: atlantic,
               pos: 1.4, legend: "skip connection"),
    connection(from: "e3", to: "d3", touch-layer: true, color: atlantic, pos: 1.9),
    connection(from: "e2", to: "d2", touch-layer: true, color: atlantic, pos: 2.6),
    connection(from: "e1", to: "d1", touch-layer: true, color: atlantic, pos: 4.2),
    connection(from: "mov", to: "warp", touch-layer: true, color: garnet,
               pos: 4.9, legend: "moving image resampled"),
  ),
  groups: (
    group(from: "e1", to: "bott", label: "encoder"),
    group(from: "d4", to: "d1", label: "decoder"),
    group(from: "svf", to: "warp", label: "diffeomorphic transform"),
  ),
  stroke-thickness: 1.3,
  show-legend: true,
  legend-title: "SynthMorph",
)
