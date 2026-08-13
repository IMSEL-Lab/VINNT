// The adjacent-pair edge set, the weight encoding pipeline, and the extra-
// edge routing (straight, arc, loop, sum node). Adjacent edges are pure data
// here; draw.typ turns them into lines. Extra-edge paths are drawn here.

#import "@preview/cetz:0.5.2": draw
#import "../validate.typ": check-keys

// ---------------------------------------------------------------------------
// Deterministic weights. Typst has no RNG and the goldens must be stable, so
// "random" runs a small LCG over a per-edge hash of the seed.

#let lcg(s) = calc.rem-euclid(s * 1664525 + 1013904223, 4294967296)

#let rand-weight(seed, l, i, j) = {
  let s = calc.rem-euclid(seed + l * 73856093 + i * 19349663 + j * 83492791, 4294967296)
  s = lcg(s)
  s = lcg(s)
  2.0 * (s / 4294967295) - 1.0
}

// The weight of one adjacent-pair edge, in the W x convention:
// weights.at(l - 1) maps gap l and entry [j][i] is the edge i -> j.
#let weight-of(weights, seed, l, i, j) = {
  if weights == none { none } else if type(weights) == array {
    weights.at(l - 1).at(j - 1).at(i - 1)
  } else if type(weights) == function {
    weights(l, i, j)
  } else {
    rand-weight(seed, l, i, j)
  }
}

// The |w| that saturates the encoding. Explicit matrices are scanned in
// full, collapsed entries included, so the visible encoding stays honest
// about the true scale; a function or "random" is scanned over drawn edges.
#let weight-range-of(weights, seed, requested, edges) = {
  if weights == none { return none }
  if requested != auto { return float(requested) }
  let m = 0.0
  if type(weights) == array {
    for matrix in weights {
      for row in matrix {
        for v in row { m = calc.max(m, calc.abs(float(v))) }
      }
    }
  } else {
    for e in edges {
      m = calc.max(m, calc.abs(float(weight-of(weights, seed, e.l, e.i, e.j))))
    }
  }
  m
}

// ---------------------------------------------------------------------------
// Adjacent-pair enumeration. `cols` records carry (kind, pos, active) where
// `active` lists drawn, non-excluded neurons as
// (neuron, y, dropped, dimmed, highlighted). Dropped neurons keep their node
// (with the X) but lose their edges; a gap column breaks adjacency.

#let edge-set(cols, edge-filter) = {
  let edges = ()
  for k in range(cols.len() - 1) {
    let a = cols.at(k)
    let b = cols.at(k + 1)
    if a.kind != "layer" or b.kind != "layer" { continue }
    let l = a.pos
    for na in a.active {
      if na.dropped { continue }
      for nb in b.active {
        if nb.dropped { continue }
        if edge-filter != none {
          let keep = edge-filter(l, na.neuron, nb.neuron)
          if type(keep) != bool {
            panic(
              "vinnt: `edge-filter` must return true or false; got "
                + repr(keep) + " for (l: " + str(l) + ", i: " + str(na.neuron)
                + ", j: " + str(nb.neuron) + ")."
            )
          }
          if not keep { continue }
        }
        edges.push((
          l: l, i: na.neuron, j: nb.neuron, a: k, b: k + 1,
          y1: na.y, y2: nb.y,
          dimmed: na.dropped or na.dimmed or nb.dimmed,
          highlighted: na.highlighted or nb.highlighted,
        ))
      }
    }
  }
  edges
}

// ---------------------------------------------------------------------------
// The style pipeline for one adjacent-pair edge. Order: base stroke, weight
// encoding, node-state opacity, then the override dicts (the mlp-edge
// override, then the edge-style callback - the last word). Returns
// (stroke, paint) where `paint` is the solid color for arrowhead fills.

#let apply-override(state, ov, where) = {
  check-keys("edge style", where, ov, ("paint", "thickness", "dash", "opacity"))
  if "paint" in ov { state.paint = ov.paint }
  if "thickness" in ov { state.thickness = ov.thickness }
  if "dash" in ov { state.dash = ov.dash }
  if "opacity" in ov { state.opacity = ov.opacity }
  state
}

#let styled-edge(edge, w, wrange, o, overrides) = {
  let base = o.edge-stroke
  let s = (
    paint: base.at("paint", default: black),
    thickness: base.at("thickness", default: 0.4pt),
    dash: base.at("dash", default: none),
    opacity: o.edge-opacity,
  )
  if w != none and wrange != none and wrange > 0 {
    let t = calc.min(calc.abs(float(w)) / wrange, 1)
    if o.weight-encode.contains("color") {
      s.paint = if w >= 0 { o.weight-colors.positive } else { o.weight-colors.negative }
    }
    if o.weight-encode.contains("thickness") {
      let (t0, t1) = o.weight-thickness
      s.thickness = t0 + (t1 - t0) * t
    }
    if o.weight-encode.contains("opacity") {
      s.opacity = 15% + 85% * t
    }
  }
  if edge.dimmed { s.opacity = s.opacity * 0.45 }
  if edge.highlighted { s.opacity = 100% }
  for (ov, where) in overrides {
    s = apply-override(s, ov, where)
  }
  (
    stroke: (paint: s.paint.transparentize(100% - s.opacity), thickness: s.thickness, dash: s.dash),
    paint: s.paint,
  )
}

// ---------------------------------------------------------------------------
// Extra-edge routing. `P` is the direction mapper; every path is authored in
// logical coordinates and mapped point by point. Arrowheads are filled
// stealth, always.

#let stealth-mark(paint) = (end: "stealth", fill: paint, scale: 0.6)

#let straight-extra(P, p1, p2, stroke, paint, arrow) = {
  draw.line(P(p1), P(p2), stroke: stroke,
    mark: if arrow { stealth-mark(paint) } else { none })
}

// A skip arc: cubic through a control height clearing the tallest
// intervening column (above or below the network).
#let skip-arc(P, p1, p2, hy, stroke, paint, arrow) = {
  let c1 = (p1.at(0) + (p2.at(0) - p1.at(0)) * 0.28, hy)
  let c2 = (p1.at(0) + (p2.at(0) - p1.at(0)) * 0.72, hy)
  draw.bezier(P(p1), P(p2), P(c1), P(c2), stroke: stroke,
    mark: if arrow { stealth-mark(paint) } else { none })
}

// A recurrent self-loop over a column, head returning into the top node.
#let loop-arc(P, x, ytop, trim, stroke, paint, arrow) = {
  let p1 = (x - trim * 0.9, ytop + trim * 0.55)
  let p2 = (x + trim * 0.9, ytop + trim * 0.55)
  let c1 = (x - 0.62, ytop + 1.05)
  let c2 = (x + 0.62, ytop + 1.05)
  draw.bezier(P(p1), P(p2), P(c1), P(c2), stroke: stroke,
    mark: if arrow { stealth-mark(paint) } else { none })
}

// The ResNet merge node: a small circled plus.
#let sum-node(P, pos, r, paint) = {
  let (x, y) = pos
  let st = (paint: paint, thickness: 0.7pt)
  draw.circle(P(pos), radius: r, fill: white, stroke: st)
  draw.line(P((x - r * 0.55, y)), P((x + r * 0.55, y)), stroke: st)
  draw.line(P((x, y - r * 0.55)), P((x, y + r * 0.55)), stroke: st)
}
