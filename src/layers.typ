// One draw function per layer type.
//
// Each takes `ctx` (figure-wide settings), the layer dictionary, and `st`, the
// walk state: (x, arrow-axis-y, prev-x, prev-center-y, prev-depth-offset,
// prev-pool-width, auto-offset). Each returns its drawing as `body` together
// with the updated cursor, any named positions, and legend candidates; the
// caller merges those into the walk.

#import "@preview/cetz:0.5.2": draw
#import draw: line, rect, content, circle
#import "theme.typ" as theme
#import "geom.typ" as geom
#import "primitives.typ" as primitives
#import "legend.typ": default-legend-labels

// The shared preamble every function below opens with, spelled once here:
// destructure ctx and st, and bind the ctx-carrying helpers under their
// unprefixed names so the drawing code reads the same as it draws.

#let draw-custom-layer(ctx, l-in, st) = {
  let l = l-in
  let colors = ctx.colors
  let show-relu = ctx.show-relu
  let font-sizes = ctx.font-sizes
  let depth-angle-deg = ctx.depth-angle-deg
  let scaled-font(size) = primitives.scaled-font(ctx, size)
  let get-depth-offsets(d) = geom.get-depth-offsets(ctx, d)
  let get-y-offset-for-center-on-axis(h, d, ay) = geom.get-y-offset-for-center-on-axis(ctx, h, d, ay)
  let get-perspective-center-y = geom.get-perspective-center-y
  let get-layer-anchors = geom.get-layer-anchors
  let dynamic-color-strokes(fill) = theme.dynamic-color-strokes(ctx.strokes, fill)
  let box-3d(..a) = primitives.box-3d(ctx, ..a)
  let draw-isometric-image(..a) = primitives.draw-isometric-image(ctx, ..a)
  let draw-prism-silhouette = primitives.draw-prism-silhouette
  let draw-band-front-face(..a) = primitives.draw-band-front-face(ctx, ..a)
  let draw-band-top-face(..a) = primitives.draw-band-top-face(ctx, ..a)
  let draw-band-separator-edges(..a) = primitives.draw-band-separator-edges(ctx, ..a)
  let draw-channels-labels(..a) = primitives.draw-channels-labels(ctx, ..a)
  let draw-layer-label(..a) = primitives.draw-layer-label(ctx, ..a)
  let arrow-axis-y = st.arrow-axis-y
  let x = st.x
  let prev-x = st.prev-x
  let prev-center-y = st.prev-center-y
  let prev-depth-offset = st.prev-depth-offset
  let prev-pool-width = st.prev-pool-width
  let layer-positions = (:)
  let legend-entries = ()

  let body = {
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
        fill: right-face-color.darken(ctx.darken-amounts.right).transparentize(ctx.opacity-values.right-face),
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
      let fill-color = l.at("fill", default: colors.custom)
      let bandfill-color = if "bandfill" in l {
        l.at("bandfill")
      } else if "fill" in l {
        fill-color.darken(25%)
      } else {
        colors.at("custom-relu")
      }
      let layer-show-relu = if "show-relu" in l {
        l.at("show-relu")
      } else {
        show-relu and "bandfill" in l
      }
      let layer-opacity = l.at("opacity", default: 0.7)
      let legend-key = "custom-" + str(custom-legend) + "-" + str(fill-color.to-hex())
      if not legend-entries.any(e => e.key == legend-key) {
        legend-entries.push((key: legend-key, label: custom-legend, color: fill-color, bandfill: bandfill-color, show-relu: layer-show-relu, opacity: layer-opacity))
      }
    }
  }

  (
    body: body, x: x, prev-x: prev-x, prev-center-y: prev-center-y,
    prev-depth-offset: prev-depth-offset, prev-pool-width: prev-pool-width,
    positions: layer-positions, legend: legend-entries, prev-pool-offset: none,
  )
}

#let draw-input-layer(ctx, l-in, st) = {
  let l = l-in
  let colors = ctx.colors
  let font-sizes = ctx.font-sizes
  let scaled-font(size) = primitives.scaled-font(ctx, size)
  let get-depth-offsets(d) = geom.get-depth-offsets(ctx, d)
  let get-y-offset-for-center-on-axis(h, d, ay) = geom.get-y-offset-for-center-on-axis(ctx, h, d, ay)
  let get-perspective-center-y = geom.get-perspective-center-y
  let get-layer-anchors = geom.get-layer-anchors
  let dynamic-color-strokes(fill) = theme.dynamic-color-strokes(ctx.strokes, fill)
  let box-3d(..a) = primitives.box-3d(ctx, ..a)
  let draw-isometric-image(..a) = primitives.draw-isometric-image(ctx, ..a)
  let draw-channels-labels(..a) = primitives.draw-channels-labels(ctx, ..a)
  let draw-layer-label(..a) = primitives.draw-layer-label(ctx, ..a)
  let arrow-axis-y = st.arrow-axis-y
  let x = st.x
  let prev-x = st.prev-x
  let prev-center-y = st.prev-center-y
  let prev-depth-offset = st.prev-depth-offset
  let prev-pool-width = st.prev-pool-width
  let layer-positions = (:)
  let legend-entries = ()

  let body = {
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
        fill: fill-color.darken(ctx.darken-amounts.right).transparentize(alpha-right),
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

  (
    body: body, x: x, prev-x: prev-x, prev-center-y: prev-center-y,
    prev-depth-offset: prev-depth-offset, prev-pool-width: prev-pool-width,
    positions: layer-positions, legend: legend-entries, prev-pool-offset: none,
  )
}

// Handles both "conv" and "convres"; they differ only in their default fills.
#let draw-conv-layer(ctx, l-in, st) = {
  let l = l-in
  let colors = ctx.colors
  let show-relu = ctx.show-relu
  let font-sizes = ctx.font-sizes
  let depth-angle-deg = ctx.depth-angle-deg
  let scaled-font(size) = primitives.scaled-font(ctx, size)
  let get-depth-offsets(d) = geom.get-depth-offsets(ctx, d)
  let get-y-offset-for-center-on-axis(h, d, ay) = geom.get-y-offset-for-center-on-axis(ctx, h, d, ay)
  let get-perspective-center-y = geom.get-perspective-center-y
  let get-layer-anchors = geom.get-layer-anchors
  let dynamic-color-strokes(fill) = theme.dynamic-color-strokes(ctx.strokes, fill)
  let draw-isometric-image(..a) = primitives.draw-isometric-image(ctx, ..a)
  let draw-prism-silhouette = primitives.draw-prism-silhouette
  let draw-band-front-face(..a) = primitives.draw-band-front-face(ctx, ..a)
  let draw-band-top-face(..a) = primitives.draw-band-top-face(ctx, ..a)
  let draw-band-separator-edges(..a) = primitives.draw-band-separator-edges(ctx, ..a)
  let draw-layer-label(..a) = primitives.draw-layer-label(ctx, ..a)
  let arrow-axis-y = st.arrow-axis-y
  let x = st.x
  let prev-x = st.prev-x
  let prev-center-y = st.prev-center-y
  let prev-depth-offset = st.prev-depth-offset
  let prev-pool-width = st.prev-pool-width
  let layer-positions = (:)
  let legend-entries = ()

  let body = {
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
      fill: right-face-color.darken(ctx.darken-amounts.right).transparentize(ctx.opacity-values.right-face),
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

  (
    body: body, x: x, prev-x: prev-x, prev-center-y: prev-center-y,
    prev-depth-offset: prev-depth-offset, prev-pool-width: prev-pool-width,
    positions: layer-positions, legend: legend-entries, prev-pool-offset: none,
  )
}

#let draw-pool-layer(ctx, l-in, st) = {
  let l = l-in
  let colors = ctx.colors
  let get-depth-offsets(d) = geom.get-depth-offsets(ctx, d)
  let get-perspective-center-y = geom.get-perspective-center-y
  let get-layer-anchors = geom.get-layer-anchors
  let box-3d(..a) = primitives.box-3d(ctx, ..a)
  let draw-channels-labels(..a) = primitives.draw-channels-labels(ctx, ..a)
  let draw-layer-label(..a) = primitives.draw-layer-label(ctx, ..a)
  let auto-offset = st.auto-offset
  let x = st.x
  let prev-x = st.prev-x
  let prev-center-y = st.prev-center-y
  let prev-depth-offset = st.prev-depth-offset
  let prev-pool-width = st.prev-pool-width
  let layer-positions = (:)
  let legend-entries = ()
  let prev-pool-offset = none

  let body = {
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

    // The preceding named layer's arrows depart after this pool; the caller
    // records the pool's width on that layer as `pool-offset`.
    prev-pool-offset = w

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

  (
    body: body, x: x, prev-x: prev-x, prev-center-y: prev-center-y,
    prev-depth-offset: prev-depth-offset, prev-pool-width: prev-pool-width,
    positions: layer-positions, legend: legend-entries, prev-pool-offset: prev-pool-offset,
  )
}

#let draw-unpool-layer(ctx, l-in, st) = {
  let l = l-in
  let colors = ctx.colors
  let get-depth-offsets(d) = geom.get-depth-offsets(ctx, d)
  let get-perspective-center-y = geom.get-perspective-center-y
  let get-layer-anchors = geom.get-layer-anchors
  let box-3d(..a) = primitives.box-3d(ctx, ..a)
  let draw-channels-labels(..a) = primitives.draw-channels-labels(ctx, ..a)
  let draw-layer-label(..a) = primitives.draw-layer-label(ctx, ..a)
  let auto-offset = st.auto-offset
  let x = st.x
  let prev-x = st.prev-x
  let prev-center-y = st.prev-center-y
  let prev-depth-offset = st.prev-depth-offset
  let prev-pool-width = st.prev-pool-width
  let layer-positions = (:)
  let legend-entries = ()

  let body = {
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

  (
    body: body, x: x, prev-x: prev-x, prev-center-y: prev-center-y,
    prev-depth-offset: prev-depth-offset, prev-pool-width: prev-pool-width,
    positions: layer-positions, legend: legend-entries, prev-pool-offset: none,
  )
}

// One shape serves deconv, concat, gap and fc: a plain box on the axis whose
// defaults differ per type. `spec` states them: (use-width: bool, width,
// fill-key, opacity) -- `use-width` says whether the `width` option is read,
// with `width` as its fallback, or the width is fixed.
#let draw-box-layer(ctx, l-in, st, spec) = {
  let l = l-in
  let colors = ctx.colors
  let get-depth-offsets(d) = geom.get-depth-offsets(ctx, d)
  let get-y-offset-for-center-on-axis(h, d, ay) = geom.get-y-offset-for-center-on-axis(ctx, h, d, ay)
  let get-perspective-center-y = geom.get-perspective-center-y
  let get-layer-anchors = geom.get-layer-anchors
  let box-3d(..a) = primitives.box-3d(ctx, ..a)
  let draw-channels-labels(..a) = primitives.draw-channels-labels(ctx, ..a)
  let draw-layer-label(..a) = primitives.draw-layer-label(ctx, ..a)
  let arrow-axis-y = st.arrow-axis-y
  let x = st.x
  let prev-x = st.prev-x
  let prev-center-y = st.prev-center-y
  let prev-depth-offset = st.prev-depth-offset
  let prev-pool-width = st.prev-pool-width
  let layer-positions = (:)
  let legend-entries = ()

  let body = {
    let h = l.at("height")
    let d = l.at("depth")
    let w = if spec.use-width { l.at("width", default: spec.width) } else { spec.width }
    let label = l.at("label", default: "")
    let name = l.at("name", default: none)
    let fill-color = l.at("fill", default: colors.at(spec.fill-key))
    let layer-opacity = l.at("opacity", default: spec.opacity)
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

  (
    body: body, x: x, prev-x: prev-x, prev-center-y: prev-center-y,
    prev-depth-offset: prev-depth-offset, prev-pool-width: prev-pool-width,
    positions: layer-positions, legend: legend-entries, prev-pool-offset: none,
  )
}

#let draw-sum-layer(ctx, l-in, st) = {
  let l = l-in
  let colors = ctx.colors
  let strokes = ctx.strokes
  let font-sizes = ctx.font-sizes
  let scaled-font(size) = primitives.scaled-font(ctx, size)
  let get-depth-offsets(d) = geom.get-depth-offsets(ctx, d)
  let get-layer-anchors = geom.get-layer-anchors
  let draw-channels-labels(..a) = primitives.draw-channels-labels(ctx, ..a)
  let draw-layer-label(..a) = primitives.draw-layer-label(ctx, ..a)
  let arrow-axis-y = st.arrow-axis-y
  let x = st.x
  let prev-x = st.prev-x
  let prev-center-y = st.prev-center-y
  let prev-depth-offset = st.prev-depth-offset
  let prev-pool-width = st.prev-pool-width
  let layer-positions = (:)
  let legend-entries = ()

  let body = {
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

  (
    body: body, x: x, prev-x: prev-x, prev-center-y: prev-center-y,
    prev-depth-offset: prev-depth-offset, prev-pool-width: prev-pool-width,
    positions: layer-positions, legend: legend-entries, prev-pool-offset: none,
  )
}

#let draw-convsoftmax-layer(ctx, l-in, st) = {
  let l = l-in
  let colors = ctx.colors
  let get-depth-offsets(d) = geom.get-depth-offsets(ctx, d)
  let get-y-offset-for-center-on-axis(h, d, ay) = geom.get-y-offset-for-center-on-axis(ctx, h, d, ay)
  let get-perspective-center-y = geom.get-perspective-center-y
  let get-layer-anchors = geom.get-layer-anchors
  let box-3d(..a) = primitives.box-3d(ctx, ..a)
  let draw-channels-labels(..a) = primitives.draw-channels-labels(ctx, ..a)
  let draw-layer-label(..a) = primitives.draw-layer-label(ctx, ..a)
  let arrow-axis-y = st.arrow-axis-y
  let x = st.x
  let prev-x = st.prev-x
  let prev-center-y = st.prev-center-y
  let prev-depth-offset = st.prev-depth-offset
  let prev-pool-width = st.prev-pool-width
  let layer-positions = (:)
  let legend-entries = ()

  let body = {
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

  (
    body: body, x: x, prev-x: prev-x, prev-center-y: prev-center-y,
    prev-depth-offset: prev-depth-offset, prev-pool-width: prev-pool-width,
    positions: layer-positions, legend: legend-entries, prev-pool-offset: none,
  )
}

// Handles both "softmax" and "output"; they differ in default label and fill.
#let draw-softmax-layer(ctx, l-in, st) = {
  let l = l-in
  let colors = ctx.colors
  let font-sizes = ctx.font-sizes
  let scaled-font(size) = primitives.scaled-font(ctx, size)
  let get-depth-offsets(d) = geom.get-depth-offsets(ctx, d)
  let get-y-offset-for-center-on-axis(h, d, ay) = geom.get-y-offset-for-center-on-axis(ctx, h, d, ay)
  let get-perspective-center-y = geom.get-perspective-center-y
  let get-layer-anchors = geom.get-layer-anchors
  let box-3d(..a) = primitives.box-3d(ctx, ..a)
  let draw-channels-labels(..a) = primitives.draw-channels-labels(ctx, ..a)
  let draw-layer-label(..a) = primitives.draw-layer-label(ctx, ..a)
  let arrow-axis-y = st.arrow-axis-y
  let x = st.x
  let prev-x = st.prev-x
  let prev-center-y = st.prev-center-y
  let prev-depth-offset = st.prev-depth-offset
  let prev-pool-width = st.prev-pool-width
  let layer-positions = (:)
  let legend-entries = ()

  let body = {
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

  (
    body: body, x: x, prev-x: prev-x, prev-center-y: prev-center-y,
    prev-depth-offset: prev-depth-offset, prev-pool-width: prev-pool-width,
    positions: layer-positions, legend: legend-entries, prev-pool-offset: none,
  )
}
