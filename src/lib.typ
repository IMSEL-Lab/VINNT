#import "@preview/cetz:0.5.2": canvas, draw

// Option tables, validation and layer constructors, re-exported.
#import "schema.typ": *

// How far a layer's top and side faces lean right, in canvas units.
#let depth-shear(depth, depth-multiplier: 0.3) = depth * depth-multiplier

// Smallest offset that lets a connection descend between two layers without crossing them.
#let min-clear-offset(depth, depth-multiplier: 0.3) = 2 * depth-shear(depth, depth-multiplier: depth-multiplier)

// Turn an imported model dump into a layer list; `label` picks "leaf", "path", "op", "shape" or none.
#let from-shapes(
  data,
  label: "leaf",
  defaults: (:),
  by-op: (:),
  overrides: (:),
  drop: (),
) = {
  data.at("layers", default: ()).filter(r => r.at("name") not in drop).map(r => {
    let shape = r.at("shape", default: none)
    let text-of(kind) = {
      if kind == none { none }
      else if kind == "op" { r.at("op", default: "") }
      else if kind == "path" { r.at("path", default: r.name) }
      else if kind == "shape" and shape != none and shape.len() == 3 {
        str(shape.at(0)) + "×" + str(shape.at(1))
      } else if kind == "shape" and shape != none { str(shape.at(0)) }
      else if kind == "shape" { none }
      else {
        let parts = r.at("path", default: r.name).split(".")
        let last = parts.last()
        if parts.len() > 1 and last.matches(regex("^[0-9]+$")).len() > 0 {
          parts.at(parts.len() - 2) + "." + last
        } else { last }
      }
    }

    let l = (
      type: r.at("type"),
      name: r.at("name"),
      offset: auto,
    )
    let lbl = text-of(label)
    if lbl != none and lbl != "" { l.insert("label", lbl) }

    if shape != none and shape.len() == 3 {
      l.insert("shape", (shape.at(0), shape.at(1), shape.at(2)))
      l.insert("channels", (shape.at(0), shape.at(1)))
    } else if shape != none and shape.len() == 1 {
      l.insert("channels", (shape.at(0),))
    }

    if l.type in ("conv", "convres", "custom") {
      l.insert("show-relu", r.at("relu", default: false))
    }
    let n = r.at("repeat", default: 1)
    if n > 1 { l.insert("repeat", n) }

    for (k, v) in defaults { l.insert(k, v) }
    for (k, v) in by-op.at(r.at("op", default: ""), default: (:)) { l.insert(k, v) }
    for (k, v) in overrides.at(r.at("name"), default: (:)) { l.insert(k, v) }
    l
  })
}

// Stage brackets from the same dump, one per run of layers sharing a group.
#let groups-from-shapes(data, skip: ("input",), drop: (), ..rest) = {
  let runs = ()
  for r in data.at("layers", default: ()) {
    let g = r.at("group", default: "")
    if g in skip or g == "" or r.at("name") in drop { continue }
    if runs.len() > 0 and runs.last().label == g {
      runs.last().to = r.at("name")
    } else {
      runs.push((label: g, from: r.at("name"), to: r.at("name")))
    }
  }
  runs.map(g => (from: g.from, to: g.to, label: g.label) + rest.named())
}

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

let colors-warm = (
  conv: rgb("#ffe0a1"),
  conv-relu: rgb("#ffa947"),
  pool: rgb("#e04227"),
  unpool: rgb("#2E7D7D"),
  deconv: rgb("#88C1D0"),
  concat: rgb("#B39DDB"),
  softmax: rgb("#6A0066"),
  gap: rgb("#FF69B4"),
  fc: rgb("#B39DDB"),
  fc-relu: rgb("#9575CD"),
  sum: rgb("#FFFFFF"),
  sum-stroke: rgb("#000000"),
  convres: rgb("#e681a8"),
  convres-relu: rgb("#ad507e"),
  convsoftmax: rgb("#6A0066"),
  input: rgb("#f7f1ed"),
  output: rgb("#6A0066"),
  custom: rgb("#dad9d7"),
  custom-relu: rgb("#a8a7a4"),
  arrow: rgb("#000000"),
  connection: rgb("#000000"),
)

// Cold palette
let colors-cold = (
  conv: rgb("#CDEDFE"),
  conv-relu: rgb("#89C7E8"),
  pool: rgb("#af78e6"),
  unpool: rgb("#B8A3E8"),
  deconv: rgb("#96e7c8"),
  concat: rgb("#7EC8E3"),
  softmax: rgb("#4A148C"),
  gap: rgb("#E91E63"),
  fc: rgb("#9FA8DA"),
  fc-relu: rgb("#7986CB"),
  sum: rgb("#FFFFFF"),
  sum-stroke: rgb("#000000"),
  convres: rgb("#8edbd5"),
  convres-relu: rgb("#54adac"),
  convsoftmax: rgb("#4A148C"),
  input: rgb("#ecebf5"),
  output: rgb("#4A148C"),
  custom: rgb("#d7d9da"),
  custom-relu: rgb("#a1a4ad"),
  arrow: rgb("#000000"),
  connection: rgb("#000000"),
)

let strokes = (
  solid: (paint: black.lighten(20%), thickness: 0.65pt * stroke-thickness),
  hidden: (paint: gray.darken(50%).transparentize(50%), thickness: 0.45pt * stroke-thickness, dash: (1pt, 0.8pt)),
  arrow: (thickness: 0pt),
  connection: (thickness: 1pt * stroke-thickness),
)

let dynamic-color-strokes(fill) = {
  (
    solid: (paint: fill.darken(50%).saturate(80%), thickness: strokes.solid.thickness),
    hidden: (paint: fill.darken(60%).saturate(80%).transparentize(60%), thickness: strokes.hidden.thickness, dash: strokes.hidden.dash),
  )
}

let font-sizes = (
  label: 8.5pt,
  channel-number: 7pt,
  layer-label: 8.5pt,
  output-number: 8pt,
  legend-title: 10pt,
  legend-item: 8pt,
)

let opacity-values = (
  front-face: 30%,
  top-face: 30%,
  right-face: 30%,
  band: 60%,
  ball: 10%,
  edge: 70%,
)

let darken-amounts = (
  top: 0%,
  right: 0%,
)

let arrow-config = (
  triangle-size: 0.2,
  axis-y: 2.5
)

let depth-angle-deg = 45deg

let get-depth-offsets(d) = {
  let s = depth-shear(d, depth-multiplier: depth-multiplier)
  (s, s)
}

let get-y-offset-for-center-on-axis(h, d, axis-y) = {
  let (_, oy) = get-depth-offsets(d)
  axis-y - h / 2 - oy / 2
}

let get-perspective-center-y(y-offset, h, oy) = {
  y-offset + h / 2 + oy / 2
}

let get-layer-anchors(x, y, w, h, ox, oy) = {
  let center-x = x + w/2 + ox/2
  let center-y = y + h/2 + oy/2
  (
    west: (x, center-y),
    east: (x + w + ox, center-y),
    true_west: (x + ox/2, center-y),
    true_east: (x + w + ox/2, center-y),
    north: (center-x, y + h + oy),
    south: (center-x, y),
    anchor: (center-x, center-y),
    near: (center-x, center-y),
    northeast: (x + w + ox, y + h + oy),
    southeast: (x + w + ox, y),
    northwest: (x, y + h + oy),
    southwest: (x, y),
  )
}

let coord-along-path(start, end, pos: 1.0) = {
  (start.at(0) + (end.at(0) - start.at(0)) * pos,
   start.at(1) + (end.at(1) - start.at(1)) * pos)
}

let get-circle-boundary-point(from-pt, center-pt, radius) = {
  let dx = center-pt.at(0) - from-pt.at(0)
  let dy = center-pt.at(1) - from-pt.at(1)
  let dist = calc.sqrt(dx * dx + dy * dy)
  if dist > 0 {
    let ux = dx / dist
    let uy = dy / dist
    (center-pt.at(0) - ux * radius, center-pt.at(1) - uy * radius)
  } else {
    (center-pt.at(0) + radius, center-pt.at(1))
  }
}

let colors = if palette == "cold" { colors-cold } else { colors-warm }
let scale-factor = scale / 100%

canvas(length: 1cm * scale-factor, {
  import draw: *

  let scaled-font = (size) => size * scale-factor

  // Draw an image on the right face, sheared into the isometric projection.
  let draw-isometric-image(x, y, w, h, ox, oy, image) = {
    let img-height = (h) * 28.25pt * scale-factor
    let img-width = (oy / depth-multiplier) * 28.25pt * scale-factor

    let actual-img-width() = measure(image).width
    let actual-img-height() = measure(image).height

    content((x+w+ox/2,y+h/2+oy/2),
      context {
        pad(
          x: -((1+depth-multiplier) * img-height - img-width)/2,
          y: +(img-height/2 - img-width)/2
        )[
        #std.rotate(90deg)[
        #std.skew(ax: 45deg)[
        #std.rotate(-90deg)[
        #pad(
          x: -(actual-img-width() - img-width * depth-multiplier)/2,
          y: -(actual-img-height() - img-height)/2
        )[
        #std.scale(x: img-width * depth-multiplier, y: img-height)[
        #image]
        ]]]]]
      }
    )
  }

  // Outline a prism as one closed silhouette plus its three near-corner creases.
  let draw-prism-silhouette(px, py, pw, ph, pox, poy, base, show-right: true) = {
    let s = (paint: base.paint, thickness: base.thickness, join: "round", cap: "round")
    let A = (px, py)
    let B = (px + pw, py)
    let C = (px + pw, py + ph)
    let D = (px, py + ph)
    let Bp = (px + pw + pox, py + poy)
    let Cp = (px + pw + pox, py + ph + poy)
    let Dp = (px + pox, py + ph + poy)
    line(A, B, Bp, Cp, Dp, D, close: true, stroke: s)
    if show-right { line(B, C, stroke: s) }
    line(D, C, stroke: s)
    line(C, Cp, stroke: s)
  }

  // A layer block: front, top and right faces plus hidden back edges.
  let box-3d(x, y, w, h, d, fill, opacity: 1, show-left: true, show-right: true, ylabel: none, zlabel: none, is-input: false, image: none) = {
    let (ox, oy) = get-depth-offsets(d)
    let alpha = 100% - opacity * 100%

    let dyn-strokes = dynamic-color-strokes(fill)

    line((x, y), (x + ox, y + oy), stroke: dyn-strokes.hidden)
    line((x + ox, y + oy), (x + w + ox, y + oy), stroke: dyn-strokes.hidden)
    line((x + ox, y + oy), (x + ox, y + h + oy), stroke: dyn-strokes.hidden)

    rect((x, y), (x + w, y + h), fill: fill.transparentize(alpha), stroke: none)

    line((x, y + h), (x + ox, y + h + oy), (x + w + ox, y + h + oy), (x + w, y + h),
      close: true, fill: fill.darken(darken-amounts.top).transparentize(alpha), stroke: none)
    line((x + w, y), (x + w + ox, y + oy), (x + w + ox, y + h + oy), (x + w, y + h),
      close: true, fill: fill.darken(darken-amounts.right).transparentize(alpha), stroke: none)

    if image != none {
      draw-isometric-image(x, y, w, h, ox, oy, image)
    }

    draw-prism-silhouette(x, y, w, h, ox, oy, dyn-strokes.solid, show-right: show-right)

    if is-input {
      if ylabel != none {
        content((x - 0.2, y + h/2), anchor: "east",
          [#text(size: scaled-font(font-sizes.layer-label), weight: "bold", str(ylabel))])
      }
      if zlabel != none {
        content((x + w/2 + ox/2, y + h + oy - 0.9), angle: depth-angle-deg,
          [#text(size: scaled-font(font-sizes.layer-label), weight: "bold", str(zlabel))])
      }
    } else {
      if ylabel != none {
        content((x - 0.3, y + h/2), anchor: "east",
          [#text(size: scaled-font(font-sizes.layer-label), str(ylabel))])
      }
      if zlabel != none {
        content((x + w/2 + ox/2, y - 0.4), angle: depth-angle-deg,
          [#text(size: scaled-font(font-sizes.layer-label), str(zlabel))])
      }
    }
  }

  // Front face of a single band, optionally split into conv and activation parts.
  let draw-band-front-face(band-x, y, band-width, h, fill-color, bandfill-color, alpha, show-relu) = {
    if show-relu {
      let conv-width = band-width * 2 / 3
      rect((band-x, y), (band-x + conv-width, y + h),
        fill: fill-color.transparentize(calc.max(opacity-values.front-face, alpha)), stroke: none)
      rect((band-x + conv-width, y), (band-x + band-width, y + h),
        fill: bandfill-color.transparentize(calc.max(opacity-values.front-face, alpha)), stroke: none)
    } else {
      rect((band-x, y), (band-x + band-width, y + h),
        fill: fill-color.transparentize(calc.max(opacity-values.front-face, alpha)), stroke: none)
    }
  }

  // Top face of a single band, optionally split into conv and activation parts.
  let draw-band-top-face(band-x, y, band-width, h, ox, oy, fill-color, bandfill-color, show-relu) = {
    if show-relu {
      let conv-width = band-width * 2 / 3
      line((band-x, y + h), (band-x + ox, y + h + oy),
        (band-x + conv-width + ox, y + h + oy), (band-x + conv-width, y + h),
        close: true,
        fill: fill-color.darken(darken-amounts.top).transparentize(opacity-values.top-face),
        stroke: none)
      line((band-x + conv-width, y + h), (band-x + conv-width + ox, y + h + oy),
        (band-x + band-width + ox, y + h + oy), (band-x + band-width, y + h),
        close: true,
        fill: bandfill-color.darken(darken-amounts.top).transparentize(opacity-values.top-face),
        stroke: none)
    } else {
      line((band-x, y + h), (band-x + ox, y + h + oy),
        (band-x + band-width + ox, y + h + oy), (band-x + band-width, y + h),
        close: true,
        fill: fill-color.darken(darken-amounts.top).transparentize(opacity-values.top-face),
        stroke: none)
    }
  }

  // Edges between bands; the first band also gets the three hidden back edges.
  let draw-band-separator-edges(band-x, y, h, ox, oy, band-width, is-first, fill-color) = {

    let dyn-strokes = dynamic-color-strokes(fill-color)

    if is-first {
      line((band-x, y), (band-x + ox, y + oy), stroke: dyn-strokes.hidden)
      line((band-x + ox, y + oy), (band-x + ox, y + h + oy), stroke: dyn-strokes.hidden)
      line((band-x + ox, y + oy), (band-x + band-width + ox, y + oy), stroke: dyn-strokes.hidden)
    } else {
      line((band-x, y), (band-x, y + h), stroke: dyn-strokes.solid)
      line((band-x, y + h), (band-x + ox, y + h + oy), stroke: dyn-strokes.solid)
      line((band-x, y), (band-x + ox, y + oy), stroke: dyn-strokes.hidden)
      line((band-x + ox, y + oy), (band-x + ox, y + h + oy), stroke: dyn-strokes.hidden)
      line((band-x + ox, y + oy), (band-x + band-width + ox, y + oy), stroke: dyn-strokes.hidden)
    }
  }

  // First channel number goes below the layer, a second one along the depth diagonal.
  let draw-channels-labels(channels, center-x, right-x, y, ox, oy) = {
    if channels != none and channels.len() > 0 {
      content((center-x, y - 0.15),
        [#text(size: scaled-font(font-sizes.channel-number), str(channels.at(0)))])

      if channels.len() > 1 {
        let diag-mid-x = right-x + ox / 2.5
        let diag-mid-y = y + oy / 2.5
        content((diag-mid-x, diag-mid-y - 0.23), angle: depth-angle-deg,
          [#text(size: scaled-font(font-sizes.channel-number), str(channels.at(1)))])
      }
    }
  }

  // `label-dx`/`label-dy` shift the label, `label-orient` or `label-angle` rotates it.
  let draw-layer-label(l, label, cx, cy, size: none) = {
    if label == none { return }
    let font-size = if size == none { font-sizes.label } else { size }
    let body = text(size: scaled-font(font-size), weight: "bold", label)
    let px = cx + l.at("label-dx", default: 0)
    let py = cy + l.at("label-dy", default: 0)

    let orient = l.at("label-orient", default: none)
    let angle = l.at("label-angle", default: none)
    if orient != none and angle != none {
      panic("Use either label-orient or label-angle, not both. label-orient sets " +
            "the angle and the matching anchor together; label-angle leaves the " +
            "anchor to you.")
    }

    if orient == none {
      content((px, py), anchor: l.at("label-anchor", default: "base"),
        angle: if angle == none { 0deg } else { angle }, body)
    } else {
      let presets = (
        horizontal: (rot: 0deg, anchor: "base"),
        diagonal: (rot: -45deg, anchor: "north-east"),
        vertical: (rot: -90deg, anchor: "north"),
      )
      if orient not in presets {
        panic("label-orient must be \"horizontal\", \"diagonal\" or \"vertical\"; got " +
              repr(orient) + ". For any other angle use label-angle together with " +
              "your own label-anchor.")
      }
      let preset = presets.at(orient)
      let rotated = if preset.rot == 0deg { body } else {
        std.rotate(preset.rot, reflow: true, body)
      }
      content((px, py), anchor: l.at("label-anchor", default: preset.anchor), rotated)
    }
  }

  let draw-arrow-icon(x1, y1, x2, y2, opacity: 0.7, paint: none) = {
    let dx = x2 - x1
    let dy = y2 - y1
    let len = calc.sqrt(dx * dx + dy * dy)

    if len > 0 {
      let mid-x = (x1 + x2) / 2
      let mid-y = (y1 + y2) / 2
      let ux = dx / len
      let uy = dy / len
      let px = -uy
      let py = ux

      let size = arrow-config.triangle-size
      let tip = size * 0.9
      let back = size * 0.9
      let wing = size * 0.45

      let tip-pt = (mid-x + ux * tip, mid-y + uy * tip)
      let back-mid = (mid-x - ux * back, mid-y - uy * back)
      let right-pt = (back-mid.at(0) + px * wing, back-mid.at(1) + py * wing)
      let left-pt = (back-mid.at(0) - px * wing, back-mid.at(1) - py * wing)
      let back-tip = (back-mid.at(0) + ux * back * 0.5, back-mid.at(1) + uy * back * 0.5)

      let arrow-color = if paint == none { colors.arrow } else { paint }

      line(tip-pt, right-pt, back-tip, left-pt, close: true,
        fill: arrow-color, stroke: (paint: arrow-color, thickness: strokes.arrow.thickness, join: "round"))
    }
  }

  // A line segment with an arrowhead at its midpoint.
  let draw-segment-with-arrow(x1, y1, x2, y2, opacity: 0.7, style: none, head: true) = {
    let paint = if style == none { colors.connection } else { style.paint }
    let thickness = if style == none { strokes.connection.thickness } else { style.thickness }
    let dash = if style == none { none } else { style.dash }
    line((x1, y1), (x2, y2),
      stroke: (paint: paint, thickness: thickness, dash: dash, cap: "butt"))
    if head {
      draw-arrow-icon(x1, y1, x2, y2, opacity: opacity, paint: paint)
    }
  }

  // Draw a routed connection; `layers` inlines blocks along the second segment.
  let draw-connection-path(segments, opacity: 0.7, layers: none, layer-positions-ref: (:), show-relu: false, style: none, tail-behind: false, heads: auto) = {
    if layers != none and layers.len() > 0 {
      if segments.len() > 0 {
        let seg = segments.at(0)
        draw-segment-with-arrow(seg.at(0).at(0), seg.at(0).at(1), seg.at(1).at(0), seg.at(1).at(1), opacity: opacity, style: style)
      }

      if segments.len() > 1 {
        let seg = segments.at(1)
        let seg-start = seg.at(0)
        let seg-end = seg.at(1)

        let layer-infos = ()
        for layer-spec in layers {
          let layer-type = layer-spec.at("type")

          if layer-type == "conv" {
            let widths = layer-spec.at("widths", default: (0.5,))
            let total-width = widths.fold(0, (acc, w) => acc + w)
            let layer-h = layer-spec.at("height", default: 2)
            let layer-d = layer-spec.at("depth", default: 2)
            let (lox, loy) = get-depth-offsets(layer-d)

            layer-infos.push((
              spec: layer-spec,
              width: total-width,
              height: layer-h,
              depth: layer-d,
              ox: lox,
              oy: loy,
            ))
          }
        }

        let num-layers = layer-infos.len()
        let positions = ()
        for (i, info) in layer-infos.enumerate() {
          let t = (i + 1) / (num-layers + 1)
          let center-x = seg-start.at(0) + (seg-end.at(0) - seg-start.at(0)) * t
          let center-y = seg-start.at(1) + (seg-end.at(1) - seg-start.at(1)) * t
          let layer-x = center-x - info.width / 2
          let layer-y = center-y - info.height / 2 - info.oy / 2

          let west-x = layer-x + info.ox / 2
          let east-x = layer-x + info.width + info.ox / 2

          positions.push((
            x: layer-x,
            y: layer-y,
            center-x: center-x,
            center-y: center-y,
            west: (west-x, center-y),
            east: (east-x, center-y),
          ))
        }

        if positions.len() > 0 {
          draw-segment-with-arrow(seg-start.at(0), seg-start.at(1), positions.at(0).west.at(0), positions.at(0).west.at(1), opacity: opacity, style: style)
        }

        for (i, info) in layer-infos.enumerate() {
          let pos = positions.at(i)
          let layer-spec = info.spec
          let layer-name = layer-spec.at("name", default: none)

          let mid-x = pos.x
          let mid-y = pos.y
          let total-width = info.width
          let layer-h = info.height
          let lox = info.ox
          let loy = info.oy

          let fill-color = layer-spec.at("fill", default: colors.conv)
          let bandfill-color = layer-spec.at("bandfill", default: colors.at("conv-relu"))
          let layer-opacity = layer-spec.at("opacity", default: 1.0)
          let alpha-front = 100% - layer-opacity * 100%
          let widths = layer-spec.at("widths", default: (0.5,))
          let channels = layer-spec.at("channels", default: none)
          let layer-show-relu = layer-spec.at("show-relu", default: show-relu)

          let dyn-strokes = dynamic-color-strokes(fill-color)
          let dyn-band-strokes = dynamic-color-strokes(bandfill-color)

          let has-diagonal-label = channels != none and channels.len() == widths.len() + 1
          let diagonal-label = if has-diagonal-label { channels.at(widths.len()) } else { none }

          let cumulative-x = mid-x
          for (j, w) in widths.enumerate() {
            let band-width = w
            let band-x = cumulative-x

            draw-band-front-face(band-x, mid-y, band-width, layer-h, fill-color, bandfill-color, alpha-front, layer-show-relu)

            if channels != none and j < channels.len() {
              content((band-x + band-width / 2, mid-y - 0.15),
          [#text(size: scaled-font(font-sizes.channel-number), str(channels.at(j)))])
            }

            cumulative-x += band-width
          }

          cumulative-x = mid-x
          for (j, w) in widths.enumerate() {
            let band-width = w
            let band-x = cumulative-x

            draw-band-top-face(band-x, mid-y, band-width, layer-h, lox, loy, fill-color, bandfill-color, layer-show-relu)

            cumulative-x += band-width
          }

          let right-face-color = if layer-show-relu { bandfill-color } else { fill-color }
          let right-face-strokes = if layer-show-relu { dyn-band-strokes } else { dyn-strokes }
          line((mid-x + total-width, mid-y), (mid-x + total-width + lox, mid-y + loy),
            (mid-x + total-width + lox, mid-y + layer-h + loy), (mid-x + total-width, mid-y + layer-h),
            close: true, fill: right-face-color.darken(darken-amounts.right).transparentize(opacity-values.right-face),
            stroke: none)

          cumulative-x = mid-x
          for (j, w) in widths.enumerate() {
            let band-width = w
            let band-x = cumulative-x
            let edge-strokes = if layer-show-relu { dyn-band-strokes } else { dyn-strokes }
            draw-band-separator-edges(band-x, mid-y, layer-h, lox, loy, band-width, j == 0, fill-color)
            cumulative-x += band-width
          }

          draw-prism-silhouette(mid-x, mid-y, total-width, layer-h, lox, loy, dyn-strokes.solid)

          let label = layer-spec.at("label", default: none)
          if label != none {
            draw-layer-label(layer-spec, label, mid-x + total-width / 2, mid-y - 0.5, size: font-sizes.layer-label)
          }

          if diagonal-label != none {
            let diag-start-x = mid-x + total-width
            let diag-start-y = mid-y
            let diag-mid-x = diag-start-x + lox / 2.5
            let diag-mid-y = diag-start-y + loy / 2.5
            content((diag-mid-x, diag-mid-y - 0.23), angle: depth-angle-deg,
              [#text(size: scaled-font(font-sizes.channel-number), str(diagonal-label))])
          }

          if layer-name != none {
            layer-positions-ref.insert(layer-name, (
              x: mid-x, y: mid-y, w: total-width, h: layer-h, ox: lox, oy: loy,
              anchors: get-layer-anchors(mid-x, mid-y, total-width, layer-h, lox, loy)
            ))
          }

          if i < layer-infos.len() - 1 {
            let from-east = positions.at(i).east
            let to-west = positions.at(i + 1).west
            draw-segment-with-arrow(from-east.at(0), from-east.at(1), to-west.at(0), to-west.at(1), opacity: opacity, style: style)
          } else {
            draw-segment-with-arrow(positions.at(-1).east.at(0), positions.at(-1).east.at(1), seg-end.at(0), seg-end.at(1), opacity: opacity, style: style)
          }
        }
      }

      for idx in range(2, segments.len()) {
        let seg = segments.at(idx)
        draw-segment-with-arrow(seg.at(0).at(0), seg.at(0).at(1), seg.at(1).at(0), seg.at(1).at(1), opacity: opacity, style: style)
      }
    } else {
      for (si, seg) in segments.enumerate() {
        let last = si == segments.len() - 1
        let seg-head = if heads == auto { true } else { heads.at(si, default: true) }
        if tail-behind and last {
          on-layer(-1, draw-segment-with-arrow(seg.at(0).at(0), seg.at(0).at(1), seg.at(1).at(0), seg.at(1).at(1), opacity: opacity, style: style, head: seg-head))
        } else {
          draw-segment-with-arrow(seg.at(0).at(0), seg.at(0).at(1), seg.at(1).at(0), seg.at(1).at(1), opacity: opacity, style: style, head: seg-head)
        }
      }
    }

    for i in range(segments.len() - 1) {
      let v = segments.at(i).at(1)
      let a = segments.at(i).at(0)
      let b = segments.at(i + 1).at(1)
      let da = (a.at(0) - v.at(0), a.at(1) - v.at(1))
      let db = (b.at(0) - v.at(0), b.at(1) - v.at(1))
      let la = calc.max(calc.sqrt(da.at(0) * da.at(0) + da.at(1) * da.at(1)), 0.001)
      let lb = calc.max(calc.sqrt(db.at(0) * db.at(0) + db.at(1) * db.at(1)), 0.001)
      let stub = 0.12
      let stub-paint = if style == none { colors.connection } else { style.paint }
      let stub-thickness = if style == none { strokes.connection.thickness } else { style.thickness }
      line(
        (v.at(0) + da.at(0) / la * stub, v.at(1) + da.at(1) / la * stub),
        v,
        (v.at(0) + db.at(0) / lb * stub, v.at(1) + db.at(1) / lb * stub),
        stroke: (paint: stub-paint, thickness: stub-thickness, join: "round", cap: "butt"),
      )
    }
  }

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

    let default-legend-labels = (
      input: "Input",
      conv: "Convolution",
      convres: "Conv Residual",
      pool: "Pooling",
      unpool: "Unpooling",
      deconv: "Deconvolution",
      concat: "Concatenation",
      sum: "Element-wise Sum",
      gap: "Global Avg Pool",
      fc: "Fully Connected",
      convsoftmax: "Conv Softmax",
      softmax: "Softmax",
      output: "Output",
    )

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

        // CUSTOM LAYER
        if l.type == "custom" {
          let h = l.at("height", default: 5)
          let d = l.at("depth", default: 5)
          l.insert("height", h)
          l.insert("depth", d)
          let w = l.at("width", default: none)
          let widths = l.at("widths", default: none)
          let label = l.at("label", default: none)
          let xlabel = l.at("xlabel", default: none)
          let name = l.at("name", default: none)
          let fill-color = l.at("fill", default: colors.custom)
          let bandfill-color = if "bandfill" in l {
            l.at("bandfill")
          } else if "fill" in l {
            fill-color.darken(25%)
          } else {
            colors.at("custom-relu")
          }
          let layer-opacity = l.at("opacity", default: 0.7)
          let channels = l.at("channels", default: none)
          let ylabel-val = l.at("ylabel", default: none)
          let zlabel-val = l.at("zlabel", default: none)
          let layer-show-relu = if "show-relu" in l {
            l.at("show-relu")
          } else {
            show-relu and "bandfill" in l
          }
          let layer-show-connection = l.at("show-connection", default: true)
          let connection-label = l.at("connection-label", default: none)
          let img = l.at("image", default: none)
          let is-input-style = l.at("input-style", default: false)

          let (ox, oy) = get-depth-offsets(d)
          let y-offset = get-y-offset-for-center-on-axis(h, d, arrow-axis-y)

            // Simple box when no band widths were given, multi-band otherwise.
          let use-simple-box = widths == none

          if use-simple-box {
            let actual-w = if w == none { 0.2 } else { w }

            if img == "default" {
              img = image("bird.jpg")
            }

            box-3d(x, y-offset, actual-w, h, d, fill-color, opacity: layer-opacity, show-left: true, show-right: true, image: img)

            draw-channels-labels(channels, x + actual-w/2, x + actual-w, y-offset, ox, oy)

            if name != none {
              layer-positions.insert(name, (
                x: x, y: y-offset, w: actual-w, h: h, ox: ox, oy: oy, type: "custom",
                anchors: get-layer-anchors(x, y-offset, actual-w, h, ox, oy),
                pool-offset: 0
              ))
            }

            if label != none {
              draw-layer-label(l, label, x + actual-w/2, y-offset - 0.5)
            }

            prev-x = x + actual-w
            prev-depth-offset = ox
            x += actual-w
            prev-center-y = get-perspective-center-y(y-offset, h, oy)
            prev-pool-width = 0
          } else {
            let dyn-strokes = dynamic-color-strokes(fill-color)
            let dyn-band-strokes = dynamic-color-strokes(bandfill-color)

            let has-diagonal-label = channels != none and channels.len() == widths.len() + 1
            let diagonal-label = if has-diagonal-label { channels.at(widths.len()) } else { none }
            let channel-labels = if channels != none {
              if has-diagonal-label { channels.slice(0, widths.len()) } else { channels }
            } else {
              (widths.map(w => ""))
            }

            let start-x = x
            let total-width = widths.fold(0, (acc, w) => acc + w)

            let cumulative-x = start-x
            let alpha-front = 100% - layer-opacity * 100%
            for (j, ch) in channel-labels.enumerate() {
              let band-width = widths.at(j)
              let band-x = cumulative-x

              draw-band-front-face(band-x, y-offset, band-width, h, fill-color, bandfill-color, alpha-front, layer-show-relu)

              let band-center-x = band-x + band-width / 2
              content((band-center-x, y-offset - 0.15),
                [#text(size: scaled-font(font-sizes.channel-number), str(ch))])

              cumulative-x += band-width
            }

            cumulative-x = start-x
            for (j, ch) in channel-labels.enumerate() {
              let band-width = widths.at(j)
              let band-x = cumulative-x

              draw-band-top-face(band-x, y-offset, band-width, h, ox, oy, fill-color, bandfill-color, layer-show-relu)

              cumulative-x += band-width
            }

            let right-face-color = if layer-show-relu { bandfill-color } else { fill-color }
            line((start-x + total-width, y-offset), (start-x + total-width + ox, y-offset + oy),
              (start-x + total-width + ox, y-offset + h + oy), (start-x + total-width, y-offset + h),
              close: true,
              fill: right-face-color.darken(darken-amounts.right).transparentize(opacity-values.right-face),
              stroke: none)

            if img != none {
              draw-isometric-image(start-x, y-offset, total-width, h, ox, oy, img)
            }

            cumulative-x = start-x
            for (j, ch) in channel-labels.enumerate() {
              let band-width = widths.at(j)
              let band-x = cumulative-x

              draw-band-separator-edges(band-x, y-offset, h, ox, oy, band-width, j == 0, fill-color)

            cumulative-x += band-width
          }

          draw-prism-silhouette(start-x, y-offset, total-width, h, ox, oy, dyn-strokes.solid)

          prev-x = start-x + total-width
            prev-depth-offset = ox
            x = start-x + total-width
            let center-x = start-x + total-width / 2

            if label != none {
              draw-layer-label(l, label, center-x, y-offset - 0.5, size: font-sizes.layer-label)
            }

            if xlabel != none {
              content((center-x, y-offset - 0.8),
                [#text(size: scaled-font(font-sizes.layer-label), xlabel)])
            }

            if ylabel-val != none {
              content((start-x - 0.4, y-offset + h/2), anchor: "east",
                [#text(size: scaled-font(font-sizes.layer-label), str(ylabel-val))])
            }
            if zlabel-val != none {
              content((start-x + total-width + ox + 0.4, y-offset + h/2 + oy/2), anchor: "west",
                [#text(size: scaled-font(font-sizes.layer-label), str(zlabel-val))])
            }

            if diagonal-label != none {
              let diag-start-x = start-x + total-width
              let diag-start-y = y-offset
              let diag-mid-x = diag-start-x + ox / 2.5
              let diag-mid-y = diag-start-y + oy / 2.5
              content((diag-mid-x, diag-mid-y - 0.23), angle: depth-angle-deg,
                [#text(size: scaled-font(font-sizes.channel-number), str(diagonal-label))])
            }

            if name != none {
              layer-positions.insert(name, (
                x: start-x, y: y-offset, w: total-width, h: h, ox: ox, oy: oy, type: "custom",
                anchors: get-layer-anchors(start-x, y-offset, total-width, h, ox, oy),
                pool-offset: 0
              ))
            }

            prev-center-y = get-perspective-center-y(y-offset, h, oy)
            prev-pool-width = 0
          }

          let custom-legend = l.at("legend", default: none)
          if custom-legend != none {
            let legend-key = "custom-" + str(custom-legend) + "-" + str(fill-color.to-hex())
            if not legend-entries.any(e => e.key == legend-key) {
              legend-entries.push((key: legend-key, label: custom-legend, color: fill-color, bandfill: bandfill-color, show-relu: layer-show-relu, opacity: layer-opacity))
            }
          }
        }

        // INPUT IMAGE
        else if l.type == "input" {
          l.insert("type", "custom")
          if not l.keys().contains("width") { l.insert("width", 0) }
          if not l.keys().contains("fill") { l.insert("fill", colors.input) }
          if not l.keys().contains("opacity") { l.insert("opacity", 0.9) }
          if not l.keys().contains("input-style") { l.insert("input-style", true) }
          if not l.keys().contains("show-connection") { l.insert("show-connection", false) }

          let h = l.at("height", default: 5)
          let d = l.at("depth", default: 5)
          l.insert("height", h)
          l.insert("depth", d)
          let w = l.at("width", default: 0)
          let label = l.at("label", default: none)
          let name = l.at("name", default: none)
          let fill-color = l.at("fill", default: colors.input)
          let layer-opacity = l.at("opacity", default: 0.9)
          let layer-show-connection = l.at("show-connection", default: false)
          let connection-label = l.at("connection-label", default: none)
          let channels = l.at("channels", default: none)
          let img = l.at("image", default: none)

          let (ox, oy) = get-depth-offsets(d)
          let y-offset = get-y-offset-for-center-on-axis(h, d, arrow-axis-y)

          if img == "default" {
            img = image("bird.jpg")
          }

          if img != none {
            draw-isometric-image(x, y-offset, w, h, ox, oy, img)

            let alpha-right = layer-opacity * 100%
            line((x + w, y-offset), (x + w + ox, y-offset + oy),
              (x + w + ox, y-offset + h + oy), (x + w, y-offset + h),
              close: true,
              fill: fill-color.darken(darken-amounts.right).transparentize(alpha-right),
              stroke: dynamic-color-strokes(fill-color).solid)
          } else {
            box-3d(x, y-offset, w, h, d, fill-color, opacity: layer-opacity, show-left: true, show-right: true, image: img)
          }

          draw-channels-labels(channels, x + w/2, x + w, y-offset, ox, oy)

          if name != none {
            layer-positions.insert(name, (
              x: x, y: y-offset, w: w, h: h, ox: ox, oy: oy, type: "input",
              anchors: get-layer-anchors(x, y-offset, w, h, ox, oy),
              pool-offset: 0
            ))
          }

          if label != none {
            draw-layer-label(l, label, x + w/2, y-offset - 0.8)
          }

          prev-x = x + w
          prev-depth-offset = ox
          x += w
          prev-center-y = get-perspective-center-y(y-offset, h, oy)
          prev-pool-width = 0

          let layer-legend = l.at("legend", default: default-legend-labels.at("input"))
          if not legend-entries.any(e => e.key == "input") {
            legend-entries.push((key: "input", label: layer-legend, color: fill-color, bandfill: fill-color, show-relu: false, opacity: layer-opacity))
          }
        }

        // CONVOLUTIONAL BLOCK
        else if l.type == "conv" or l.type == "convres"{
          let fill-color = if l.type == "conv" {
            l.at("fill", default: colors.conv)
            } else if l.type == "convres" {
            l.at("fill", default: colors.convres)
          }
          let bandfill-color = if l.type == "conv" {
            l.at("bandfill", default: colors.at("conv-relu"))
            } else if l.type == "convres" {
            l.at("bandfill", default: colors.at("convres-relu"))
          }

          if not l.keys().contains("fill") { l.insert("fill", fill-color) }
          if not l.keys().contains("bandfill") { l.insert("bandfill", bandfill-color) }
          if not l.keys().contains("widths") { l.insert("widths", (1,)) }
          let channels = l.at("channels", default: none)
          let widths = l.at("widths", default: (1,))
          let h = l.at("height", default: 5)
          let d = l.at("depth", default: 5)
          l.insert("height", h)
          l.insert("depth", d)
          let label = l.at("label", default: none)
          let xlabel = l.at("xlabel", default: none)
          let name = l.at("name", default: none)
          let layer-opacity = l.at("opacity", default: 1.0)
          let ylabel-val = l.at("ylabel", default: none)
          let zlabel-val = l.at("zlabel", default: none)
          let layer-show-relu = l.at("show-relu", default: show-relu)
          let layer-show-connection = l.at("show-connection", default: true)
          let connection-label = l.at("connection-label", default: none)
          let img = l.at("image", default: none)

          if img == "default" {
            img = image("bird.jpg")
          }

          let dyn-strokes = dynamic-color-strokes(fill-color)
          let dyn-band-strokes = dynamic-color-strokes(bandfill-color)

          let has-diagonal-label = channels != none and channels.len() == widths.len() + 1
          let diagonal-label = if has-diagonal-label { channels.at(widths.len()) } else { none }
          let channel-labels = if channels != none {
            if has-diagonal-label { channels.slice(0, widths.len()) } else { channels }
          } else {
            (widths.map(w => ""))
          }

          let (ox, oy) = get-depth-offsets(d)
          let y-offset = get-y-offset-for-center-on-axis(h, d, arrow-axis-y)
          let start-x = x
          let total-width = widths.fold(0, (acc, w) => acc + w)

          let cumulative-x = start-x
          let alpha-front = 100% - layer-opacity * 100%
          for (j, ch) in channel-labels.enumerate() {
            let band-width = widths.at(j)
            let band-x = cumulative-x

            draw-band-front-face(band-x, y-offset, band-width, h, fill-color, bandfill-color, alpha-front, layer-show-relu)

            let band-center-x = band-x + band-width / 2
            content((band-center-x, y-offset - 0.15),
              [#text(size: scaled-font(font-sizes.channel-number), str(ch))])

            cumulative-x += band-width
          }

          cumulative-x = start-x
          for (j, ch) in channel-labels.enumerate() {
            let band-width = widths.at(j)
            let band-x = cumulative-x

            draw-band-top-face(band-x, y-offset, band-width, h, ox, oy, fill-color, bandfill-color, layer-show-relu)

            cumulative-x += band-width
          }

          let right-face-color = if layer-show-relu { bandfill-color } else { fill-color }
          line((start-x + total-width, y-offset), (start-x + total-width + ox, y-offset + oy),
            (start-x + total-width + ox, y-offset + h + oy), (start-x + total-width, y-offset + h),
            close: true,
            fill: right-face-color.darken(darken-amounts.right).transparentize(opacity-values.right-face),
            stroke: none)

          if img != none {
            draw-isometric-image(start-x, y-offset, total-width, h, ox, oy, img)
          }

          cumulative-x = start-x
          for (j, ch) in channel-labels.enumerate() {
            let band-width = widths.at(j)
            let band-x = cumulative-x

            draw-band-separator-edges(band-x, y-offset, h, ox, oy, band-width, j == 0, fill-color)

            cumulative-x += band-width
          }

          draw-prism-silhouette(start-x, y-offset, total-width, h, ox, oy, dyn-strokes.solid)

          prev-x = start-x + total-width
          prev-depth-offset = ox
          x = start-x + total-width
          let center-x = start-x + total-width / 2

          if label != none {
            draw-layer-label(l, label, center-x, y-offset - 0.5, size: font-sizes.layer-label)
          }

          if xlabel != none {
            content((center-x, y-offset - 0.8),
              [#text(size: scaled-font(font-sizes.layer-label), xlabel)])
          }

          if ylabel-val != none {
            content((start-x - 0.4, y-offset + h/2), anchor: "east",
              [#text(size: scaled-font(font-sizes.layer-label), str(ylabel-val))])
          }
          if zlabel-val != none {
            content((start-x + total-width + ox + 0.4, y-offset + h/2 + oy/2), anchor: "west",
              [#text(size: scaled-font(font-sizes.layer-label), str(zlabel-val))])
          }

          if diagonal-label != none {
            let diag-start-x = start-x + total-width
            let diag-start-y = y-offset
            let diag-mid-x = diag-start-x + ox / 2.5
            let diag-mid-y = diag-start-y + oy / 2.5
            content((diag-mid-x, diag-mid-y - 0.23), angle: depth-angle-deg,
              [#text(size: scaled-font(font-sizes.channel-number), str(diagonal-label))])
          }

          if name != none {
            layer-positions.insert(name, (
              x: start-x, y: y-offset, w: total-width, h: h, ox: ox, oy: oy, type: "conv",
              anchors: get-layer-anchors(start-x, y-offset, total-width, h, ox, oy),
              pool-offset: 0
            ))
          }

          prev-center-y = get-perspective-center-y(y-offset, h, oy)
          prev-pool-width = 0

          let layer-legend = l.at("legend", default: default-legend-labels.at(l.type))
          if not legend-entries.any(e => e.key == l.type) {
            legend-entries.push((key: l.type, label: layer-legend, color: fill-color, bandfill: bandfill-color, show-relu: layer-show-relu, opacity: layer-opacity))
          }
        }

        // POOLING LAYER
        else if l.type == "pool" {
          let h = l.at("height", default: 4)
          let d = l.at("depth", default: 4)
          l.insert("height", h)
          l.insert("depth", d)
          let w = 0.1
          let name = l.at("name", default: none)
          let fill-color = l.at("fill", default: colors.pool)
          let layer-opacity = l.at("opacity", default: 0.75)
          let layer-show-connection = l.at("show-connection", default: true)
          let connection-label = l.at("connection-label", default: none)
          let label = l.at("label", default: none)
          let channels = l.at("channels", default: none)
          let img = l.at("image", default: none)
          let layer-offset = { let o = l.at("offset", default: none); if o == auto { auto-offset } else { o } }
          let (ox, oy) = get-depth-offsets(d)
          let y-offset = prev-center-y - h / 2 - oy / 2
          let pool-x = if layer-offset != none { x + layer-offset } else { x + prev-depth-offset / 2 - ox / 2 }

          if img == "default" {
            img = image("bird.jpg")
          }

          box-3d(pool-x, y-offset, w, h, d, fill-color, opacity: layer-opacity, show-left: true, show-right: true, image: img)

          draw-channels-labels(channels, pool-x + w/2, pool-x + w, y-offset, ox, oy)

          if label != none {
            draw-layer-label(l, label, pool-x + w/2, y-offset - 0.5)
          }

          if i > 0 {
            let prev-layer = layers.at(i - 1)
            let prev-name = prev-layer.at("name", default: none)
            if prev-name != none and prev-name in layer-positions {
              let prev-pos = layer-positions.at(prev-name)
              layer-positions.insert(prev-name, (
                ..prev-pos,
                pool-offset: w
              ))
            }
          }

          if name != none {
            layer-positions.insert(name, (
              x: pool-x, y: y-offset, w: w, h: h, ox: ox, oy: oy, type: "pool",
              anchors: get-layer-anchors(pool-x, y-offset, w, h, ox, oy),
              pool-offset: 0
            ))
          }

          prev-x = pool-x + w
          prev-depth-offset = ox
          if layer-offset != none {
            x += layer-offset + w
          } else {
            x = pool-x + w
          }
          prev-center-y = get-perspective-center-y(y-offset, h, oy)
          prev-pool-width = 0

          let layer-legend = l.at("legend", default: default-legend-labels.at("pool"))
          if not legend-entries.any(e => e.key == "pool") {
            legend-entries.push((key: "pool", label: layer-legend, color: fill-color, bandfill: fill-color, show-relu: false, opacity: layer-opacity))
          }
        }

        // UNPOOLING LAYER
        else if l.type == "unpool" {
          let h = l.at("height", default: 4)
          let d = l.at("depth", default: 4)
          l.insert("height", h)
          l.insert("depth", d)
          let w = 0.1
          let name = l.at("name", default: none)
          let fill-color = l.at("fill", default: colors.unpool)
          let layer-show-connection = l.at("show-connection", default: true)
          let connection-label = l.at("connection-label", default: none)
          let layer-opacity = l.at("opacity", default: 0.75)
          let label = l.at("label", default: none)
          let channels = l.at("channels", default: none)
          let img = l.at("image", default: none)
          let layer-offset = { let o = l.at("offset", default: none); if o == auto { auto-offset } else { o } }
          let (ox, oy) = get-depth-offsets(d)
          let y-offset = prev-center-y - h / 2 - oy / 2
          let unpool-x = if layer-offset != none { x + layer-offset } else { x + prev-depth-offset / 2 - ox / 2 }

          if img == "default" {
            img = image("bird.jpg")
          }

          box-3d(unpool-x, y-offset, w, h, d, fill-color, opacity: layer-opacity, show-left: true, show-right: true, image: img)

          draw-channels-labels(channels, unpool-x + w/2, unpool-x + w, y-offset, ox, oy)

          if label != none {
            draw-layer-label(l, label, unpool-x + w/2, y-offset - 0.5)
          }

          if name != none {
            layer-positions.insert(name, (
              x: unpool-x, y: y-offset, w: w, h: h, ox: ox, oy: oy, type: "unpool",
              anchors: get-layer-anchors(unpool-x, y-offset, w, h, ox, oy)
            ))
          }

          prev-x = unpool-x + w
          prev-depth-offset = ox
          if layer-offset != none {
            x += layer-offset + w
          } else {
            x = unpool-x + w
          }
          prev-center-y = get-perspective-center-y(y-offset, h, oy)
          prev-pool-width = 0

          let layer-legend = l.at("legend", default: default-legend-labels.at("unpool"))
          if not legend-entries.any(e => e.key == "unpool") {
            legend-entries.push((key: "unpool", label: layer-legend, color: fill-color, bandfill: fill-color, show-relu: false, opacity: layer-opacity))
          }
        }

        // DECONVOLUTIONAL LAYER
        else if l.type == "deconv" {
          let h = l.at("height", default: 5)
          let d = l.at("depth", default: 5)
          l.insert("height", h)
          l.insert("depth", d)
          let w = l.at("width", default: 0.3)
          let label = l.at("label", default: "")
          let name = l.at("name", default: none)
          let fill-color = l.at("fill", default: colors.deconv)
          let layer-opacity = l.at("opacity", default: 0.7)
          let layer-show-connection = l.at("show-connection", default: true)
          let connection-label = l.at("connection-label", default: none)
          let channels = l.at("channels", default: none)
          let img = l.at("image", default: none)
          let (ox, oy) = get-depth-offsets(d)
          let y-offset = get-y-offset-for-center-on-axis(h, d, arrow-axis-y)

          if img == "default" {
            img = image("bird.jpg")
          }

          box-3d(x, y-offset, w, h, d, fill-color, opacity: layer-opacity, show-left: true, show-right: true, image: img)

          draw-channels-labels(channels, x + w/2, x + w, y-offset, ox, oy)

          if label != none {
            draw-layer-label(l, label, x + w/2, y-offset - 0.5)
          }

          if name != none {
            layer-positions.insert(name, (
              x: x, y: y-offset, w: w, h: h, ox: ox, oy: oy, type: "deconv",
              anchors: get-layer-anchors(x, y-offset, w, h, ox, oy)
            ))
          }

          prev-x = x + w
          prev-depth-offset = ox
          x += w
          prev-center-y = get-perspective-center-y(y-offset, h, oy)
          prev-pool-width = 0

          let layer-legend = l.at("legend", default: default-legend-labels.at("deconv"))
          if not legend-entries.any(e => e.key == "deconv") {
            legend-entries.push((key: "deconv", label: layer-legend, color: fill-color, bandfill: fill-color, show-relu: false, opacity: layer-opacity))
          }
        }

        // CONCATENATION LAYER
        else if l.type == "concat" {
          let h = l.at("height", default: 3)
          let d = l.at("depth", default: 3)
          l.insert("height", h)
          l.insert("depth", d)
          let w = l.at("width", default: 0.15)
          let label = l.at("label", default: "")
          let name = l.at("name", default: none)
          let fill-color = l.at("fill", default: colors.concat)
          let layer-opacity = l.at("opacity", default: 0.7)
          let layer-show-connection = l.at("show-connection", default: true)
          let connection-label = l.at("connection-label", default: none)
          let channels = l.at("channels", default: none)
          let img = l.at("image", default: none)
          let (ox, oy) = get-depth-offsets(d)
          let y-offset = get-y-offset-for-center-on-axis(h, d, arrow-axis-y)

          if img == "default" {
            img = image("bird.jpg")
          }

          box-3d(x, y-offset, w, h, d, fill-color, opacity: layer-opacity, show-left: true, show-right: true, image: img)

          draw-channels-labels(channels, x + w/2, x + w, y-offset, ox, oy)

          if label != none {
            draw-layer-label(l, label, x + w/2, y-offset - 0.5)
          }

          if name != none {
            layer-positions.insert(name, (
              x: x, y: y-offset, w: w, h: h, ox: ox, oy: oy, type: "concat",
              anchors: get-layer-anchors(x, y-offset, w, h, ox, oy)
            ))
          }

          prev-x = x + w
          prev-depth-offset = ox
          x += w
          prev-center-y = get-perspective-center-y(y-offset, h, oy)
          prev-pool-width = 0

          let layer-legend = l.at("legend", default: default-legend-labels.at("concat"))
          if not legend-entries.any(e => e.key == "concat") {
            legend-entries.push((key: "concat", label: layer-legend, color: fill-color, bandfill: fill-color, show-relu: false, opacity: layer-opacity))
          }
        }

        // GLOBAL AVERAGE POOLING
        else if l.type == "gap" {
          let h = l.at("height", default: 1.5)
          let d = l.at("depth", default: 1.5)
          l.insert("height", h)
          l.insert("depth", d)
          let w = 0.3
          let label = l.at("label", default: "")
          let name = l.at("name", default: none)
          let fill-color = l.at("fill", default: colors.gap)
          let layer-opacity = l.at("opacity", default: 0.7)
          let layer-show-connection = l.at("show-connection", default: true)
          let connection-label = l.at("connection-label", default: none)
          let channels = l.at("channels", default: none)
          let img = l.at("image", default: none)
          let (ox, oy) = get-depth-offsets(d)
          let y-offset = get-y-offset-for-center-on-axis(h, d, arrow-axis-y)

          if img == "default" {
            img = image("bird.jpg")
          }

          box-3d(x, y-offset, w, h, d, fill-color, opacity: layer-opacity, show-left: true, show-right: true, image: img)

          draw-channels-labels(channels, x + w/2, x + w, y-offset, ox, oy)

          if label != none {
            draw-layer-label(l, label, x + w/2, y-offset - 0.5)
          }

          if name != none {
            layer-positions.insert(name, (
              x: x, y: y-offset, w: w, h: h, ox: ox, oy: oy, type: "gap",
              anchors: get-layer-anchors(x, y-offset, w, h, ox, oy)
            ))
          }

          prev-x = x + w
          prev-depth-offset = ox
          x += w
          prev-center-y = get-perspective-center-y(y-offset, h, oy)
          prev-pool-width = 0

          let layer-legend = l.at("legend", default: default-legend-labels.at("gap"))
          if not legend-entries.any(e => e.key == "gap") {
            legend-entries.push((key: "gap", label: layer-legend, color: fill-color, bandfill: fill-color, show-relu: false, opacity: layer-opacity))
          }
        }

        // FULLY CONNECTED
        else if l.type == "fc" {
          let h = l.at("height", default: 3)
          let d = l.at("depth", default: 0.4)
          l.insert("height", h)
          l.insert("depth", d)
          let w = 0.2
          let label = l.at("label", default: "")
          let name = l.at("name", default: none)
          let fill-color = l.at("fill", default: colors.fc)
          let layer-opacity = l.at("opacity", default: 0.7)
          let layer-show-connection = l.at("show-connection", default: true)
          let connection-label = l.at("connection-label", default: none)
          let channels = l.at("channels", default: none)
          let img = l.at("image", default: none)
          let (ox, oy) = get-depth-offsets(d)
          let y-offset = get-y-offset-for-center-on-axis(h, d, arrow-axis-y)

          if img == "default" {
            img = image("bird.jpg")
          }

          box-3d(x, y-offset, w, h, d, fill-color, opacity: layer-opacity, show-left: true, show-right: true, image: img)

          draw-channels-labels(channels, x + w/2, x + w, y-offset, ox, oy)

          if label != none {
            draw-layer-label(l, label, x + w/2, y-offset - 0.5)
          }

          if name != none {
            layer-positions.insert(name, (
              x: x, y: y-offset, w: w, h: h, ox: ox, oy: oy, type: "fc",
              anchors: get-layer-anchors(x, y-offset, w, h, ox, oy)
            ))
          }

          prev-x = x + w
          prev-depth-offset = ox
          x += w
          prev-center-y = get-perspective-center-y(y-offset, h, oy)
          prev-pool-width = 0

          let layer-legend = l.at("legend", default: default-legend-labels.at("fc"))
          if not legend-entries.any(e => e.key == "fc") {
            legend-entries.push((key: "fc", label: layer-legend, color: fill-color, bandfill: fill-color, show-relu: false, opacity: layer-opacity))
          }
        }

        // SUM NODE
        else if l.type == "sum" {
          let radius = l.at("radius", default: 0.4)
          let symbol = l.at("symbol", default: "+")
          let label = l.at("label", default: none)
          let name = l.at("name", default: none)
          let fill-color = l.at("fill", default: colors.sum)
          let layer-show-connection = l.at("show-connection", default: true)
          let connection-label = l.at("connection-label", default: none)
          let layer-opacity = l.at("opacity", default: 1.0)
          let channels = l.at("channels", default: none)

          let center-x = x + radius + prev-depth-offset / 2
          let center-y = arrow-axis-y

          let stroke-color = l.at("stroke", default: colors.sum-stroke)
          let sum-stroke = (paint: stroke-color, thickness: strokes.solid.thickness * 1.5)
          fill-color = fill-color.transparentize((1-layer-opacity)*100%)

          circle((center-x, center-y), radius: radius,
            fill: fill-color,
            stroke: sum-stroke)

          if symbol != none {
            let symbole-size = scaled-font(font-sizes.label * 2.5)
            content((center-x, center-y),
              [#v(-0.185 * symbole-size)#text(size: symbole-size, weight: "bold", fill: stroke-color, symbol)])
          }

          if channels != none {
            let (ox, oy) = get-depth-offsets(radius * 2)
            draw-channels-labels(channels, center-x, center-x + radius, center-y - radius, ox, oy)
          }

          if label != none {
            draw-layer-label(l, label, center-x, center-y - 1.5 * radius)
          }

          prev-x = center-x + radius
          prev-depth-offset = 0
          x += radius * 3

          if name != none {
            let (ox, oy) = get-depth-offsets(radius * 2)
            layer-positions.insert(name, (
              x: center-x - radius, y: center-y - radius, w: radius * 2, h: radius * 2, ox: ox, oy: oy,
              type: "sum", radius: radius, center-x: center-x,
              anchors: get-layer-anchors(center-x - radius, center-y - radius, radius * 2, radius * 2, 0, 0),
              pool-offset: 0
            ))
          }

          prev-center-y = center-y
          prev-pool-width = 0

          let layer-legend = l.at("legend", default: default-legend-labels.at("sum"))
          if not legend-entries.any(e => e.key == "sum") {
            legend-entries.push((key: "sum", label: layer-legend, color: fill-color, bandfill: fill-color, show-relu: false, opacity: layer-opacity, stroke: stroke-color))
          }
        }

        // CONVOLUTIONAL SOFTMAX
        else if l.type == "convsoftmax" {
          let h = l.at("height", default: 4)
          let d = l.at("depth", default: 4)
          l.insert("height", h)
          l.insert("depth", d)
          let w = l.at("width", default: 0.1)
          let layer-show-connection = l.at("show-connection", default: true)
          let connection-label = l.at("connection-label", default: none)
          let label = l.at("label", default: "")
          let name = l.at("name", default: none)
          let fill-color = l.at("fill", default: colors.convsoftmax)
          let layer-opacity = l.at("opacity", default: 0.5)
          let channels = l.at("channels", default: none)
          let img = l.at("image", default: none)
          let (ox, oy) = get-depth-offsets(d)
          let y-offset = get-y-offset-for-center-on-axis(h, d, arrow-axis-y)

          if img == "default" {
            img = image("bird.jpg")
          }

          box-3d(x, y-offset, w, h, d, fill-color, opacity: layer-opacity, show-left: true, show-right: true, image: img)

          draw-channels-labels(channels, x + w/2, x + w, y-offset, ox, oy)

          if label != none {
            draw-layer-label(l, label, x + w/2, y-offset - 0.5)
          }

          if name != none {
            layer-positions.insert(name, (
              x: x, y: y-offset, w: w, h: h, ox: ox, oy: oy,
              anchors: get-layer-anchors(x, y-offset, w, h, ox, oy)
            ))
          }

          prev-x = x + w
          prev-depth-offset = ox
          x += w
          prev-center-y = get-perspective-center-y(y-offset, h, oy)
          prev-pool-width = 0

          let layer-legend = l.at("legend", default: default-legend-labels.at("convsoftmax"))
          if not legend-entries.any(e => e.key == "convsoftmax") {
            legend-entries.push((key: "convsoftmax", label: layer-legend, color: fill-color, bandfill: fill-color, show-relu: false, opacity: layer-opacity))
          }
        }

        // SOFTMAX / OUTPUT
        else if l.type == "softmax" or l.type == "output" {
          let h = l.at("height", default: 3)
          let d = l.at("depth", default: 0.4)
          l.insert("height", h)
          l.insert("depth", d)
          let w = l.at("width", default: 0.2)
          let label = l.at("label", default: if l.type == "softmax" { "Softmax" } else { "Output" })
          let name = l.at("name", default: none)
          let layer-show-connection = l.at("show-connection", default: true)
          let connection-label = l.at("connection-label", default: none)
          let classes = l.at("classes", default: none)
          let channels = l.at("channels", default: none)
          let fill-color = l.at("fill", default: if l.type == "softmax" { colors.softmax } else { colors.output })
          let layer-opacity = l.at("opacity", default: 0.5)
          let img = l.at("image", default: none)
          let (ox, oy) = get-depth-offsets(d)
          let y-offset = get-y-offset-for-center-on-axis(h, d, arrow-axis-y)

          if img == "default" {
            img = image("bird.jpg")
          }

          box-3d(x, y-offset, w, h, d, fill-color, opacity: layer-opacity, show-left: true, show-right: true, image: img)

          if channels != none {
            draw-channels-labels(channels, x + w/2, x + w, y-offset, ox, oy)
          } else if classes != none {
            content((x + w/2, y-offset - 0.3),
              [#text(size: scaled-font(font-sizes.output-number), str(classes))])
          }
          if label != none {
            draw-layer-label(l, label, x + w/2, y-offset - 0.6)
          }

          if name != none {
            layer-positions.insert(name, (
              x: x, y: y-offset, w: w, h: h, ox: ox, oy: oy, type: l.type,
              anchors: get-layer-anchors(x, y-offset, w, h, ox, oy)
            ))
          }

          prev-x = x + w
          prev-depth-offset = ox
          x += w
          prev-center-y = get-perspective-center-y(y-offset, h, oy)
          prev-pool-width = 0

          let layer-legend = l.at("legend", default: default-legend-labels.at(l.type))
          if not legend-entries.any(e => e.key == l.type) {
            legend-entries.push((key: l.type, label: layer-legend, color: fill-color, bandfill: fill-color, show-relu: false, opacity: layer-opacity))
          }
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
    let legend-x = prev-x + prev-depth-offset + 1.0
    let legend-item-height = 0.4
    let legend-box-size = 0.3

    let entry-count = legend-entries.len()

    let legend-total-height = 0.5 + entry-count * legend-item-height

    let legend-y = arrow-axis-y + legend-total-height / 2

    content((legend-x - 0.05, legend-y + 0.15),
      anchor: "north-west",
      [#text(size: scaled-font(font-sizes.legend-title), weight: "bold", legend-title)])

    legend-y -= 0.6

    let has-line = legend-entries.any(e => e.at("kind", default: "box") == "line")
    let sample-width = if has-line { legend-box-size * 2.4 } else { legend-box-size }

    for entry in legend-entries {
      let item-stroke = dynamic-color-strokes(entry.color)
      if entry.at("stroke", default: none) != none {
        item-stroke.solid.paint = entry.stroke
      }
      let alpha = 100% - entry.at("opacity", default: 1.0) * 100%

      if entry.at("kind", default: "box") == "line" {
        let mid-y = legend-y + legend-box-size / 2
        let head-size = arrow-config.triangle-size
        let head-center = legend-x + sample-width - head-size * 0.9
        line((legend-x, mid-y), (head-center - head-size * 0.75, mid-y),
          stroke: (paint: entry.style.paint, thickness: entry.style.thickness,
                   dash: entry.style.dash, cap: "butt"))
        draw-arrow-icon(head-center - 0.5, mid-y, head-center + 0.5, mid-y,
          paint: entry.style.paint)
      } else if entry.at("show-relu", default: false) {
        let split-x = legend-x + sample-width * 2 / 3
        rect((legend-x, legend-y), (split-x, legend-y + legend-box-size),
          fill: entry.color.transparentize(alpha), stroke: none)
        rect((split-x, legend-y), (legend-x + sample-width, legend-y + legend-box-size),
          fill: entry.bandfill.transparentize(alpha), stroke: none)
        rect((legend-x, legend-y), (legend-x + sample-width, legend-y + legend-box-size),
          fill: none, stroke: item-stroke.solid)
      } else {
        rect((legend-x, legend-y), (legend-x + sample-width, legend-y + legend-box-size),
          fill: entry.color.transparentize(alpha), stroke: item-stroke.solid)
      }

      content((legend-x + sample-width + 0.2, legend-y - 0.013 + legend-box-size / 2), anchor: "west",
        [#text(size: scaled-font(font-sizes.legend-item), entry.label)])

      legend-y -= legend-item-height
    }
  }
})}