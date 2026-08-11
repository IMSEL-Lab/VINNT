// FIGURE 6 — the figure this project actually needs: dual-branch RGB/IR fusion,
// shown flat, with the fusion module expanded.
//
// Second draft, with the shape vocabulary from fig2 and fig3. The two backbones
// are narrowing trapezoids because they reduce resolution, the inputs and
// outputs are stacked planes, and the gate is an elementwise circle rather than
// a labelled box. Only the head stays a rectangle, because it preserves
// structure.
//
// TARGET API:
//
//   #draw-network(
//     (
//       source(name: "rgb", label: "RGB", sub: "640x640x3", lane: 1),
//       source(name: "ir",  label: "IR",  sub: "640x640x1", lane: -1),
//       block(name: "bb-rgb", label: "Backbone", role: "downsample", lane: 1),
//       block(name: "bb-ir",  label: "Backbone", role: "downsample", lane: -1),
//       block(name: "fuse",   label: "Gated fusion", detail: (...)),
//       block(name: "head",   label: "Head"),
//       sink(name: "out",     label: "Detections", sub: "N x 6"),
//     ),
//     connections: (
//       connection(from: "bb-rgb", to: "bb-ir", type: "tied", label: "shared"),
//     ),
//     view: "flat",
//     detail: "fuse",
//   )
//
// What this figure adds that figures 2 and 3 do not.
//   - PARALLEL LANES in the flat view. The isometric renderer already has lane
//     machinery (`lane-unit`, branch()); the flat renderer must reuse it rather
//     than invent its own, or the two views will disagree about geometry.
//   - Weight sharing expressed as a CONNECTION between two named blocks, not as
//     a property on one of them. Same mechanism will carry weight tying, EMA
//     teachers and stop-gradient annotations.
//   - MERGE SEMANTICS: two lanes entering one block. The isometric side has
//     concat()/sum() for this. The flat renderer needs the same or the
//     description stops being renderer-independent.
//   - A detail panel whose contents are NOT a slice of a linear trunk. This is
//     the case that argues against a pure `collapse:` design — see FINDINGS.

#import "@preview/cetz:0.5.2": canvas
#import "mock.typ": *

#set page(width: auto, height: auto, margin: 6mm)

#canvas(length: 1cm, {
  let up = 1.35
  let dn = -1.35

  fstack((0, up), "RGB", sub: "640x640x3", w: 1.0, h: 1.1, fill: c-sand)
  fstack((0, dn), "IR", sub: "640x640x1", w: 1.0, h: 1.1, fill: c-sand)

  ftrap((2.9, up), "Backbone", sub: "CSPDarknet", w: 2.1, h: 1.5, h-out: 0.85, fill: c-10black)
  ftrap((2.9, dn), "Backbone", sub: "CSPDarknet", w: 2.1, h: 1.5, h-out: 0.85, fill: c-10black)

  fbox(
    (6.2, 0),
    "Gated fusion",
    w: 2.2,
    h: 1.3,
    fill: c-garnet,
    stroke-color: c-garnet,
    text-color: white,
  )

  fbox((9.1, 0), "Head", sub: "decoupled", w: 1.8, h: 1.0, fill: c-30black)
  fstack((11.7, 0), "Detections", sub: "N x 6", w: 1.0, h: 1.1, fill: c-congaree-l)

  farrow((0.75, up), (1.75, up))
  farrow((0.75, dn), (1.75, dn))
  farrow((4.0, up - 0.02), (5.05, 0.42))
  farrow((4.0, dn + 0.02), (5.05, -0.42))
  farrow((7.35, 0), (8.15, 0))
  farrow((10.05, 0), (11.1, 0))

  // Weight sharing, drawn as a styled connection between two named blocks.
  line(
    (2.9, up - 0.78),
    (2.9, dn + 0.78),
    stroke: (paint: c-atlantic, thickness: 0.9pt, dash: (2pt, 2pt)),
    mark: stealth2(c-atlantic),
  )
  content((2.9, 0), box(fill: white, inset: 2.5pt, text(size: 6.5pt, fill: c-atlantic)[shared]))

  // ---- detail panel for the fusion module ----
  let py = -4.3
  let ptl = (2.4, py + 1.6)
  let pbr = (10.8, py - 1.6)
  rect(ptl, pbr, fill: white, stroke: (paint: c-garnet, thickness: 1pt))
  callout((6.2 - 1.1, -0.65), (6.2 + 1.1, -0.65), ptl, (pbr.at(0), ptl.at(1)))

  // Feature maps arriving from the two branches.
  prism(3.0, py + 0.62, w: 0.32, h: 0.9, d: 0.34, fill: rgb("#CDEDFE"))
  content((3.0, py + 1.28), text(size: 6.5pt, fill: c-70black)[$F_"rgb"$])
  prism(3.0, py - 0.78, w: 0.32, h: 0.9, d: 0.34, fill: rgb("#8edbd5"))
  content((3.0, py - 1.32), text(size: 6.5pt, fill: c-70black)[$F_"ir"$])

  // concat -> gate -> weighted sum
  fop((4.6, py), $⊕$)
  content((4.6, py - 0.6), text(size: 6.5pt, fill: c-70black)[concat])

  fbox((6.2, py), "1x1 conv", w: 1.25, h: 0.6, fill: c-10black)
  fbar((7.6, py), "sigmoid", w: 0.34, h: 0.85, above: true)

  fop((8.9, py), $times$)
  content((8.9, py - 0.6), text(size: 6.5pt, fill: c-70black)[gate])

  farrow((3.55, py + 0.62), (4.25, py + 0.16))
  farrow((3.55, py - 0.78), (4.25, py - 0.16))
  farrow((4.9, py), (5.55, py))
  farrow((6.85, py), (7.38, py))
  farrow((7.82, py), (8.6, py))
  farrow((9.2, py), (9.85, py))

  prism(9.95, py, w: 0.32, h: 0.9, d: 0.34, fill: rgb("#e681a8"))
  content((10.1, py - 0.72), text(size: 6.5pt, fill: c-70black)[$F_"fused"$])

  content((6.4, py - 2.15), text(size: 7.5pt, fill: c-garnet)[*Gated fusion*, expanded])
})
