// FIGURE 6 — the figure this project actually needs: dual-branch RGB/IR fusion,
// shown flat, with the fusion module expanded.
//
// TARGET API:
//
//   #draw-network(
//     (
//       source(name: "rgb", label: "RGB",  lane: 1),
//       source(name: "ir",  label: "IR",   lane: -1),
//       block(name: "bb-rgb", label: "Backbone", lane: 1),
//       block(name: "bb-ir",  label: "Backbone", lane: -1, weights: "shared"),
//       block(name: "fuse",   label: "Gated fusion", detail: (...)),
//       block(name: "head",   label: "Head"),
//       sink(name: "out",     label: "Detections"),
//     ),
//     view: "flat",
//     detail: "fuse",
//   )
//
// What this figure adds that figures 2 and 3 do not.
//   - PARALLEL LANES in the flat view. The isometric renderer already has lane
//     machinery (`lane-unit`, branch()); the flat renderer must reuse it rather
//     than invent its own, or the two views will disagree about geometry.
//   - A block annotated as sharing weights with another block. That is a
//     relationship between two named blocks, which is what `connections:`
//     already expresses — so it should probably be a connection with a style,
//     not a block property.
//   - Merge semantics: two lanes entering one block. The isometric side has
//     concat()/sum() for this. Flat blocks need the same, or the description
//     stops being renderer-independent.

#import "@preview/cetz:0.5.2": canvas
#import "mock.typ": *

#set page(width: auto, height: auto, margin: 6mm)

#canvas(length: 1cm, {
  let up = 1.05
  let dn = -1.05

  fbox((0, up), "RGB", sub: "640x640x3", fill: c-sand, w: 1.7, h: 0.95)
  fbox((0, dn), "IR", sub: "640x640x1", fill: c-sand, w: 1.7, h: 0.95)

  fbox((2.7, up), "Backbone", sub: "CSPDarknet", fill: c-10black, h: 0.95)
  fbox((2.7, dn), "Backbone", sub: "CSPDarknet", fill: c-10black, h: 0.95)

  fbox((5.9, 0), "Gated fusion", fill: c-garnet, text-color: white, stroke-color: c-garnet, w: 2.4, h: 1.2)
  fbox((8.9, 0), "Head", sub: "decoupled", fill: c-10black)
  fbox((11.6, 0), "Detections", fill: c-atlantic.lighten(70%), w: 1.9)

  farrow((0.85, up), (1.6, up))
  farrow((0.85, dn), (1.6, dn))
  farrow((3.8, up), (4.7, 0.28))
  farrow((3.8, dn), (4.7, -0.28))
  farrow((7.1, 0), (7.8, 0))
  farrow((10.0, 0), (10.65, 0))

  // shared-weights relation, drawn as a styled connection between two blocks
  line(
    (2.7, up - 0.48),
    (2.7, dn + 0.48),
    stroke: (paint: c-atlantic, thickness: 0.9pt, dash: (2pt, 2pt)),
    mark: stealth2(c-atlantic),
  )
  content((2.7, 0), box(fill: white, inset: 2pt, text(size: 6pt, fill: c-atlantic)[shared]))

  // ---- detail panel for the fusion module ----
  let py = -3.5
  let ptl = (2.6, py + 1.25)
  let pbr = (9.2, py - 1.25)
  rect(ptl, pbr, fill: white, stroke: (paint: c-garnet, thickness: 1pt))
  callout((5.9 - 1.2, -0.6), (5.9 + 1.2, -0.6), ptl, (pbr.at(0), ptl.at(1)))

  prism(3.2, py + 0.45, w: 0.35, h: 0.85, d: 0.3, fill: rgb("#CDEDFE"), sub: "F_rgb")
  prism(3.2, py - 0.55, w: 0.35, h: 0.85, d: 0.3, fill: rgb("#CDEDFE"), sub: "F_ir")

  fbox((5.0, py), "1x1 conv", w: 1.3, h: 0.65, fill: c-10black)
  fbox((6.6, py), "sigmoid", w: 1.2, h: 0.65, fill: c-10black)

  circle((7.9, py), radius: 0.24, fill: white, stroke: (paint: black, thickness: 0.9pt))
  content((7.9, py), text(size: 8pt)[$times$])

  farrow((3.75, py + 0.45), (4.3, py + 0.12))
  farrow((3.75, py - 0.55), (4.3, py - 0.12))
  farrow((5.7, py), (5.95, py))
  farrow((7.25, py), (7.6, py))
  farrow((8.2, py), (8.8, py))

  content((5.9, py - 1.75), text(size: 7.5pt, fill: c-garnet)[*Gated fusion*, expanded])
})
