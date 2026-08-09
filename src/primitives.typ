// Reusable drawing pieces: prisms, band faces, arrows and labels.
//
// Every function takes `ctx` first, the dictionary draw-network assembles from
// its figure-wide settings (palette colors, strokes, fonts, depth multiplier,
// scale factor). Nothing here holds state of its own.

#import "@preview/cetz:0.5.2": draw
#import draw: line, rect, content, circle
#import "theme.typ": dynamic-color-strokes
#import "geom.typ": get-depth-offsets

#let scaled-font(ctx, size) = size * ctx.scale-factor

// Draw an image on the right face, sheared into the isometric projection.
#let draw-isometric-image(ctx, x, y, w, h, ox, oy, image) = {
  let depth-multiplier = ctx.depth-multiplier
  let img-height = (h) * 28.25pt * ctx.scale-factor
  let img-width = (oy / depth-multiplier) * 28.25pt * ctx.scale-factor

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
#let draw-prism-silhouette(px, py, pw, ph, pox, poy, base, show-right: true) = {
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
#let box-3d(ctx, x, y, w, h, d, fill, opacity: 1, show-left: true, show-right: true, ylabel: none, zlabel: none, is-input: false, image: none) = {
  let font-sizes = ctx.font-sizes
  let darken-amounts = ctx.darken-amounts
  let depth-angle-deg = ctx.depth-angle-deg
  let (ox, oy) = get-depth-offsets(ctx, d)
  let alpha = 100% - opacity * 100%

  let dyn-strokes = dynamic-color-strokes(ctx.strokes, fill)

  line((x, y), (x + ox, y + oy), stroke: dyn-strokes.hidden)
  line((x + ox, y + oy), (x + w + ox, y + oy), stroke: dyn-strokes.hidden)
  line((x + ox, y + oy), (x + ox, y + h + oy), stroke: dyn-strokes.hidden)

  rect((x, y), (x + w, y + h), fill: fill.transparentize(alpha), stroke: none)

  line((x, y + h), (x + ox, y + h + oy), (x + w + ox, y + h + oy), (x + w, y + h),
    close: true, fill: fill.darken(darken-amounts.top).transparentize(alpha), stroke: none)
  line((x + w, y), (x + w + ox, y + oy), (x + w + ox, y + h + oy), (x + w, y + h),
    close: true, fill: fill.darken(darken-amounts.right).transparentize(alpha), stroke: none)

  if image != none {
    draw-isometric-image(ctx, x, y, w, h, ox, oy, image)
  }

  draw-prism-silhouette(x, y, w, h, ox, oy, dyn-strokes.solid, show-right: show-right)

  if is-input {
    if ylabel != none {
      content((x - 0.2, y + h/2), anchor: "east",
        [#text(size: scaled-font(ctx, font-sizes.layer-label), weight: "bold", str(ylabel))])
    }
    if zlabel != none {
      content((x + w/2 + ox/2, y + h + oy - 0.9), angle: depth-angle-deg,
        [#text(size: scaled-font(ctx, font-sizes.layer-label), weight: "bold", str(zlabel))])
    }
  } else {
    if ylabel != none {
      content((x - 0.3, y + h/2), anchor: "east",
        [#text(size: scaled-font(ctx, font-sizes.layer-label), str(ylabel))])
    }
    if zlabel != none {
      content((x + w/2 + ox/2, y - 0.4), angle: depth-angle-deg,
        [#text(size: scaled-font(ctx, font-sizes.layer-label), str(zlabel))])
    }
  }
}

// Front face of a single band, optionally split into conv and activation parts.
#let draw-band-front-face(ctx, band-x, y, band-width, h, fill-color, bandfill-color, alpha, show-relu) = {
  let opacity-values = ctx.opacity-values
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
#let draw-band-top-face(ctx, band-x, y, band-width, h, ox, oy, fill-color, bandfill-color, show-relu) = {
  let opacity-values = ctx.opacity-values
  let darken-amounts = ctx.darken-amounts
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
#let draw-band-separator-edges(ctx, band-x, y, h, ox, oy, band-width, is-first, fill-color) = {

  let dyn-strokes = dynamic-color-strokes(ctx.strokes, fill-color)

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
#let draw-channels-labels(ctx, channels, center-x, right-x, y, ox, oy) = {
  let font-sizes = ctx.font-sizes
  if channels != none and channels.len() > 0 {
    content((center-x, y - 0.15),
      [#text(size: scaled-font(ctx, font-sizes.channel-number), str(channels.at(0)))])

    if channels.len() > 1 {
      let diag-mid-x = right-x + ox / 2.5
      let diag-mid-y = y + oy / 2.5
      content((diag-mid-x, diag-mid-y - 0.23), angle: ctx.depth-angle-deg,
        [#text(size: scaled-font(ctx, font-sizes.channel-number), str(channels.at(1)))])
    }
  }
}

// `label-dx`/`label-dy` shift the label, `label-orient` or `label-angle` rotates it.
#let draw-layer-label(ctx, l, label, cx, cy, size: none) = {
  if label == none { return }
  let font-size = if size == none { ctx.font-sizes.label } else { size }
  let body = text(size: scaled-font(ctx, font-size), weight: "bold", label)
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

#let draw-arrow-icon(ctx, x1, y1, x2, y2, opacity: 0.7, paint: none) = {
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

    let size = ctx.arrow-config.triangle-size
    let tip = size * 0.9
    let back = size * 0.9
    let wing = size * 0.45

    let tip-pt = (mid-x + ux * tip, mid-y + uy * tip)
    let back-mid = (mid-x - ux * back, mid-y - uy * back)
    let right-pt = (back-mid.at(0) + px * wing, back-mid.at(1) + py * wing)
    let left-pt = (back-mid.at(0) - px * wing, back-mid.at(1) - py * wing)
    let back-tip = (back-mid.at(0) + ux * back * 0.5, back-mid.at(1) + uy * back * 0.5)

    let arrow-color = if paint == none { ctx.colors.arrow } else { paint }

    line(tip-pt, right-pt, back-tip, left-pt, close: true,
      fill: arrow-color, stroke: (paint: arrow-color, thickness: ctx.strokes.arrow.thickness, join: "round"))
  }
}

// A line segment with an arrowhead at its midpoint.
#let draw-segment-with-arrow(ctx, x1, y1, x2, y2, opacity: 0.7, style: none, head: true) = {
  let paint = if style == none { ctx.colors.connection } else { style.paint }
  let thickness = if style == none { ctx.strokes.connection.thickness } else { style.thickness }
  let dash = if style == none { none } else { style.dash }
  line((x1, y1), (x2, y2),
    stroke: (paint: paint, thickness: thickness, dash: dash, cap: "butt"))
  if head {
    draw-arrow-icon(ctx, x1, y1, x2, y2, opacity: opacity, paint: paint)
  }
}
