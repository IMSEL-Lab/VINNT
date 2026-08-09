// draw-network: validate, walk the trunk, then route connections and finish
// with groups and the legend. The per-type block drawing lives in layers.typ,
// primitives in primitives.typ, and the visual constants in theme.typ.

#import "@preview/cetz:0.5.2": canvas, draw
#import "validate.typ": check-layers, check-connections, check-groups, collect-names
#import "theme.typ" as theme
#import "geom.typ" as geom
#import "geom.typ": min-clear-offset, depth-shear
#import "primitives.typ" as primitives
#import "routing.typ" as routing
#import "legend.typ" as vlegend
#import "layers.typ" as vlayers

#let draw-network(
  layers,
  connections: (),
  groups: (),
  palette: "warm",
  show-legend: false,
  legend-title: "Layers",
  main-legend: none,
  scale: 100%,
  stroke-thickness: 1,
  depth-multiplier: 0.3,
  lane-unit: 0.75,
  shape-scale: (spatial: (1.2, -3.2), channels: (0.075, 0.0)),
  auto-gap: 0.55,
  show-relu: false,
) = {

// Reject unknown keys and dangling names before drawing anything.
check-layers(layers, "layer")
let declared-names = collect-names(layers)
check-connections(connections, declared-names)
check-groups(groups, declared-names)

let colors = theme.palette-colors(palette)
let scale-factor = scale / 100%

// Everything the drawing helpers need from the figure-wide settings, passed
// down as one value.
let ctx = (
  colors: colors,
  strokes: theme.make-strokes(stroke-thickness),
  font-sizes: theme.font-sizes,
  opacity-values: theme.opacity-values,
  darken-amounts: theme.darken-amounts,
  arrow-config: theme.arrow-config,
  depth-angle-deg: theme.depth-angle-deg,
  depth-multiplier: depth-multiplier,
  scale-factor: scale-factor,
  show-relu: show-relu,
)
let strokes = ctx.strokes
let font-sizes = ctx.font-sizes
let arrow-config = ctx.arrow-config

canvas(length: 1cm * scale-factor, {
  import draw: *

  let scaled-font = (size) => size * scale-factor
  let get-depth-offsets(d) = geom.get-depth-offsets(ctx, d)
  let get-y-offset-for-center-on-axis(h, d, axis-y) = geom.get-y-offset-for-center-on-axis(ctx, h, d, axis-y)
  let get-perspective-center-y = geom.get-perspective-center-y
  let dynamic-color-strokes(fill) = theme.dynamic-color-strokes(strokes, fill)
  let draw-arrow-icon(..a) = primitives.draw-arrow-icon(ctx, ..a)
  let draw-segment-with-arrow(..a) = primitives.draw-segment-with-arrow(ctx, ..a)
  let draw-connection-path(..a) = routing.draw-connection-path(ctx, ..a)

  let arrow-axis-y = arrow-config.axis-y

  // Walk a run of layers, returning its drawing plus the layout facts the caller needs.
  let walk-trunk(layers, start-x, arrow-axis-y) = {
    let x = start-x
    let first-west = none
    let branch-extents = ()
    let max-half-extent = 0
    let prev-layer-depth = 0
    let connection-targets = connections.map(c => c.at("to", default: none)).filter(n => n != none)
    let prev-center-y = arrow-axis-y
    let prev-x = 0
    let prev-depth-offset = 0
    let prev-pool-width = 0
    let used-layer-types = (:)
    let layer-positions = (:)
    let arrow-segments = (:)
    let legend-entries = ()

    let body = {
      for (i, l) in layers.enumerate() {
        // A parallel section: each branch is a layer list walked at its own height.
        if l.type == "branch" {
          let subs = l.at("branches", default: ())
          let spread = l.at("spread", default: 6)
          let lead = l.at("lead", default: 2.0)
          let rejoin-lead = l.at("rejoin-lead", default: lead)
          let open-mode = l.at("open", default: none)
          if open-mode not in (none, "start", "end") {
            panic("branch open must be \"start\" or \"end\"; got " + repr(open-mode))
          }
          if i == 0 { open-mode = "start" }
          let n = subs.len()
          // "depth" stacks branches along the projection axis, "vertical" straight up.
          let depth-spread = l.at("spread-mode", default: "vertical") == "depth"
          let turn-out = calc.max(x + lead / 2, prev-x + prev-depth-offset + 0.15)
          let branch-from-x = prev-x + prev-pool-width + prev-depth-offset / 2
          let branch-from-y = prev-center-y
          let branch-start = if open-mode == "start" { x } else { turn-out + lead / 2 }
          let ends = ()
          let branch-members = ()

          let spine-cross = turn-out + spread / 2
          let junction(px, py) = circle((px, py), radius: 0.09, fill: colors.connection, stroke: none)
          if depth-spread and n > 1 and open-mode != "start" {
            draw-connection-path((((branch-from-x, branch-from-y), (spine-cross, branch-from-y)),), opacity: 0.7)
            draw-connection-path((((spine-cross, branch-from-y), (turn-out + spread, branch-from-y + spread / 2)),), opacity: 0.7)
            draw-connection-path((((spine-cross, branch-from-y), (turn-out, branch-from-y - spread / 2)),), opacity: 0.7)
            junction(spine-cross, branch-from-y)
          }

          for (bi, sub) in subs.enumerate() {
            let k = if n <= 1 { 0 } else { spread * ((n - 1) / 2 - bi) / (n - 1) }
            let dx = if depth-spread and n > 1 { k + spread / 2 } else { 0 }
            let dy = k
            let r = walk-trunk(sub, branch-start + dx, arrow-axis-y + dy)

            for (k, v) in r.positions { layer-positions.insert(k, v) }
            for (k, v) in r.segments { arrow-segments.insert(k, v) }
            branch-members += r.positions.keys()
            branch-extents += r.branch-extents
            for e in r.legend {
              if not legend-entries.any(q => q.key == e.key) { legend-entries.push(e) }
            }
            max-half-extent = calc.max(max-half-extent, r.max-half-extent + calc.abs(dy))

            let (in-x, in-y) = if r.first-west == none {
              (branch-start + dx, arrow-axis-y + dy)
            } else { r.first-west }
            let turn = turn-out
            if open-mode == "start" {
            } else if depth-spread {
              let from = if n <= 1 { (branch-from-x, branch-from-y) } else { (turn + dx, branch-from-y + dy) }
              draw-connection-path(((from, (in-x, in-y)),), opacity: 0.7)
              if bi != 0 and bi != n - 1 and calc.abs(dy) > 0.001 {
                junction(turn + dx, branch-from-y + dy)
              }
            } else if calc.abs(in-y - branch-from-y) < 0.001 {
              let from-x = if n <= 1 { branch-from-x } else { turn }
              draw-connection-path((((from-x, branch-from-y), (in-x, in-y)),), opacity: 0.7)
            } else {
              draw-connection-path((
                ((branch-from-x, branch-from-y), (turn, branch-from-y)),
                ((turn, branch-from-y), (turn, in-y)),
                ((turn, in-y), (in-x, in-y)),
              ), opacity: 0.7)
              junction(turn, branch-from-y)
            }
            r.body

            let first-name = if sub.len() > 0 { sub.first().at("name", default: none) } else { none }
            if open-mode != "start" and first-name != none and first-name + "-in" not in arrow-segments {
              let tooth-start-x = if depth-spread {
                if n <= 1 { branch-from-x } else { turn + dx }
              } else {
                if n <= 1 { branch-from-x } else { turn }
              }
              let mid = ((tooth-start-x + in-x) / 2, in-y)
              arrow-segments.insert(first-name + "-in", (end: (in-x, in-y), mid: mid, x: mid.at(0), y: mid.at(1)))
            }
            let last-name = if sub.len() > 0 { sub.last().at("name", default: none) } else { none }
            ends.push((x: r.prev-x + r.prev-depth-offset / 2, shear: r.prev-depth-offset / 2, y: r.prev-center-y, dy: dy, dx: dx, bi: bi, last-name: last-name, end: r.end-x))
          }

          let rturn0 = ends.map(e => e.x + e.shear - e.at("dx", default: 0)).fold(branch-start, calc.max) + rejoin-lead / 2
          let rcross = rturn0 + spread / 2
          let resume = if depth-spread {
            rcross + rejoin-lead / 2
          } else {
            ends.map(e => e.x + e.shear).fold(x, calc.max) + rejoin-lead
          }
          if open-mode == "end" {
          } else if depth-spread {
            for e in ends {
              let out-x = if n <= 1 { resume } else { rturn0 + e.dx }
              if n <= 1 {
                draw-connection-path((((e.x, e.y), (resume, arrow-axis-y)),), opacity: 0.7)
              } else {
                draw-connection-path((((e.x, e.y), (out-x, e.y)),), opacity: 0.7)
              }
              if e.last-name != none and e.last-name + "-out" not in arrow-segments {
                let mid = ((e.x + out-x) / 2, e.y)
                arrow-segments.insert(e.last-name + "-out", (start: (e.x, e.y), mid: mid, x: mid.at(0), y: mid.at(1)))
              }
              if e.bi != 0 and e.bi != n - 1 and calc.abs(e.dy) > 0.001 {
                junction(out-x, e.y)
              }
            }
            if n > 1 {
              draw-connection-path((((rturn0 + spread, arrow-axis-y + spread / 2), (rcross, arrow-axis-y)),), opacity: 0.7)
              draw-connection-path((((rturn0, arrow-axis-y - spread / 2), (rcross, arrow-axis-y)),), opacity: 0.7)
              junction(rcross, arrow-axis-y)
            }
          } else {
            for e in ends {
              let turn = resume - rejoin-lead / 2
              let out-x = if n <= 1 { resume } else { turn }
              if e.last-name != none and e.last-name + "-out" not in arrow-segments {
                let mid = ((e.x + out-x) / 2, e.y)
                arrow-segments.insert(e.last-name + "-out", (start: (e.x, e.y), mid: mid, x: mid.at(0), y: mid.at(1)))
              }
              if n <= 1 {
                draw-connection-path((((e.x, e.y), (resume, arrow-axis-y)),), opacity: 0.7)
              } else if e.dy == 0 {
                draw-connection-path((((e.x, e.y), (turn, arrow-axis-y)),), opacity: 0.7)
              } else {
                draw-connection-path((
                  ((e.x, e.y), (turn, e.y)),
                  ((turn, e.y), (turn, arrow-axis-y)),
                ), opacity: 0.7)
                junction(turn, arrow-axis-y)
              }
            }
          }

          let dot-x = if n <= 1 { resume } else if depth-spread { rcross } else { resume - rejoin-lead / 2 }
          x = if depth-spread and n > 1 { rturn0 + spread } else { dot-x }
          prev-x = if open-mode == "end" { x } else { dot-x }
          branch-extents.push((x0: turn-out, x1: x, members: branch-members))
          prev-depth-offset = 0
          prev-center-y = arrow-axis-y
          prev-pool-width = 0
          prev-layer-depth = 0
          continue
        }

        used-layer-types.insert(l.type, true)

        if first-west == none {
          let (f-ox, f-oy) = get-depth-offsets(l.at("depth", default: 5))
          let f-h = l.at("height", default: 5)
          let f-y = get-y-offset-for-center-on-axis(f-h, l.at("depth", default: 5), arrow-axis-y)
          first-west = (x + f-ox / 2, get-perspective-center-y(f-y, f-h, f-oy))
        }

        // A stated tensor shape supplies geometry defaults; explicit fields still win.
        let shp = l.at("shape", default: none)
        if shp != none {
          if shp.len() != 3 {
            panic("shape must be (channels, height, width); got " + repr(shp))
          }
          let (shp-c, shp-h, shp-w) = shp
          let from-spatial(v) = calc.max(
            shape-scale.spatial.at(0) * calc.log(calc.max(v, 1), base: 2) + shape-scale.spatial.at(1), 0.4)
          let from-channels(v) = calc.max(
            shape-scale.channels.at(0) * calc.log(calc.max(v, 1), base: 2) + shape-scale.channels.at(1), 0.15)

          if not l.keys().contains("height") { l.insert("height", from-spatial(shp-h)) }
          if not l.keys().contains("depth") { l.insert("depth", from-spatial(shp-w)) }
          if not l.keys().contains("widths") and not l.keys().contains("width") {
            if l.type == "conv" or l.type == "convres" {
              l.insert("widths", (from-channels(shp-c),))
            } else if l.type == "custom" {
              l.insert("width", from-channels(shp-c))
            }
          }
        }

        if not l.keys().contains("height") {
          let default-h = if l.type == "pool" or l.type == "unpool" { 4 } else if l.type == "concat" or l.type == "fc" or l.type == "softmax" or l.type == "output" { 3 } else if l.type == "gap" { 1.5 } else if l.type == "convsoftmax" { 4 } else { 5 }
          l.insert("height", default-h)
        }
        if not l.keys().contains("depth") {
          let default-d = if l.type == "pool" or l.type == "unpool" { 4 } else if l.type == "concat" { 3 } else if l.type == "gap" { 1.5 } else if l.type == "fc" or l.type == "softmax" or l.type == "output" { 0.4 } else if l.type == "convsoftmax" { 4 } else { 5 }
          l.insert("depth", default-d)
        }

        let (_, l-oy) = get-depth-offsets(l.depth)
        max-half-extent = calc.max(max-half-extent, l.height / 2 + l-oy / 2)

        // `offset: auto`: cover the previous layer's lean, and widen it if a route lands here.
        let auto-offset = {
          let base = depth-shear(prev-layer-depth, depth-multiplier: depth-multiplier) + auto-gap
          if l.at("name", default: none) in connection-targets {
            calc.max(base, min-clear-offset(prev-layer-depth, depth-multiplier: depth-multiplier))
          } else {
            base
          }
        }
        let gap = if i == 0 {
          0
        } else if l.type == "pool" or l.type == "unpool" {
          0
        } else {
          let stated = l.at("offset", default: auto)
          if stated == auto { auto-offset } else { stated }
        }

        x += gap
        prev-layer-depth = l.depth

        if i > 0 {
          let prev-layer = layers.at(i - 1)
          let prev-show-connection = prev-layer.at("show-connection", default: if prev-layer.type == "input" { false } else { true })
          if prev-show-connection {
            let start-x = prev-x + prev-pool-width + prev-depth-offset / 2
            let start-y = prev-center-y

            let curr-h = l.at("height")
            let curr-d = l.at("depth")
            let (curr-ox, curr-oy) = get-depth-offsets(curr-d)
            let curr-depth-offset = curr-ox
            let curr-y-offset = get-y-offset-for-center-on-axis(curr-h, curr-d, arrow-axis-y)
            let end-y = get-perspective-center-y(curr-y-offset, curr-h, curr-oy)

            let end-x = if l.type == "sum" {
              let radius = l.at("radius", default: 0.4)
              x + prev-depth-offset / 2
            } else {
              let is-curr-pool-or-unpool = l.type == "pool" or l.type == "unpool"
              let stated-offset = { let o = l.at("offset", default: none); if o == auto { auto-offset } else { o } }
              let curr-offset = if is-curr-pool-or-unpool { stated-offset } else { none }
              let curr-layer-x = if curr-offset != none { x + curr-offset } else if is-curr-pool-or-unpool { x + prev-depth-offset / 2 - curr-ox / 2 } else { x }
              curr-layer-x + curr-depth-offset / 2
            }

            let prev-name = prev-layer.at("name", default: none)
            let curr-name = l.at("name", default: none)

            let mid-arrow-x = (start-x + end-x) / 2
            let mid-arrow-y = (start-y + end-y) / 2

            if prev-name != none {
              arrow-segments.insert(prev-name + "-out", (
                start: (start-x, start-y),
                mid: (mid-arrow-x, mid-arrow-y),
                x: mid-arrow-x,
                y: mid-arrow-y
              ))
            }
            if curr-name != none {
              arrow-segments.insert(curr-name + "-in", (
                end: (end-x, end-y),
                mid: (mid-arrow-x, mid-arrow-y),
                x: mid-arrow-x,
                y: mid-arrow-y
              ))
            }

            let is-pool-or-unpool = l.type == "pool" or l.type == "unpool"
            let has-offset = l.at("offset", default: none) != none
            if not is-pool-or-unpool or has-offset {
              draw-segment-with-arrow(start-x, start-y, end-x, end-y, opacity: 0.7)

              let conn-label = prev-layer.at("connection-label", default: none)
              if conn-label != none {
                content((mid-arrow-x, mid-arrow-y + 0.28),
                  [#text(size: scaled-font(font-sizes.layer-label), conn-label)])
              }
            }
          }
        }

        let repeat-x0 = x

        // Everything below the walk is per-type: dispatch to layers.typ and
        // fold the returned cursor and collections back into the walk state.
        let st = (
          x: x, arrow-axis-y: arrow-axis-y,
          prev-x: prev-x, prev-center-y: prev-center-y,
          prev-depth-offset: prev-depth-offset, prev-pool-width: prev-pool-width,
          auto-offset: auto-offset,
        )
        let r = if l.type == "custom" {
          vlayers.draw-custom-layer(ctx, l, st)
        } else if l.type == "input" {
          vlayers.draw-input-layer(ctx, l, st)
        } else if l.type == "conv" or l.type == "convres" {
          vlayers.draw-conv-layer(ctx, l, st)
        } else if l.type == "pool" {
          vlayers.draw-pool-layer(ctx, l, st)
        } else if l.type == "unpool" {
          vlayers.draw-unpool-layer(ctx, l, st)
        } else if l.type == "deconv" {
          vlayers.draw-box-layer(ctx, l, st, (use-width: true, width: 0.3, fill-key: "deconv", opacity: 0.7))
        } else if l.type == "concat" {
          vlayers.draw-box-layer(ctx, l, st, (use-width: true, width: 0.15, fill-key: "concat", opacity: 0.7))
        } else if l.type == "gap" {
          vlayers.draw-box-layer(ctx, l, st, (use-width: false, width: 0.3, fill-key: "gap", opacity: 0.7))
        } else if l.type == "fc" {
          vlayers.draw-box-layer(ctx, l, st, (use-width: false, width: 0.2, fill-key: "fc", opacity: 0.7))
        } else if l.type == "sum" {
          vlayers.draw-sum-layer(ctx, l, st)
        } else if l.type == "convsoftmax" {
          vlayers.draw-convsoftmax-layer(ctx, l, st)
        } else if l.type == "softmax" or l.type == "output" {
          vlayers.draw-softmax-layer(ctx, l, st)
        }

        r.body
        x = r.x
        prev-x = r.prev-x
        prev-center-y = r.prev-center-y
        prev-depth-offset = r.prev-depth-offset
        prev-pool-width = r.prev-pool-width
        // A pool departs the previous layer's outgoing arrows after itself.
        if r.prev-pool-offset != none and i > 0 {
          let prev-layer = layers.at(i - 1)
          let prev-name = prev-layer.at("name", default: none)
          if prev-name != none and prev-name in layer-positions {
            let prev-pos = layer-positions.at(prev-name)
            layer-positions.insert(prev-name, (
              ..prev-pos,
              pool-offset: r.prev-pool-offset
            ))
          }
        }
        for (k, v) in r.positions { layer-positions.insert(k, v) }
        for e in r.legend {
          if not legend-entries.any(q => q.key == e.key) { legend-entries.push(e) }
        }

        // A repeated block, drawn as a bracket and count over the top face.
        let repeat-n = if l.type in ("pool", "unpool", "sum") { 1 } else { l.at("repeat", default: 1) }
        if repeat-n > 1 {
          let rw = x - repeat-x0
          if rw > 0 {
            let rh = l.at("height", default: 5)
            let rd = l.at("depth", default: 5)
            let (rox, roy) = get-depth-offsets(rd)
            let ry = get-y-offset-for-center-on-axis(rh, rd, arrow-axis-y)
            let bx0 = repeat-x0 + rox
            let bx1 = repeat-x0 + rw + rox
            let by = ry + rh + roy + 0.26
            let rule = (paint: colors.connection, thickness: strokes.connection.thickness, cap: "butt", join: "miter")
            line((bx0, by - 0.16), (bx0, by), (bx1, by), (bx1, by - 0.16), stroke: rule)
            content((bx0, by + 0.12), anchor: "base-west",
              [#text(size: scaled-font(font-sizes.channel-number), weight: "bold", "x" + str(repeat-n))])
          }
        }
      }
    }

    (
      body: body,
      positions: layer-positions,
      segments: arrow-segments,
      legend: legend-entries,
      max-half-extent: max-half-extent,
      prev-x: prev-x,
      prev-depth-offset: prev-depth-offset,
      prev-center-y: prev-center-y,
      first-west: first-west,
      branch-extents: branch-extents,
      end-x: x,
    )
  }

  let trunk = walk-trunk(layers, 0, arrow-axis-y)
  trunk.body
  let layer-positions = trunk.positions
  let arrow-segments = trunk.segments
  let legend-entries = trunk.legend
  let max-half-extent = trunk.max-half-extent
  let prev-x = trunk.prev-x
  let prev-depth-offset = trunk.prev-depth-offset
  let branch-extents = trunk.branch-extents

  for (i, l) in layers.enumerate() {
    let curr-name = l.at("name", default: none)
    if curr-name != none and curr-name in layer-positions {
      let prev-name = none
      for j in range(i - 1, -1, step: -1) {
        let candidate-name = layers.at(j).at("name", default: none)
        if candidate-name != none and candidate-name in layer-positions {
          prev-name = candidate-name
          break
        }
      }

      if prev-name != none {
        let prev-pos = layer-positions.at(prev-name)
        let curr-pos = layer-positions.at(curr-name)

        let pool-offset = prev-pos.at("pool-offset", default: 0)
        let arrow-start = (prev-pos.anchors.true_east.at(0) + pool-offset, prev-pos.anchors.true_east.at(1))
        let arrow-end = curr-pos.anchors.true_west

        let mid-x = (arrow-start.at(0) + arrow-end.at(0)) / 2
        let mid-y = arrow-start.at(1)

        arrow-segments.insert(prev-name + "-out", (
          start: arrow-start,
          mid: (mid-x, mid-y),
          x: mid-x,
          y: mid-y
        ))
        arrow-segments.insert(curr-name + "-in", (
          end: arrow-end,
          mid: (mid-x, mid-y),
          x: mid-x,
          y: mid-y
        ))
      }
    }
  }

  // Lane assignment for connections asking for `pos: auto`: height grows with reach.
  let lane-clearance = 0.7
  let collect-index(ls, base) = {
    let m = (:)
    for (i, l) in ls.enumerate() {
      let at = if base == none { i } else { base }
      let n = l.at("name", default: none)
      if n != none { m.insert(n, at) }
      if l.type == "branch" {
        for sub in l.at("branches", default: ()) {
          for (k, v) in collect-index(sub, at) { m.insert(k, v) }
        }
      }
    }
    m
  }
  let layer-index = collect-index(layers, none)
  let auto-lane = (:)
  let entries = ()
  for (i, conn) in connections.enumerate() {
    if conn.at("pos", default: auto) != auto { continue }
    let f = conn.at("from")
    let t = conn.at("to")
    if f not in layer-index or t not in layer-index { continue }
    if f not in layer-positions or t not in layer-positions { continue }
    let a = layer-positions.at(f)
    let b = layer-positions.at(t)
    entries.push((
      i: i,
      reach: calc.abs(layer-index.at(t) - layer-index.at(f)),
      start: calc.min(a.x, b.x),
      end: calc.max(a.x + a.w, b.x + b.w),
    ))
  }
  let auto-side = (:)
  let distinct = entries.map(e => e.reach).dedup().sorted()
  let offset = 0
  for r in distinct {
    let group = entries.filter(e => e.reach == r).sorted(key: e => e.start)
    let lane-ends = ()
    for e in group {
      let placed = false
      for (li, le) in lane-ends.enumerate() {
        if not placed and e.start > le {
          lane-ends.at(li) = e.end
          auto-lane.insert(str(e.i), offset + int(li / 2))
          auto-side.insert(str(e.i), if calc.rem(li, 2) == 0 { "air" } else { "flat" })
          placed = true
        }
      }
      if not placed {
        lane-ends.push(e.end)
        let li = lane-ends.len() - 1
        auto-lane.insert(str(e.i), offset + int(li / 2))
        auto-side.insert(str(e.i), if calc.rem(li, 2) == 0 { "air" } else { "flat" })
      }
    }
    offset += int((lane-ends.len() + 1) / 2)
  }

  // Even spacing along the arrival edge for connections asking for `arrive-offset: auto`.
  let auto-arrive = (:)
  {
    let groups = (:)
    for (i, conn) in connections.enumerate() {
      if conn.at("arrive-offset", default: auto) != auto { continue }
      if not conn.at("touch-layer", default: false) { continue }
      let f = conn.at("from")
      let t = conn.at("to")
      if f not in layer-positions or t not in layer-positions { continue }
      let key = t + "/" + conn.at("mode", default: "air")
      let entry = (i: i, x: layer-positions.at(f).x)
      groups.insert(key, groups.at(key, default: ()) + (entry,))
    }
    for (key, members) in groups {
      let t = key.split("/").at(0)
      let mode = key.split("/").at(1)
      let tp = layer-positions.at(t)
      let edge = if mode == "depth" { tp.h } else {
        calc.sqrt(tp.ox * tp.ox + tp.oy * tp.oy)
      }
      let ordered = members.sorted(key: m => m.x)
      let k = ordered.len()
      for (j, m) in ordered.enumerate() {
        auto-arrive.insert(str(m.i), edge * ((j + 1) / (k + 1) - 0.5))
      }
    }
  }

  // Axis arrowheads a route attaches to, redrawn afterwards so the route does not cut them.
  let anchored-heads = ()
  let lowest-route-y = arrow-axis-y

  if main-legend != none {
    legend-entries.push((
      key: "main-flow", label: main-legend, kind: "line",
      color: colors.connection, bandfill: colors.connection,
      style: (paint: colors.connection, thickness: strokes.connection.thickness, dash: none),
      show-relu: false, opacity: 1.0,
    ))
  }

  for (conn-index, conn) in connections.enumerate() {
    let from-name = conn.at("from")
    let to-name = conn.at("to")
    let conn-type = conn.at("type", default: "skip")
    let conn-mode = conn.at("mode", default: auto-side.at(str(conn-index), default: "air"))
    let conn-pos = conn.at("pos", default: auto)
    if conn-pos == auto {
      let lane = auto-lane.at(str(conn-index), default: 0)
      conn-pos = max-half-extent + conn.at("clearance", default: lane-clearance) + lane * lane-unit
    }
    let conn-label = conn.at("label", default: none)
    let conn-opacity = conn.at("opacity", default: 0.7)
    let touch-layer = conn.at("touch-layer", default: false)
    let conn-style = (
      paint: conn.at("color", default: colors.connection),
      thickness: strokes.connection.thickness * conn.at("thickness", default: 1),
      dash: conn.at("dash", default: none),
    )

    let conn-legend = conn.at("legend", default: none)
    if conn-legend != none {
      let legend-key = "conn-" + str(conn-legend)
      if not legend-entries.any(e => e.key == legend-key) {
        legend-entries.push((
          key: legend-key, label: conn-legend, kind: "line",
          color: conn-style.paint, bandfill: conn-style.paint,
          style: conn-style, show-relu: false, opacity: 1.0,
        ))
      }
    }

    if from-name in layer-positions and to-name in layer-positions {
      let from-pos = layer-positions.at(from-name)
      let to-pos = layer-positions.at(to-name)

      let from-anchor-key = from-name + "-out"
      let to-anchor-key = to-name + "-in"

      let from-has-pool = from-pos.at("pool-offset", default: 0) > 0
      let from-type = from-pos.at("type", default: none)
      let departing-from-layer-with-pool = from-has-pool and from-type != "pool"

      let from-anchor = if departing-from-layer-with-pool {
        let base-x = from-pos.x + from-pos.w
        let base-y = from-pos.y
        let h = from-pos.h
        let ox = from-pos.ox
        let oy = from-pos.oy

        if conn-mode == "air" {
          (base-x + ox/2, base-y + h + oy/2)
        } else if conn-mode == "depth" {
          (base-x, base-y + h/2 + oy/2)
        } else {
          (base-x + ox/2, base-y + oy/2)
        }
      } else if from-anchor-key in arrow-segments {
        anchored-heads.push(from-anchor-key)
        let seg = arrow-segments.at(from-anchor-key)
        (seg.mid.at(0) - arrow-config.triangle-size * 0.2, seg.mid.at(1))
      } else {
        from-pos.anchors.true_east
      }

      let to-type = to-pos.at("type", default: none)
      let arrive-off-raw = conn.at("arrive-offset", default: auto)
      let arrive-off = if arrive-off-raw == auto {
        auto-arrive.at(str(conn-index), default: 0)
      } else { arrive-off-raw }
      let to-anchor = if touch-layer {
        let base-x = to-pos.x
        let base-y = to-pos.y
        let h = to-pos.h
        let ox = to-pos.ox
        let oy = to-pos.oy

        let diag = calc.max(calc.sqrt(ox * ox + oy * oy), 0.0001)
        if conn-mode == "air" {
          (base-x + ox/2 + arrive-off * ox / diag, base-y + h + oy/2 + arrive-off * oy / diag)
        } else if conn-mode == "depth" {
          (base-x, base-y + h/2 + oy/2 + arrive-off)
        } else {
          (base-x + ox/2 + arrive-off * ox / diag, base-y + oy/2 + arrive-off * oy / diag)
        }
      } else if to-type == "sum" {
        let center-x = to-pos.center-x
        let center-y = to-pos.y + to-pos.radius
        let center = (center-x, center-y)
        let radius = to-pos.at("radius", default: 0.4)
        if conn-mode == "flat" {
          (center.at(0), center.at(1) - radius)
        } else if conn-mode == "air" {
          (center.at(0), center.at(1) + radius)
        } else if conn-mode == "depth" {
          let angle = 225 * calc.pi / 180
          (center.at(0) + radius * calc.cos(angle), center.at(1) + radius * calc.sin(angle))
        } else {
          (center.at(0), center.at(1) - radius)
        }
      } else if to-anchor-key in arrow-segments {
        anchored-heads.push(to-anchor-key)
        let seg = arrow-segments.at(to-anchor-key)
        (seg.mid.at(0) - arrow-config.triangle-size * 0.2, seg.mid.at(1))
      } else {
        to-pos.anchors.true_west
      }

      if conn-type == "skip" {
        let conn-layers = conn.at("layers", default: none)

        if conn-mode == "flat" {
          let down-y = from-anchor.at(1) - conn-pos
          lowest-route-y = calc.min(lowest-route-y, down-y)
          let waypoint1 = (from-anchor.at(0), down-y)
          let waypoint2 = (to-anchor.at(0), down-y)

          draw-connection-path(((from-anchor, waypoint1), (waypoint1, waypoint2), (waypoint2, to-anchor)), opacity: conn-opacity, layers: conn-layers, layer-positions-ref: layer-positions, show-relu: show-relu, style: conn-style, tail-behind: touch-layer and conn-mode != "air")

          if conn-label != none {
            content(((waypoint1.at(0) + waypoint2.at(0)) / 2, down-y - 0.3),
              [#text(size: scaled-font(font-sizes.layer-label), conn-label)])
          }
        } else if conn-mode == "depth" {
          let (ox, oy) = get-depth-offsets(conn-pos * 2.5)
          let waypoint1 = (from-anchor.at(0) - ox, from-anchor.at(1) - oy)
          lowest-route-y = calc.min(lowest-route-y, waypoint1.at(1))
          let waypoint2-x = if to-type == "sum" {
            let radius = to-pos.at("radius", default: 0.4)
            let angle = 225 * calc.pi / 180
            to-anchor.at(0) - ox - radius * calc.cos(angle)
          } else {
            to-anchor.at(0) - ox
          }
          let waypoint2 = (waypoint2-x, from-anchor.at(1) - oy)

          draw-connection-path(((from-anchor, waypoint1), (waypoint1, waypoint2), (waypoint2, to-anchor)), opacity: conn-opacity, layers: conn-layers, layer-positions-ref: layer-positions, show-relu: show-relu, style: conn-style, tail-behind: touch-layer and conn-mode != "air")

          if conn-label != none {
            content(((waypoint1.at(0) + waypoint2.at(0)) / 2, waypoint1.at(1) - 0.3),
              [#text(size: scaled-font(font-sizes.layer-label), conn-label)])
          }
        } else if conn-mode == "air" {
          let up-y = arrow-axis-y + conn-pos
          let down-y = from-anchor.at(1) - conn-pos
          let waypoint1 = (from-anchor.at(0), up-y)
          let waypoint2 = (to-anchor.at(0), up-y)

          draw-connection-path(((from-anchor, waypoint1), (waypoint1, waypoint2), (waypoint2, to-anchor)), opacity: conn-opacity, layers: conn-layers, layer-positions-ref: layer-positions, show-relu: show-relu, style: conn-style, tail-behind: touch-layer and conn-mode != "air")

          if conn-label != none {
            content(((waypoint1.at(0) + waypoint2.at(0)) / 2, up-y + 0.28),
              [#text(size: scaled-font(font-sizes.layer-label), conn-label)])
          }
        }
      }
    }
  }

  for key in anchored-heads.dedup() {
    let seg = arrow-segments.at(key)
    let (mx, my) = seg.mid
    draw-arrow-icon(mx - 0.5, my, mx + 0.5, my, opacity: 0.7)
  }

  // Group brackets, drawn square and inset so adjacent groups read as two.
  if groups.len() > 0 {
    let group-tick = 0.22
    let group-inset = 0.12
    for g in groups {
      let f = g.at("from")
      let t = g.at("to")
      if f not in layer-positions or t not in layer-positions { continue }
      let a = layer-positions.at(f)
      let b = layer-positions.at(t)
      let x0 = calc.min(a.x, b.x) + group-inset
      let x1 = calc.max(a.x + a.w + a.ox, b.x + b.w + b.ox) - group-inset
      for be in branch-extents {
        if f in be.members or t in be.members {
          x0 = calc.min(x0, be.x0 + group-inset)
          x1 = calc.max(x1, be.x1 - group-inset)
        }
      }
      let y = calc.min(arrow-axis-y - max-half-extent, lowest-route-y) - g.at("offset", default: 1.15)
      let paint = g.at("color", default: colors.connection)
      line((x0, y + group-tick), (x0, y), (x1, y), (x1, y + group-tick),
        stroke: (paint: paint, thickness: strokes.connection.thickness, cap: "butt", join: "miter"))
      let label = g.at("label", default: none)
      if label != none {
        content(((x0 + x1) / 2, y - 0.34),
          [#text(size: scaled-font(font-sizes.label), weight: "bold", fill: paint, label)])
      }
    }
  }

  if show-legend {
    vlegend.draw-legend(ctx, legend-entries, legend-title, prev-x + prev-depth-offset + 1.0, arrow-axis-y)
  }
})}
