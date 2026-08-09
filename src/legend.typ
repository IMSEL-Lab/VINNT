// Legend defaults and rendering.

#import "@preview/cetz:0.5.2": draw
#import draw: line, rect, content
#import "theme.typ" as theme
#import "primitives.typ" as primitives

#let default-legend-labels = (
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

#let draw-legend(ctx, legend-entries, legend-title, legend-x, arrow-axis-y) = {
  let font-sizes = ctx.font-sizes
  let arrow-config = ctx.arrow-config
  let scaled-font(size) = primitives.scaled-font(ctx, size)
  let dynamic-color-strokes(fill) = theme.dynamic-color-strokes(ctx.strokes, fill)
  let draw-arrow-icon(..a) = primitives.draw-arrow-icon(ctx, ..a)

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
