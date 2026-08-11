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
