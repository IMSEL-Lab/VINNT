// FIGURE 3 — flat overview with one box expanded isometrically below it.
//
// This is the figure that justifies the whole package. Nothing else on Universe
// can produce it, because no other tool knows the two views describe the same
// object.
//
// TARGET API, option A — expansion carried inline on the block:
//
//   #draw-network(
//     (
//       source(name: "in", label: "RGB frame"),
//       block(name: "bb", label: "Backbone", detail: (
//         conv(shape: (64, 320, 320), name: "d1"),
//         pool(name: "d2"),
//         conv(shape: (128, 160, 160), name: "d3"),
//         convres(shape: (256, 80, 80), name: "d4"),
//       )),
//       block(name: "neck", label: "Neck"),
//       block(name: "head", label: "Head"),
//     ),
//     view: "flat",
//     detail: "bb",          // which box to expand, and where
//   )
//
// TARGET API, option B — describe the network once, collapse for the overview:
//
//   #let net = (
//     input(name: "in"),
//     conv(shape: (64, 320, 320), name: "d1"),
//     pool(name: "d2"),
//     conv(shape: (128, 160, 160), name: "d3"),
//     convres(shape: (256, 80, 80), name: "d4"),
//     conv(shape: (512, 40, 40), name: "n1"),
//     fc(name: "h1"),
//   )
//   #draw-network(
//     net,
//     view: "flat",
//     collapse: (
//       (from: "d1", to: "d4", label: "Backbone", name: "bb"),
//       (from: "n1", to: "n1", label: "Neck",     name: "neck"),
//       (from: "h1", to: "h1", label: "Head",     name: "head"),
//     ),
//     detail: "bb",
//   )
//
// B has one source of truth and reuses the `groups:` mechanism that already
// exists. A is easier to type for a figure whose overview boxes are not really
// one contiguous run of layers. THIS IS THE DECISION TO MAKE. Look at the
// picture below and decide which source you would rather maintain.

#import "@preview/cetz:0.5.2": canvas
#import "mock.typ": *

#set page(width: auto, height: auto, margin: 6mm)

#canvas(length: 1cm, {
  // ---- overview row ----
  let y = 0
  fbox((0, y), "RGB frame", sub: "640x640x3", fill: c-sand, w: 2.0)
  fbox((3.0, y), "Backbone", sub: "CSPDarknet", fill: c-garnet, text-color: white, stroke-color: c-garnet)
  fbox((6.0, y), "Neck", sub: "PAN-FPN", fill: c-10black)
  fbox((9.0, y), "Head", sub: "decoupled", fill: c-10black)
  fbox((11.9, y), "Detections", sub: "N x 6", fill: c-atlantic.lighten(70%), w: 2.0)

  farrow((1.0, y), (1.9, y))
  farrow((4.1, y), (4.9, y), label: "P3-P5")
  farrow((7.1, y), (7.9, y))
  farrow((10.1, y), (10.9, y))

  // ---- detail panel ----
  let py = -3.6
  let ptl = (1.1, py + 1.5)
  let pbr = (10.9, py - 1.5)
  rect(ptl, pbr, fill: white, stroke: (paint: c-garnet, thickness: 1pt))

  // magnification lines from the highlighted box to the panel corners
  callout((3.0 - 1.1, y - 0.55), (3.0 + 1.1, y - 0.55), ptl, (pbr.at(0), ptl.at(1)))

  prism(1.8, py, w: 0.35, h: 2.2, d: 0.8, fill: rgb("#CDEDFE"), label: "conv", sub: "64")
  prism(3.0, py, w: 0.3, h: 1.8, d: 0.65, fill: rgb("#af78e6"), label: "pool")
  prism(4.2, py, w: 0.5, h: 1.6, d: 0.55, fill: rgb("#CDEDFE"), label: "conv", sub: "128")
  prism(5.6, py, w: 0.3, h: 1.3, d: 0.45, fill: rgb("#af78e6"), label: "pool")
  prism(6.8, py, w: 0.7, h: 1.1, d: 0.38, fill: rgb("#8edbd5"), label: "convres", sub: "256")
  prism(8.6, py, w: 0.9, h: 0.85, d: 0.3, fill: rgb("#8edbd5"), label: "convres", sub: "512")

  for (a, b) in ((2.6, 2.95), (3.75, 4.15), (5.15, 5.55), (6.3, 6.75), (8.0, 8.55)) {
    line((a, py), (b, py), stroke: (paint: black, thickness: 0.8pt), mark: stealth(black))
  }

  content((6.0, py - 2.05), text(size: 7.5pt, fill: c-garnet)[*Backbone*, expanded])
})
