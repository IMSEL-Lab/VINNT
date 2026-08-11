// Mock primitives for the design sketches.
//
// These exist only so the target figures in this folder can be LOOKED AT while
// the API is being decided. Nothing here is a proposal for how the library
// should be implemented — it is scaffolding, and it should be deleted once the
// real renderers exist.

#import "@preview/cetz:0.5.2": draw
#import draw: line, rect, content, circle, bezier

// Palette. Flat blocks read as roles, not as tensor types, so they get their
// own scale rather than reusing the isometric layer colors.
#let c-garnet = rgb("#73000A")
#let c-atlantic = rgb("#466A9F")
#let c-congaree = rgb("#1F414D")
#let c-warmgrey = rgb("#676156")
#let c-sand = rgb("#FFF2E3")
#let c-10black = rgb("#ECECEC")
#let c-30black = rgb("#C7C7C7")
#let c-70black = rgb("#5C5C5C")
#let c-honeycomb = rgb("#A49137")
#let c-congaree-l = rgb("#1F414D").lighten(72%)

#let stealth(color) = (end: "stealth", fill: color, scale: 0.6)
#let stealth2(color) = (start: "stealth", end: "stealth", fill: color, scale: 0.6)

// A flat labelled block. The overview vocabulary.
#let fbox(
  pos,
  label,
  w: 2.2,
  h: 1.1,
  fill: c-10black,
  stroke-color: black,
  text-color: black,
  sub: none,
  name: none,
) = {
  let (x, y) = pos
  rect(
    (x - w / 2, y - h / 2),
    (x + w / 2, y + h / 2),
    fill: fill,
    stroke: (paint: stroke-color, thickness: 1pt),
    name: name,
  )
  if sub == none {
    content((x, y), text(size: 9pt, fill: text-color)[#label])
  } else {
    content((x, y + 0.16), text(size: 9pt, fill: text-color)[#label])
    content((x, y - 0.22), text(size: 6.5pt, fill: text-color.lighten(25%))[#sub])
  }
}

// ---------------------------------------------------------------------------
// SHAPE VOCABULARY
//
// Geometry carries meaning before any label is read. This is the one good idea
// in neural-viz and the thing the first draft of fig2 lost by drawing every
// block as an identical rectangle.
//
//   narrowing trapezoid   reduces resolution   (encoder, backbone, downsample)
//   widening trapezoid    raises resolution    (decoder, upsample)
//   thin vertical bar     bottleneck           (latent, neck, embedding)
//   stacked planes        batched data         (dataset, image input, output set)
//   rectangle             structure-preserving (head, generic op)
//   circle                elementwise op       (sum, product, gate)
//
// A block should only be a rectangle when it genuinely has no structural story.
// ---------------------------------------------------------------------------

#let block-label(x, y, label, sub, text-color, inside) = {
  let (ly, sy) = if inside { (y + 0.16, y - 0.22) } else { (y, y - 0.3) }
  if sub == none {
    content((x, if inside { y } else { y }), text(size: 9pt, fill: text-color)[#label])
  } else {
    content((x, ly), text(size: 9pt, fill: text-color)[#label])
    content((x, sy), text(size: 6.5pt, fill: text-color.lighten(25%))[#sub])
  }
}

// Narrowing trapezoid — anything that reduces spatial resolution.
#let ftrap(
  pos,
  label,
  w: 2.2,
  h: 1.5,
  h-out: 0.8,
  fill: c-10black,
  stroke-color: black,
  text-color: black,
  sub: none,
  flip: false,
) = {
  let (x, y) = pos
  let (hl, hr) = if flip { (h-out, h) } else { (h, h-out) }
  line(
    (x - w / 2, y - hl / 2),
    (x - w / 2, y + hl / 2),
    (x + w / 2, y + hr / 2),
    (x + w / 2, y - hr / 2),
    close: true,
    fill: fill,
    stroke: (paint: stroke-color, thickness: 1pt),
  )
  block-label(x, y, label, sub, text-color, true)
}

// Thin vertical bar — a bottleneck.
//
// `above` lifts the label over the bar. Needed in fig3, where the space beneath
// the overview row is reserved for magnification callouts. That the label has
// to dodge is itself a finding: label placement cannot be a fixed offset when
// callouts share the figure. See FINDINGS item 9.
#let fbar(
  pos,
  label,
  w: 0.42,
  h: 1.5,
  fill: c-honeycomb,
  stroke-color: black,
  sub: none,
  above: false,
) = {
  let (x, y) = pos
  rect(
    (x - w / 2, y - h / 2),
    (x + w / 2, y + h / 2),
    fill: fill,
    stroke: (paint: stroke-color, thickness: 1pt),
  )
  let edge = if above { y + h / 2 + 0.28 } else { y - h / 2 - 0.28 }
  let step = if above { 0.27 } else { -0.27 }
  content((x, edge), text(size: 8pt)[#label])
  if sub != none {
    content((x, edge + step), text(size: 6.5pt, fill: c-70black)[#sub])
  }
}

// Stacked planes — batched data entering or leaving the system.
#let fstack(
  pos,
  label,
  w: 1.15,
  h: 1.3,
  fill: c-sand,
  stroke-color: black,
  sub: none,
  n: 3,
  step: 0.13,
) = {
  let (x, y) = pos
  // back-to-front so the front plane paints over the others
  for i in range(n - 1, -1, step: -1) {
    let dx = i * step
    let dy = i * step
    rect(
      (x - w / 2 + dx, y - h / 2 + dy),
      (x + w / 2 + dx, y + h / 2 + dy),
      fill: fill,
      stroke: (paint: stroke-color, thickness: 0.9pt),
    )
  }
  content((x, y - h / 2 - 0.28), text(size: 8pt)[#label])
  if sub != none {
    content((x, y - h / 2 - 0.55), text(size: 6.5pt, fill: c-70black)[#sub])
  }
}

// Elementwise operator node.
#let fop(pos, symbol, r: 0.26, fill: white, stroke-color: black) = {
  let (x, y) = pos
  circle((x, y), radius: r, fill: fill, stroke: (paint: stroke-color, thickness: 1pt))
  content((x, y), text(size: 9pt)[#symbol])
}

// Flow arrow between two flat blocks.
#let farrow(from, to, label: none, color: black) = {
  line(from, to, stroke: (paint: color, thickness: 1pt), mark: stealth(color))
  if label != none {
    let mx = (from.at(0) + to.at(0)) / 2
    let my = (from.at(1) + to.at(1)) / 2
    content((mx, my + 0.28), text(size: 6.5pt, fill: color)[#label])
  }
}

// Node positions for a column, as a pure function. Kept separate from the
// drawing so the caller can lay out edges before or after the nodes.
//
// `count` is the true layer width. When it exceeds `cutoff` the column is drawn
// collapsed: a few nodes, a vertical ellipsis, then the last node. This is the
// cutoff-driven ellipsis borrowed from nndiagram.
#let neuron-slots(count, cutoff: 6, pitch: 0.52) = {
  let collapsed = count > cutoff
  let slots = if collapsed { 5 } else { count }
  let y0 = (slots - 1) * pitch / 2
  let ys = range(slots).map(i => y0 - i * pitch)
  (
    collapsed: collapsed,
    ys: ys,
    // the drawable node positions, with the ellipsis slot removed
    nodes: ys.enumerate().filter(p => not (collapsed and p.at(0) == 2)).map(p => p.at(1)),
    top: y0,
  )
}

// Draw a column of neurons.
#let neuron-column(
  x,
  count,
  cutoff: 6,
  pitch: 0.52,
  r: 0.17,
  fill: white,
  stroke-color: black,
  label: none,
) = {
  let s = neuron-slots(count, cutoff: cutoff, pitch: pitch)

  for (i, y) in s.ys.enumerate() {
    // In a collapsed column the middle slot is the ellipsis, not a node.
    if s.collapsed and i == 2 {
      for k in range(3) {
        circle((x, y + 0.12 - k * 0.12), radius: 0.022, fill: black, stroke: none)
      }
    } else {
      circle((x, y), radius: r, fill: fill, stroke: (paint: stroke-color, thickness: 0.8pt))
    }
  }

  if label != none {
    content((x, -s.top - 0.55), text(size: 7pt)[#label])
  }
}

// Fully connect two neuron columns.
#let connect-columns(x1, ys1, x2, ys2, r: 0.17, color: c-70black, opacity: 45%) = {
  for a in ys1 {
    for b in ys2 {
      line(
        (x1 + r, a),
        (x2 - r, b),
        stroke: (paint: color.transparentize(100% - opacity), thickness: 0.4pt),
      )
    }
  }
}

// A mock isometric prism, standing in for a real vinnt block.
//
// This exists only because `draw-network` opens its own `canvas()` and so
// cannot be placed inside another one. See design/FINDINGS.md — that is a real
// constraint the composed figures run into, not an accident of this sketch.
#let prism(
  x,
  y,
  w: 0.5,
  h: 1.6,
  d: 0.45,
  fill: rgb("#CDEDFE"),
  label: none,
  sub: none,
) = {
  let ox = d * 0.55
  let oy = d * 0.42
  let st = (paint: black.lighten(20%), thickness: 0.65pt)

  // front face
  rect((x, y - h / 2), (x + w, y + h / 2), fill: fill, stroke: st)
  // top face
  line(
    (x, y + h / 2),
    (x + ox, y + h / 2 + oy),
    (x + w + ox, y + h / 2 + oy),
    (x + w, y + h / 2),
    close: true,
    fill: fill.darken(8%),
    stroke: st,
  )
  // right face
  line(
    (x + w, y + h / 2),
    (x + w + ox, y + h / 2 + oy),
    (x + w + ox, y - h / 2 + oy),
    (x + w, y - h / 2),
    close: true,
    fill: fill.darken(18%),
    stroke: st,
  )
  if label != none {
    content((x + w / 2 + ox / 2, y - h / 2 - 0.3), text(size: 6.5pt)[#label])
  }
  if sub != none {
    content((x + w / 2 + ox / 2, y + h / 2 + oy + 0.25), text(size: 6pt, fill: c-70black)[#sub])
  }
}

// Magnification callout: connect a box in the overview to a detail panel below.
#let callout(box-tl, box-br, panel-tl, panel-br, color: c-garnet) = {
  let dash = (paint: color, thickness: 0.9pt, dash: (2.5pt, 2pt))
  line(box-tl, panel-tl, stroke: dash)
  line(box-br, panel-br, stroke: dash)
}
