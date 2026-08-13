// mlp-content and draw-mlp: validate, lay out the columns, then draw edges,
// nodes, and the caption rows. draw-mlp is exactly canvas(length: unit,
// mlp-content(..)), so the figure can also be embedded in a user's canvas.

#import "@preview/cetz:0.5.2": canvas, draw
#import "keys.typ": mlp-figure-defaults, bracket-activations, glyph-names
#import "theme.typ": mlp-grey, mlp-caption-ink, mlp-fonts
#import "validate.typ" as mval
#import "geom.typ" as mgeom
#import "glyphs.typ" as mglyphs
#import "edges.typ" as medges

// A filled stealth arrowhead; the only arrowhead this renderer draws.
#let smark(paint) = (end: "stealth", fill: paint, scale: 0.6)

// Format a 0..1 value with two decimals for show-value-text.
#let fmt2(v) = {
  let n = int(calc.round(v * 100))
  let fr = calc.rem(n, 100)
  let wh = int((n - fr) / 100)
  str(wh) + "." + (if fr < 10 { "0" + str(fr) } else { str(fr) })
}

// Perceived luminance test for value-text contrast; `c` is an rgb color.
#let is-dark(c) = {
  let comp = c.components()
  comp.at(0) * 0.299 + comp.at(1) * 0.587 + comp.at(2) * 0.114 < 55%
}

// The role-based auto node label (1-based true indices).
#let auto-node-label(role, pos, n-hidden, i) = {
  if role == "input" { $x_#i$ } else if role == "output" { $hat(y)_#i$ } else if n-hidden == 1 { $h_#i$ } else {
    let k = pos - 1
    $h_#i^((#k))$
  }
}

#let edge-key(l, i, j) = str(l) + "." + str(i) + "." + str(j)

#let mlp-content(layers, ..opts) = {
  // ------------------------------------------------------------------ options
  mval.check-figure-opts(opts)
  let o = mlp-figure-defaults
  for (k, v) in opts.named() { o.insert(k, v) }
  mval.check-figure-values(o)
  let pal = mval.resolve-palette(o.palette)
  let wc = mlp-figure-defaults.weight-colors
  for (k, v) in o.weight-colors { wc.insert(k, v) }
  o.weight-colors = wc

  let up = o.direction == "up"
  let P = p => mgeom.map-point(o.direction, p)

  // ------------------------------------------------------------------ columns
  let raw-cols = mval.normalize-columns(layers)
  let names = mval.resolve-names(raw-cols)
  let L = raw-cols.filter(c => c.kind == "layer").len()
  let n-hidden = calc.max(L - 2, 0)

  if type(o.layer-labels) == array and o.layer-labels.len() != L {
    panic(
      "vinnt: `layer-labels` has " + str(o.layer-labels.len())
        + " entries but the figure has " + str(L) + " layers; pass one entry "
        + "(content, string or none) per layer."
    )
  }

  let cols = ()
  for (ci, c) in raw-cols.enumerate() {
    let name = names.at(ci)
    if c.kind == "gap" {
      let pitch = c.src.at("pitch", default: 0.6 * o.layer-pitch)
      if (type(pitch) != int and type(pitch) != float) or pitch <= 0 {
        panic(
          "vinnt: `pitch` on gap " + str(c.pos) + " (\"" + name + "\") must "
            + "be a positive number in canvas units; got " + repr(pitch) + "."
        )
      }
      cols.push((
        kind: "gap", pos: c.pos, name: name, width: pitch,
        label: c.src.at("label", default: none), sub: none,
      ))
      continue
    }
    let src = c.src
    mval.check-layer-detail(src, c.pos, name, L)
    let count = src.count
    let role = if c.pos == 1 { "input" } else if c.pos == L and L > 1 { "output" } else { "hidden" }
    let act = if "activation" in src { src.activation } else if c.pos >= 2 { o.activation } else { none }
    if o.activation-style != "caption" {
      mval.check-glyph-activation(act, c.pos, name, o.activation-style)
    }
    let is-bracket = type(act) == str and bracket-activations.contains(act)
    let shape = if "shape" in src { src.shape } else if o.activation-style == "split" and act != none and not is-bracket { "split" } else if c.pos == 1 and o.input-style == "square" { "square" } else { o.node-shape }
    let nsize = src.at("node-size", default: o.node-size)
    let trim = if shape == "split" { nsize * 1.35 } else { nsize }
    let stroke = src.at("stroke", default: o.node-stroke)
    if type(stroke) == color { stroke = (paint: stroke, thickness: 0.8pt) }
    let cutoff = if src.at("show-all", default: false) { none } else { o.cutoff }
    let slots = mgeom.layer-slots(count, cutoff, o.collapse-to, o.node-pitch)
    let dropped = src.at("dropped", default: ())
    let dimmed = src.at("dimmed", default: ())
    let highlighted = src.at("highlighted", default: ())
    let excluded = src.at("exclude", default: ())
    let active = slots.drawn.filter(d => not excluded.contains(d.neuron)).map(d => (
      neuron: d.neuron, y: d.y,
      dropped: dropped.contains(d.neuron),
      dimmed: dimmed.contains(d.neuron),
      highlighted: highlighted.contains(d.neuron),
    ))
    let label = src.at("label", default: none)
    if label == none {
      if o.layer-labels == auto {
        label = if c.pos == 1 { "input" } else if c.pos == L { "output" } else if n-hidden == 1 { "hidden" } else { "hidden " + str(c.pos - 1) }
      } else if type(o.layer-labels) == array {
        label = o.layer-labels.at(c.pos - 1)
      }
    }
    cols.push((
      kind: "layer", pos: c.pos, name: name, width: o.layer-pitch,
      count: count, role: role, act: act, is-bracket: is-bracket,
      shape: shape, nsize: nsize, trim: trim,
      fill: src.at("fill", default: pal.at(role)), stroke: stroke,
      slots: slots, active: active,
      dropped: dropped, dimmed: dimmed, highlighted: highlighted, excluded: excluded,
      values: src.at("values", default: none),
      show-value-text: src.at("show-value-text", default: false),
      node-label: src.at("node-label", default: none),
      has-own-node-label: "node-label" in src,
      node-label-pos: src.at("node-label-pos", default: "inside"),
      node-style: src.at("node-style", default: none),
      label: label, sub: src.at("sub", default: none),
      bias: src.at("bias", default: o.bias and c.pos < L),
    ))
  }

  let xs = mgeom.column-xs(cols.map(c => c.width))
  cols = cols.enumerate().map(((i, c)) => { c.insert("x", xs.at(i)); c })

  // Layer index for endpoint resolution and the weight shape check.
  let index = ()
  for (ci, c) in cols.enumerate() {
    if c.kind == "layer" {
      index.push((
        col: ci, pos: c.pos, name: c.name, count: c.count,
        drawn: c.active.map(a => a.neuron), excluded: c.excluded,
      ))
    }
  }
  let gap-names = cols.filter(c => c.kind == "gap").map(c => c.name)
  let counts = index.map(r => r.count)
  mval.check-weights(o.weights, counts)

  // ------------------------------------------------------------------- edges
  let edges = medges.edge-set(cols, o.edge-filter)
  let edge-idx = (:)
  for (k, e) in edges.enumerate() { edge-idx.insert(edge-key(e.l, e.i, e.j), k) }
  let wrange = medges.weight-range-of(o.weights, o.seed, o.weight-range, edges)

  // -------------------------------------------------------------- mlp-edge(s)
  let adj-override = (:)   // edge key -> (ov, where, arrow, label)
  let gap-override = (:)   // str(l)   -> (ov, where, arrow)
  let extras = ()
  for (ei, e) in o.edges.enumerate() {
    let where = "on edges entry " + str(ei + 1)
    let f = mval.resolve-endpoint(e.from, index, gap-names, "`from` " + where)
    let t = mval.resolve-endpoint(e.to, index, gap-names, "`to` " + where)
    if (f.neuron == none) != (t.neuron == none) {
      panic(
        "vinnt: mlp-edge " + where + " mixes a node-level endpoint with a "
          + "layer-level one; give both endpoints a neuron index, or neither."
      )
    }
    let ov = (:)
    for k in ("paint", "thickness", "dash", "opacity") {
      if k in e { ov.insert(k, e.at(k)) }
    }
    let ca = cols.at(index.at(f.pos - 1).col)
    let cb = cols.at(index.at(t.pos - 1).col)
    let col-adjacent = index.at(t.pos - 1).col - index.at(f.pos - 1).col == 1
    let node-level = f.neuron != none
    let is-loop = not node-level and f.pos == t.pos
    let is-adjacent = t.pos == f.pos + 1 and col-adjacent
    if e.at("sum", default: false) and (node-level or is-loop or is-adjacent) {
      panic("vinnt: `sum` " + where + " applies to layer-level skip edges only.")
    }
    if node-level and f.pos == t.pos and f.neuron == t.neuron {
      panic(
        "vinnt: mlp-edge " + where + " connects a neuron to itself; recurrent "
          + "loops are layer-level, e.g. mlp-edge(from: \"" + f.name
          + "\", to: \"" + f.name + "\", style: \"loop\")."
      )
    }
    let style = e.at("style", default: auto)
    if style == "loop" and not is-loop {
      panic("vinnt: mlp-edge " + where + " has style \"loop\" but `from` and `to` differ; a loop needs from = to at layer level.")
    }
    if is-loop and style == auto { style = "loop" }
    if is-loop and style != "loop" {
      panic("vinnt: mlp-edge " + where + " has from = to, which is a recurrent loop; its style can only be \"loop\".")
    }

    if node-level and is-adjacent and (style == auto or style == "straight") {
      // A style override for the existing adjacent-pair edge; if a filter
      // removed that edge, this re-adds it as a single straight link.
      let k = edge-key(f.pos, f.neuron, t.neuron)
      if k in edge-idx {
        adj-override.insert(k, (
          ov: ov, where: "from mlp-edge " + where,
          arrow: e.at("arrow", default: false), label: e.at("label", default: none),
        ))
        continue
      }
      let ya = ca.active.find(a => a.neuron == f.neuron).y
      let yb = cb.active.find(a => a.neuron == t.neuron).y
      let paint = ov.at("paint", default: o.edge-stroke.at("paint", default: black))
      let opac = ov.at("opacity", default: o.edge-opacity)
      extras.push((
        kind: "straight",
        p1: (ca.x + ca.trim, ya), p2: (cb.x - cb.trim, yb),
        stroke: (
          paint: paint.transparentize(100% - opac),
          thickness: ov.at("thickness", default: o.edge-stroke.at("thickness", default: 0.4pt)),
          dash: ov.at("dash", default: none),
        ),
        paint: paint, arrow: e.at("arrow", default: false),
        label: e.at("label", default: none),
        label-at: ((ca.x + cb.x) / 2, (ya + yb) / 2 + 0.14),
      ))
      continue
    }
    if not node-level and is-adjacent {
      gap-override.insert(str(f.pos), (
        ov: ov, where: "from mlp-edge " + where,
        arrow: e.at("arrow", default: false), label: e.at("label", default: none),
      ))
      continue
    }

    // A new routed edge: loop, skip arc, or explicit straight.
    let paint = ov.at("paint", default: pal.accent)
    let opac = ov.at("opacity", default: 100%)
    let stroke = (
      paint: paint.transparentize(100% - opac),
      thickness: ov.at("thickness", default: o.edge-stroke.at("thickness", default: 0.4pt)),
      dash: ov.at("dash", default: none),
    )
    let arrow = e.at("arrow", default: true)
    if is-loop {
      let ytop = ca.slots.top
      extras.push((
        kind: "loop", x: ca.x, ytop: ytop, trim: ca.trim,
        stroke: stroke, paint: paint, arrow: arrow,
        label: e.at("label", default: none),
        label-at: (ca.x, ytop + 1.18),
        top-ext: ytop + 1.1,
      ))
      continue
    }
    // Skip arc (or explicit straight) between distinct layers.
    let lo = calc.min(index.at(f.pos - 1).col, index.at(t.pos - 1).col)
    let hi = calc.max(index.at(f.pos - 1).col, index.at(t.pos - 1).col)
    let between = cols.slice(lo + 1, hi)
    let pool = if between.len() == 0 { (ca, cb) } else { between }
    let ends = if node-level { () } else { (ca.slots.top + ca.trim, cb.slots.top + cb.trim) }
    let inter-top = calc.max(
      0.2,
      ..pool.map(c => if c.kind == "layer" { c.slots.top + c.nsize } else { 0.2 }),
      ..ends,
    )
    if style == auto { style = "arc-above" }
    let below = style == "arc-below"
    let hy = if below { -(inter-top + 0.75) } else { inter-top + 0.75 }
    let side = if below { -1 } else { 1 }
    let (p1, p2) = if node-level {
      let ya = ca.active.find(a => a.neuron == f.neuron).y
      let yb = cb.active.find(a => a.neuron == t.neuron).y
      ((ca.x, ya + side * ca.trim), (cb.x, yb + side * cb.trim))
    } else {
      (
        (ca.x, ca.slots.top * side + side * ca.trim),
        (cb.x, cb.slots.top * side + side * cb.trim),
      )
    }
    if style == "straight" {
      extras.push((
        kind: "straight", p1: p1, p2: p2, stroke: stroke, paint: paint,
        arrow: arrow, label: e.at("label", default: none),
        label-at: ((p1.at(0) + p2.at(0)) / 2, (p1.at(1) + p2.at(1)) / 2 + 0.14),
      ))
      continue
    }
    let sum-spec = none
    if e.at("sum", default: false) {
      let sr = 0.13
      let sy = side * (cb.slots.top + cb.trim + 0.45)
      sum-spec = (
        pos: (cb.x, sy), r: sr, side: side,
        into: (cb.x, side * (cb.slots.top + cb.trim + 0.03)),
      )
      p2 = (cb.x, sy + side * sr)
    }
    let apex = (p1.at(1) + p2.at(1) + 6 * hy) / 8
    extras.push((
      kind: "arc", p1: p1, p2: p2, hy: hy, stroke: stroke, paint: paint,
      arrow: arrow, label: e.at("label", default: none),
      label-at: ((p1.at(0) + p2.at(0)) / 2, apex + side * 0.16),
      sum: sum-spec,
      top-ext: if below { 0 } else { apex + 0.1 },
      bottom-ext: if below { apex - 0.1 } else { 0 },
    ))
  }

  // ------------------------------------------------------- edge label lookups
  for (li, el) in o.edge-labels.enumerate() {
    let k = edge-key(el.l, el.i, el.j)
    if el.l < 1 or el.l > counts.len() - 1 or k not in edge-idx {
      panic(
        "vinnt: edge-labels entry " + str(li + 1) + " (l: " + str(el.l)
          + ", i: " + str(el.i) + ", j: " + str(el.j) + ") does not name a "
          + "drawn edge. Gaps run 1.." + str(calc.max(counts.len() - 1, 0))
          + ", and edges attach only to drawn, non-dropped neurons that the "
          + "edge filter kept."
      )
    }
  }

  // --------------------------------------------------------------- bias edges
  let bias-edges = ()
  let bias-nodes = ()
  for (ci, c) in cols.enumerate() {
    if c.kind != "layer" or not c.bias { continue }
    if ci + 1 >= cols.len() or cols.at(ci + 1).kind != "layer" { continue }
    let nb = cols.at(ci + 1)
    let by = c.slots.top + o.node-pitch
    bias-nodes.push((x: c.x, y: by, nsize: c.nsize, col: ci))
    for a in nb.active {
      if a.dropped { continue }
      bias-edges.push((p1: (c.x + c.nsize, by), p2: (nb.x - nb.trim, a.y)))
    }
  }

  // ------------------------------------------------------------ baseline rows
  let layer-cols = cols.filter(c => c.kind == "layer")
  let maxslottop = calc.max(..layer-cols.map(c => c.slots.top))
  let any-bias = bias-nodes.len() > 0
  let bias-top = calc.max(0, ..bias-nodes.map(b => b.y + b.nsize))

  let has-label = cols.any(c => c.label != none)
  let has-sub = cols.any(c => c.sub != none)
  let act-caption = o.activation-style == "caption"
  let act-block = o.activation-style == "block"
  let has-act-row = (act-caption and layer-cols.any(c => c.act != none)) or (act-block and layer-cols.any(c => c.act != none and not c.is-bracket))
  let badge-for(c) = c.kind == "layer" and (o.count-badges == true or (o.count-badges == auto and c.slots.collapsed))
  let has-badge = o.count-badges != false and cols.any(badge-for)
  let block-half = if act-block { calc.max(0.17, ..layer-cols.map(c => c.nsize)) } else { 0.17 }
  let rows = mgeom.row-offsets(has-label, has-sub, has-act-row, has-badge,
    act-block: act-block and has-act-row, act-block-half: block-half)

  let ext-below = calc.max(maxslottop, ..extras.map(x => -x.at("bottom-ext", default: 0)))
  let ext-above = calc.max(maxslottop, ..extras.map(x => x.at("top-ext", default: 0)))
  if any-bias { ext-above = calc.max(ext-above, bias-top) }

  // Caption geometry. In "up" mode captions sit left of the rows and badges
  // right; otherwise everything follows label-pos on shared baseline rows.
  let below = o.label-pos == "below"
  let cap-row-y(off) = if below { -(ext-below + off) } else { ext-above + off }
  let label-y = none
  let sub-y = none
  let act-y = none
  let badge-y = none
  let cap-left = (label: none, sub-dy: 0.26, act: none)
  let badge-x = none
  if up {
    let base = ext-above
    cap-left.label = base + 0.55
    if has-act-row { cap-left.act = base + 0.55 + (if has-label { 1.15 } else { 0 }) }
    badge-x = ext-below + 0.55
  } else {
    if rows.label != none {
      if below or rows.sub == none {
        label-y = cap-row-y(rows.label)
        if rows.sub != none { sub-y = cap-row-y(rows.sub) }
      } else {
        // above: the sub still reads beneath its label
        label-y = cap-row-y(rows.sub)
        sub-y = cap-row-y(rows.label)
      }
    }
    if rows.act != none { act-y = cap-row-y(rows.act) }
    if rows.badge != none { badge-y = cap-row-y(rows.badge) }
  }

  // ================================================================== drawing

  // debug grid under everything
  if o.debug {
    let dbg = rgb("#73000A").transparentize(65%)
    let dst = (paint: dbg, thickness: 0.3pt)
    let ddash = (paint: dbg, thickness: 0.3pt, dash: (1.5pt, 1.5pt))
    let x0 = xs.first() - 0.5
    let x1 = xs.last() + 0.5
    draw.line(P((x0, 0)), P((x1, 0)), stroke: ddash)
    for c in cols {
      if c.kind != "layer" { continue }
      for y in c.slots.ys {
        draw.circle(P((c.x, y)), radius: 0.035, stroke: dst, fill: none)
      }
    }
    for y in (label-y, sub-y, act-y, badge-y) {
      if y != none { draw.line(P((x0, y)), P((x1, y)), stroke: ddash) }
    }
  }

  // adjacent-pair edges
  for e in edges {
    let ca = cols.at(e.a)
    let cb = cols.at(e.b)
    let w = medges.weight-of(o.weights, o.seed, e.l, e.i, e.j)
    let overrides = ()
    let gk = str(e.l)
    if gk in gap-override { overrides.push((gap-override.at(gk).ov, gap-override.at(gk).where)) }
    let k = edge-key(e.l, e.i, e.j)
    if k in adj-override { overrides.push((adj-override.at(k).ov, adj-override.at(k).where)) }
    if o.edge-style != none {
      let sd = (o.edge-style)(e.l, e.i, e.j)
      if sd != none {
        if type(sd) != dictionary {
          panic("vinnt: `edge-style` must return a dict (paint, thickness, dash, opacity) or none; got " + repr(sd) + ".")
        }
        overrides.push((sd, "from `edge-style` on the figure"))
      }
    }
    let st = medges.styled-edge(e, w, wrange, o, overrides)
    let start-trim = if ca.pos == 1 and o.input-style == "arrows" { 0 } else { ca.trim }
    let arrow = o.arrows == "all"
    if k in adj-override and adj-override.at(k).arrow { arrow = true }
    if gk in gap-override and gap-override.at(gk).arrow { arrow = true }
    draw.line(
      P((ca.x + start-trim, e.y1)), P((cb.x - cb.trim, e.y2)),
      stroke: st.stroke,
      mark: if arrow { smark(st.paint) } else { none },
    )
  }

  // bias edges, styled as normal edges
  {
    let bpaint = o.edge-stroke.at("paint", default: black)
    let bst = (
      paint: bpaint.transparentize(100% - o.edge-opacity),
      thickness: o.edge-stroke.at("thickness", default: 0.4pt),
      dash: o.edge-stroke.at("dash", default: none),
    )
    for be in bias-edges { draw.line(P(be.p1), P(be.p2), stroke: bst) }
  }

  // gap ellipsis columns: dots and faded stubs
  for (ci, c) in cols.enumerate() {
    if c.kind != "gap" { continue }
    let dotr = 0.13 * o.node-size
    for dx in (-0.14, 0, 0.14) {
      draw.circle(P((c.x + dx, 0)), radius: dotr, fill: mlp-grey, stroke: none)
    }
    let stub-st = (
      paint: o.edge-stroke.at("paint", default: black).transparentize(100% - o.edge-opacity * 0.45),
      thickness: o.edge-stroke.at("thickness", default: 0.4pt),
    )
    if ci > 0 and cols.at(ci - 1).kind == "layer" {
      let pv = cols.at(ci - 1)
      for a in pv.active {
        let s = (pv.x + pv.trim, a.y)
        let t = (c.x - 0.24, a.y * 0.25)
        draw.line(P(s), P((s.at(0) + (t.at(0) - s.at(0)) * 0.6, s.at(1) + (t.at(1) - s.at(1)) * 0.6)), stroke: stub-st)
      }
    }
    if ci + 1 < cols.len() and cols.at(ci + 1).kind == "layer" {
      let nx = cols.at(ci + 1)
      for a in nx.active {
        let s = (nx.x - nx.trim, a.y)
        let t = (c.x + 0.24, a.y * 0.25)
        draw.line(P(s), P((s.at(0) + (t.at(0) - s.at(0)) * 0.6, s.at(1) + (t.at(1) - s.at(1)) * 0.6)), stroke: stub-st)
      }
    }
  }

  // extra edges: loops, skip arcs, straights, sum nodes
  for x in extras {
    if x.kind == "straight" {
      medges.straight-extra(P, x.p1, x.p2, x.stroke, x.paint, x.arrow)
    } else if x.kind == "arc" {
      medges.skip-arc(P, x.p1, x.p2, x.hy, x.stroke, x.paint, x.arrow)
      if x.sum != none {
        medges.sum-node(P, x.sum.pos, x.sum.r, x.paint)
        draw.line(
          P((x.sum.pos.at(0), x.sum.pos.at(1) - x.sum.side * x.sum.r)), P(x.sum.into),
          stroke: (paint: x.paint, thickness: x.stroke.thickness),
          mark: smark(x.paint),
        )
      }
    } else if x.kind == "loop" {
      medges.loop-arc(P, x.x, x.ytop, x.trim, x.stroke, x.paint, x.arrow)
    }
    if x.label != none {
      draw.content(P(x.label-at), text(size: mlp-fonts.edge-label, fill: x.paint)[#x.label])
    }
  }

  // nodes
  for c in cols {
    if c.kind != "layer" { continue }
    let arrows-input = c.pos == 1 and o.input-style == "arrows"
    // vertical ellipsis of a collapsed column
    if c.slots.collapsed {
      let ey = c.slots.ys.at(c.slots.mid)
      for dy in (0.12, 0, -0.12) {
        draw.circle(P((c.x, ey + dy)), radius: 0.13 * c.nsize, fill: black, stroke: none)
      }
    }
    // node-label resolution for this column
    let nl = if c.has-own-node-label { c.node-label } else { o.node-label }
    let nl-of(i) = {
      if nl == none { none } else if nl == auto { auto-node-label(c.role, c.pos, n-hidden, i) } else if c.has-own-node-label { (nl)(i) } else { (nl)(c.pos, i) }
    }
    for a in c.active {
      let fill = c.fill
      let stroke = c.stroke
      let size = c.nsize
      let shape = c.shape
      if c.values != none {
        let v = float(c.values.at(a.neuron - 1))
        fill = color.mix((white, (1 - v) * 100%), (c.fill, v * 100%), space: rgb)
      }
      if c.node-style != none {
        let ov = (c.node-style)(a.neuron)
        if ov != none {
          if type(ov) != dictionary {
            panic("vinnt: `node-style` on layer " + str(c.pos) + " must return a dict (fill, stroke, size, shape) or none; got " + repr(ov) + ".")
          }
          for (k, v) in ov {
            if k == "fill" { fill = v } else if k == "stroke" { stroke = v; if type(stroke) == color { stroke = (paint: stroke, thickness: 0.8pt) } } else if k == "size" { size = v } else if k == "shape" { shape = v } else {
              panic("vinnt: unknown node-style key \"" + k + "\" on layer " + str(c.pos) + ". Options accepted here: fill, shape, size, stroke.")
            }
          }
        }
      }
      let r = if shape == "split" { size * 1.35 } else { size }
      if a.dimmed {
        fill = fill.transparentize(55%)
        if type(stroke) == dictionary and "paint" in stroke {
          stroke.paint = stroke.paint.transparentize(55%)
        }
      }
      let pos = (c.x, a.y)
      if not arrows-input {
        if shape == "square" {
          draw.rect(P((c.x - size, a.y - size)), P((c.x + size, a.y + size)), fill: fill, stroke: stroke)
        } else {
          draw.circle(P(pos), radius: r, fill: fill, stroke: stroke)
        }
        if shape == "split" {
          let spaint = if type(stroke) == dictionary { stroke.at("paint", default: black) } else { black }
          draw.line(P((c.x, a.y - r)), P((c.x, a.y + r)), stroke: (paint: spaint, thickness: 0.5pt))
          draw.content(P((c.x - r * 0.45, a.y)), text(size: calc.max(6.5pt, (r * 26) * 1pt))[$Sigma$])
          if type(c.act) == str and glyph-names.contains(c.act) {
            mglyphs.glyph(c.act, P((c.x + r * 0.48, a.y)), r * 0.78, spaint, thickness: 0.6pt)
          } else {
            draw.content(P((c.x + r * 0.48, a.y)), text(size: calc.max(6.5pt, (r * 24) * 1pt))[$f$])
          }
        }
        // in-node activation glyph
        if o.activation-style == "glyph" and c.act != none and not c.is-bracket and shape != "split" and not a.dropped {
          let gpaint = if type(stroke) == dictionary { stroke.at("paint", default: black) } else { black }
          mglyphs.glyph(c.act, P(pos), 1.2 * size, gpaint, thickness: 0.6pt)
        }
        // value text
        if c.values != none and c.show-value-text {
          let v = float(c.values.at(a.neuron - 1))
          let tcol = if is-dark(color.mix((white, (1 - v) * 100%), (c.fill, v * 100%), space: rgb)) { white } else { black }
          draw.content(P(pos), text(size: calc.max(6.5pt, (size * 30) * 1pt), fill: tcol)[#fmt2(v)])
        }
        // dropout X
        if a.dropped {
          let d = r * 0.78
          let xst = (paint: if type(stroke) == dictionary { stroke.at("paint", default: black) } else { black }, thickness: 0.8pt)
          draw.line(P((c.x - d, a.y - d)), P((c.x + d, a.y + d)), stroke: xst)
          draw.line(P((c.x - d, a.y + d)), P((c.x + d, a.y - d)), stroke: xst)
        }
        // highlight ring
        if a.highlighted {
          draw.circle(P(pos), radius: r + 0.06, fill: none, stroke: (paint: pal.accent, thickness: 1pt))
        }
        // node labels
        let lab = nl-of(a.neuron)
        if lab != none and not (c.show-value-text and c.node-label-pos == "inside") {
          if c.node-label-pos == "inside" {
            if o.activation-style != "glyph" and shape != "split" {
              draw.content(P(pos), text(size: calc.max(6.5pt, (size * 27) * 1pt))[#lab])
            }
          } else {
            let dxx = if c.node-label-pos == "left" { -(c.trim + 0.09) } else { c.trim + 0.09 }
            let anch = if up { if c.node-label-pos == "left" { "north" } else { "south" } } else { if c.node-label-pos == "left" { "east" } else { "west" } }
            draw.content(P((c.x + dxx, a.y)), anchor: anch, text(size: 7pt)[#lab])
          }
        }
      } else {
        // input-style "arrows": labelled stub arrows replace the layer-1 nodes
        let apaint = o.edge-stroke.at("paint", default: black)
        draw.line(P((c.x - 0.62, a.y)), P((c.x - 0.07, a.y)),
          stroke: (paint: apaint, thickness: 0.55pt), mark: smark(apaint))
        let lab = nl-of(a.neuron)
        if lab == none { lab = auto-node-label("input", 1, n-hidden, a.neuron) }
        let anch = if up { "north" } else { "east" }
        draw.content(P((c.x - 0.7, a.y)), anchor: anch, text(size: mlp-fonts.stub)[#lab])
      }
    }
  }

  // bias nodes over their edges
  for b in bias-nodes {
    draw.circle(P((b.x, b.y)), radius: b.nsize, fill: pal.bias, stroke: o.node-stroke)
    draw.content(P((b.x, b.y)), text(size: calc.max(6.5pt, (b.nsize * 34) * 1pt))[#o.bias-label])
  }

  // activation display: captions, blocks, brackets
  for c in cols {
    if c.kind != "layer" or c.act == none { continue }
    if act-caption {
      let at = if up { P((c.x, cap-left.act)) } else { P((c.x, act-y)) }
      let anch = if up { "east" } else { "center" }
      draw.content(at, anchor: anch, text(size: mlp-fonts.activation, fill: mlp-caption-ink)[#c.act])
    } else if c.is-bracket {
      // softmax / argmax: a right-side bracket spanning the layer
      let bx = c.x + c.trim + 0.16
      let yt = c.slots.top + c.nsize * 0.7
      draw.line(P((bx - 0.07, yt)), P((bx, yt)), P((bx, -yt)), P((bx - 0.07, -yt)),
        stroke: (paint: mlp-grey, thickness: 0.7pt))
      let anch = if up { "south" } else { "west" }
      draw.content(P((bx + 0.1, 0)), anchor: anch, text(size: mlp-fonts.activation, fill: mlp-caption-ink)[#c.act])
    } else if act-block {
      let by = if up { cap-left.act + block-half } else { act-y }
      let at = if up { (c.x, by) } else { (c.x, by) }
      let h = c.nsize
      let gpaint = if type(c.stroke) == dictionary { c.stroke.at("paint", default: black) } else { black }
      draw.rect(P((c.x - h, by - h)), P((c.x + h, by + h)),
        fill: white, stroke: (paint: mlp-grey, thickness: 0.5pt))
      mglyphs.glyph(c.act, P((c.x, by)), 2 * h * 0.72, gpaint, thickness: 0.6pt)
    }
  }

  // io stubs
  {
    let show-in = (o.io-stubs == true or o.io-stubs == "in") and o.input-style != "arrows"
    let show-out = o.io-stubs == true or o.io-stubs == "out"
    let spaint = o.edge-stroke.at("paint", default: black)
    let sst = (paint: spaint, thickness: 0.55pt)
    let stub-label(side, i) = {
      if o.stub-labels == none { none } else if o.stub-labels == auto {
        if side == "in" { $x_#i$ } else { $hat(y)_#i$ }
      } else { (o.stub-labels)(side, i) }
    }
    if show-in and layer-cols.len() > 0 {
      let c = layer-cols.first()
      for a in c.active {
        draw.line(P((c.x - c.trim - 0.62, a.y)), P((c.x - c.trim - 0.06, a.y)), stroke: sst, mark: smark(spaint))
        let lab = stub-label("in", a.neuron)
        if lab != none {
          let anch = if up { "north" } else { "east" }
          draw.content(P((c.x - c.trim - 0.7, a.y)), anchor: anch, text(size: mlp-fonts.stub)[#lab])
        }
      }
    }
    if show-out and layer-cols.len() > 0 {
      let c = layer-cols.last()
      for a in c.active {
        draw.line(P((c.x + c.trim + 0.06, a.y)), P((c.x + c.trim + 0.62, a.y)), stroke: sst, mark: smark(spaint))
        let lab = stub-label("out", a.neuron)
        if lab != none {
          let anch = if up { "south" } else { "west" }
          draw.content(P((c.x + c.trim + 0.7, a.y)), anchor: anch, text(size: mlp-fonts.stub)[#lab])
        }
      }
    }
  }

  // count badges
  if has-badge {
    for c in cols {
      if not badge-for(c) { continue }
      if up {
        draw.content(P((c.x, -badge-x)), anchor: "west", text(size: mlp-fonts.badge, fill: mlp-grey)[#str(c.count)])
      } else {
        draw.content(P((c.x, badge-y)), text(size: mlp-fonts.badge, fill: mlp-grey)[#str(c.count)])
      }
    }
  }

  // layer and gap captions with subs
  for c in cols {
    if c.label == none { continue }
    if up {
      let fx = P((c.x, cap-left.label))
      if c.sub == none {
        draw.content(fx, anchor: "east", text(size: mlp-fonts.label)[#c.label])
      } else {
        draw.content((fx.at(0), fx.at(1) + 0.12), anchor: "east", text(size: mlp-fonts.label)[#c.label])
        draw.content((fx.at(0), fx.at(1) - 0.14), anchor: "east", text(size: mlp-fonts.sub, fill: mlp-caption-ink)[#c.sub])
      }
    } else {
      draw.content(P((c.x, label-y)), text(size: mlp-fonts.label)[#c.label])
      if c.sub != none and sub-y != none {
        draw.content(P((c.x, sub-y)), text(size: mlp-fonts.sub, fill: mlp-caption-ink)[#c.sub])
      }
    }
  }

  // matrix labels, centered in each adjacent inter-layer gap
  if o.matrix-labels != false {
    for k in range(cols.len() - 1) {
      let a = cols.at(k)
      let b = cols.at(k + 1)
      if a.kind != "layer" or b.kind != "layer" { continue }
      let l = a.pos
      let lab = if o.matrix-labels == true { $W^((#l))$ } else { (o.matrix-labels)(l) }
      if lab == none { continue }
      let my = (a.slots.top + a.nsize + b.slots.top + b.nsize) / 2 + 0.34
      let anch = if up { "east" } else { "center" }
      draw.content(P(((a.x + b.x) / 2, my)), anchor: anch, text(size: mlp-fonts.matrix-label)[#lab])
    }
  }

  // edge labels: the representative per-edge annotations
  {
    let draw-edge-label(e, lab) = {
      let ca = cols.at(e.a)
      let cb = cols.at(e.b)
      let start-trim = if ca.pos == 1 and o.input-style == "arrows" { 0 } else { ca.trim }
      let p1 = (ca.x + start-trim, e.y1)
      let p2 = (cb.x - cb.trim, e.y2)
      let lab = if lab == auto { let l = e.l; let i = e.i; let j = e.j; $w_(#j #i)^((#l))$ } else { lab }
      draw.content(
        P(((p1.at(0) + p2.at(0)) / 2, (p1.at(1) + p2.at(1)) / 2)),
        frame: "rect", fill: white, stroke: none, padding: 1pt,
        text(size: mlp-fonts.edge-label)[#lab],
      )
    }
    for el in o.edge-labels {
      let e = edges.at(edge-idx.at(edge-key(el.l, el.i, el.j)))
      draw-edge-label(e, el.at("label", default: auto))
    }
    for (k, ov) in adj-override {
      if ov.label != none {
        let e = edges.at(edge-idx.at(k))
        draw-edge-label(e, ov.label)
      }
    }
  }

  // title
  if o.title != none {
    let t = text(size: mlp-fonts.title, weight: "semibold")[#o.title]
    if up {
      let top = xs.last() + (if o.io-stubs == true or o.io-stubs == "out" { 0.95 } else { calc.max(..layer-cols.map(c => c.trim)) + 0.25 })
      // Center over the true horizontal extents: the caption columns extend
      // left (logical +y maps to canvas -x) and the badges right.
      let lx = if cap-left.act != none { cap-left.act } else if has-label { cap-left.label } else { ext-above }
      let rx = if has-badge { badge-x } else { ext-below }
      draw.content(((rx - lx) / 2, top + 0.35), anchor: "south", t)
    } else {
      draw.content(((xs.first() + xs.last()) / 2, ext-above + 0.5), anchor: "south", t)
    }
  }
}

// The command: the same figure inside its own CeTZ canvas.
#let draw-mlp(layers, ..opts) = {
  let unit = opts.named().at("unit", default: 1cm)
  canvas(length: unit, mlp-content(layers, ..opts))
}
