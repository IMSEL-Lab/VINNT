// FIGURE 3 — flat overview with one box expanded isometrically below it.
//
// Second draft, with the shape vocabulary from fig2. This is the figure that
// justifies the whole package: nothing else on Universe can produce it, because
// no other tool knows the two views describe the same object.
//
// The shape vocabulary earns its keep here specifically. The overview block is
// a NARROWING TRAPEZOID because it reduces resolution, and the expansion below
// shows exactly how — a descending staircase of prisms. The two views now make
// the same claim at two levels of detail, instead of merely sitting near each
// other. A rectangle in the overview would have thrown that away.
//
// TARGET API, option A — expansion carried inline on the block:
//
//   #draw-network(
//     (
//       source(name: "in", label: "RGB frame"),
//       block(name: "bb", label: "Backbone", role: "downsample", detail: (
//         conv(shape: (64, 320, 320), name: "d1"),
//         pool(shape: (64, 160, 160), name: "d2"),
//         conv(shape: (128, 160, 160), name: "d3"),
//         convres(shape: (256, 80, 80), name: "d4"),
//       )),
//       block(name: "neck", label: "Neck", role: "bottleneck"),
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
//     pool(shape: (64, 160, 160), name: "d2"),
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
// exists — and note that under B the trapezoid could be DERIVED, since the
// library can see that the collapsed run goes 320 -> 80. A is easier to type
// for a figure whose overview boxes are not one contiguous run of layers.
// THIS IS THE DECISION TO MAKE. Look at the picture and decide which source you
// would rather maintain.

#import "@preview/cetz:0.5.2": canvas
#import "mock.typ": *

#set page(width: auto, height: auto, margin: 6mm)

#canvas(length: 1cm, {
  // ---- overview row ----
  let y = 0
  fstack((0, y), "RGB frame", sub: "640x640x3", fill: c-sand)

  ftrap(
    (3.1, y),
    "Backbone",
    sub: "CSPDarknet",
    w: 2.3,
    h: 1.75,
    h-out: 0.95,
    fill: c-garnet,
    stroke-color: c-garnet,
    text-color: white,
  )

  fbar((5.7, y), "Neck", sub: "PAN-FPN", h: 1.0, above: true)
  fbox((8.0, y), "Head", sub: "decoupled", w: 1.9, h: 1.0, fill: c-30black)
  fstack((10.8, y), "Detections", sub: "N x 6", fill: c-congaree-l)

  farrow((0.75, y), (1.85, y))
  farrow((4.35, y), (5.4, y), label: "P3-P5")
  farrow((6.0, y), (6.95, y))
  farrow((9.0, y), (10.15, y))

  // ---- detail panel ----
  let py = -3.9
  let ptl = (1.5, py + 1.55)
  let pbr = (10.4, py - 1.55)
  rect(ptl, pbr, fill: white, stroke: (paint: c-garnet, thickness: 1pt))

  // Magnification lines run from the trapezoid's lower corners to the panel's
  // upper corners. Hand-placed here; see FINDINGS item 9.
  callout((3.1 - 1.15, y - 0.875), (3.1 + 1.15, y - 0.475), ptl, (pbr.at(0), ptl.at(1)))

  // A descending staircase: the same claim the trapezoid makes, in detail.
  prism(2.1, py, w: 0.35, h: 2.3, d: 0.85, fill: rgb("#CDEDFE"), label: "conv", sub: "64")
  prism(3.3, py, w: 0.28, h: 1.9, d: 0.7, fill: rgb("#af78e6"), label: "pool")
  prism(4.5, py, w: 0.5, h: 1.7, d: 0.6, fill: rgb("#CDEDFE"), label: "conv", sub: "128")
  prism(5.9, py, w: 0.28, h: 1.35, d: 0.48, fill: rgb("#af78e6"), label: "pool")
  prism(7.1, py, w: 0.7, h: 1.15, d: 0.4, fill: rgb("#8edbd5"), label: "convres", sub: "256")
  prism(8.9, py, w: 0.9, h: 0.85, d: 0.3, fill: rgb("#8edbd5"), label: "convres", sub: "512")

  for (a, b) in ((2.85, 3.25), (4.05, 4.45), (5.45, 5.85), (6.6, 7.05), (8.3, 8.85)) {
    line((a, py), (b, py), stroke: (paint: black, thickness: 0.8pt), mark: stealth(black))
  }

  content((5.95, py - 2.1), text(size: 7.5pt, fill: c-garnet)[*Backbone*, expanded])
})
