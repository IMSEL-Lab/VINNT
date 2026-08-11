// FIGURE 2 — a flat system overview, no isometric anywhere.
//
// TARGET API — the source I wish I could write:
//
//   #draw-network(
//     (
//       source(name: "in",   label: "RGB frame",  sub: "640x640x3"),
//       block(name: "bb",    label: "Backbone",   sub: "CSPDarknet"),
//       block(name: "neck",  label: "Neck",       sub: "PAN-FPN"),
//       block(name: "head",  label: "Head",       sub: "decoupled"),
//       sink(name: "out",    label: "Detections", sub: "N x 6"),
//     ),
//     view: "flat",
//   )
//
// Notes on what this figure argues for.
//   - `view:` selects the renderer. The layer list is unchanged vocabulary —
//     names, labels, connections — so the SAME description could render flat or
//     isometric. That is the whole thesis.
//   - `block()` is a role, not a tensor type. It needs `sub:` for the secondary
//     line, which conv() does not have today.
//   - `source()`/`sink()` may just be `input()`/`output()` reused. Open question.

#import "@preview/cetz:0.5.2": canvas
#import "mock.typ": *

#set page(width: auto, height: auto, margin: 6mm)

#canvas(length: 1cm, {
  let y = 0
  fbox((0, y), "RGB frame", sub: "640x640x3", fill: c-sand, w: 2.0)
  fbox((3.0, y), "Backbone", sub: "CSPDarknet", fill: c-10black)
  fbox((6.0, y), "Neck", sub: "PAN-FPN", fill: c-10black)
  fbox((9.0, y), "Head", sub: "decoupled", fill: c-10black)
  fbox((12.0, y), "Detections", sub: "N x 6", fill: c-atlantic.lighten(70%), w: 2.0)

  farrow((1.0, y), (1.9, y))
  farrow((4.1, y), (4.9, y), label: "P3-P5")
  farrow((7.1, y), (7.9, y))
  farrow((10.1, y), (11.0, y))
})
