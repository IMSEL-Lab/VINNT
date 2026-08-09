// Connection routing: multi-segment paths, inline blocks along a route, and
// the corner stubs that keep turns crisp.

#import "@preview/cetz:0.5.2": draw
#import draw: line, content, on-layer
#import "theme.typ" as theme
#import "geom.typ" as geom
#import "primitives.typ" as primitives

// Draw a routed connection; `layers` inlines blocks along the second segment.
#let draw-connection-path(ctx, segments, opacity: 0.7, layers: none, layer-positions-ref: (:), show-relu: false, style: none, tail-behind: false, heads: auto) = {
  let colors = ctx.colors
  let strokes = ctx.strokes
  let font-sizes = ctx.font-sizes
  let opacity-values = ctx.opacity-values
  let darken-amounts = ctx.darken-amounts
  let depth-angle-deg = ctx.depth-angle-deg
  let scaled-font(size) = primitives.scaled-font(ctx, size)
  let get-depth-offsets(d) = geom.get-depth-offsets(ctx, d)
  let get-layer-anchors = geom.get-layer-anchors
  let dynamic-color-strokes(fill) = theme.dynamic-color-strokes(strokes, fill)
  let draw-segment-with-arrow(..a) = primitives.draw-segment-with-arrow(ctx, ..a)
  let draw-band-front-face(..a) = primitives.draw-band-front-face(ctx, ..a)
  let draw-band-top-face(..a) = primitives.draw-band-top-face(ctx, ..a)
  let draw-band-separator-edges(..a) = primitives.draw-band-separator-edges(ctx, ..a)
  let draw-prism-silhouette = primitives.draw-prism-silhouette
  let draw-layer-label(..a) = primitives.draw-layer-label(ctx, ..a)

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
