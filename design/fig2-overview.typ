// FIGURE 2 — a flat system overview, no isometric anywhere.
//
// Second draft. The first drew every block as an identical rectangle, so the
// figure said nothing until you read the labels. Shape now carries meaning:
// the backbone narrows because it reduces resolution, the neck is a bar
// because it is a bottleneck, the data ends are stacked planes because they
// are batched, and only the head — which preserves structure — is a rectangle.
//
// TARGET API — the source I wish I could write:
//
//   #draw-network(
//     (
//       source(name: "in",   label: "RGB frame",  sub: "640x640x3"),
//       block(name: "bb",    label: "Backbone",   sub: "CSPDarknet",
//             role: "downsample"),
//       block(name: "neck",  label: "Neck",       sub: "PAN-FPN",
//             role: "bottleneck"),
//       block(name: "head",  label: "Head",       sub: "decoupled"),
//       sink(name: "out",    label: "Detections", sub: "N x 6"),
//     ),
//     view: "flat",
//   )
//
// Notes on what this figure argues for.
//   - `view:` selects the renderer. The layer vocabulary is unchanged — names,
//     labels, connections — so the SAME description could render flat or
//     isometric. That is the whole thesis.
//   - `role:` picks the glyph. It should DEFAULT from the layer type wherever
//     the type already implies one: pool and conv-with-stride are downsamples,
//     deconv and unpool are upsamples, gap is a bottleneck. Authors should only
//     reach for `role:` on a generic `block()`.
//   - `sub:` is the secondary line. No constructor has this today.

#import "@preview/cetz:0.5.2": canvas
#import "mock.typ": *

#set page(width: auto, height: auto, margin: 6mm)

#canvas(length: 1cm, {
  let y = 0

  fstack((0, y), "RGB frame", sub: "640x640x3", fill: c-sand)
  ftrap((3.1, y), "Backbone", sub: "CSPDarknet", w: 2.3, h: 1.75, h-out: 0.95, fill: c-10black)
  fbar((5.7, y), "Neck", sub: "PAN-FPN", h: 1.0)
  fbox((8.0, y), "Head", sub: "decoupled", w: 1.9, h: 1.0, fill: c-30black)
  fstack((10.8, y), "Detections", sub: "N x 6", fill: c-congaree-l)

  farrow((0.75, y), (1.85, y))
  farrow((4.35, y), (5.4, y), label: "P3-P5")
  farrow((6.0, y), (6.95, y))
  farrow((9.0, y), (10.15, y))
})
