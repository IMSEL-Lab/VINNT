// Palettes, strokes, font sizes and the other fixed visual constants.

#let colors-warm = (
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
#let colors-cold = (
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

#let palette-colors(palette) = {
  if palette == "cold" { colors-cold } else { colors-warm }
}

#let make-strokes(stroke-thickness) = (
  solid: (paint: black.lighten(20%), thickness: 0.65pt * stroke-thickness),
  hidden: (paint: gray.darken(50%).transparentize(50%), thickness: 0.45pt * stroke-thickness, dash: (1pt, 0.8pt)),
  arrow: (thickness: 0pt),
  connection: (thickness: 1pt * stroke-thickness),
)

// A layer's edge strokes, derived from its fill so tinted blocks keep contrast.
#let dynamic-color-strokes(strokes, fill) = {
  (
    solid: (paint: fill.darken(50%).saturate(80%), thickness: strokes.solid.thickness),
    hidden: (paint: fill.darken(60%).saturate(80%).transparentize(60%), thickness: strokes.hidden.thickness, dash: strokes.hidden.dash),
  )
}

#let font-sizes = (
  label: 8.5pt,
  channel-number: 7pt,
  layer-label: 8.5pt,
  output-number: 8pt,
  legend-title: 10pt,
  legend-item: 8pt,
)

#let opacity-values = (
  front-face: 30%,
  top-face: 30%,
  right-face: 30%,
  band: 60%,
  ball: 10%,
  edge: 70%,
)

#let darken-amounts = (
  top: 0%,
  right: 0%,
)

#let arrow-config = (
  triangle-size: 0.2,
  axis-y: 2.5
)

#let depth-angle-deg = 45deg
