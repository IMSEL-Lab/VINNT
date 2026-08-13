// MLP palettes, strokes and font constants. The brand palette is the fig5
// look and the default; warm and cold derive from the isometric block
// palettes in ../theme.typ so a document using warm isometric figures can
// match its MLPs.

#import "../theme.typ": colors-warm, colors-cold

#let mlp-palettes = (
  brand: (
    input: rgb("#FFF2E3"),
    hidden: rgb("#ECECEC"),
    output: rgb("#466A9F").lighten(65%),
    bias: rgb("#FFFFFF"),
    accent: rgb("#73000A"),
  ),
  warm: (
    input: colors-warm.input,
    hidden: colors-warm.conv.lighten(35%),
    output: colors-warm.output.lighten(65%),
    bias: rgb("#FFFFFF"),
    accent: colors-warm.pool,
  ),
  cold: (
    input: colors-cold.input,
    hidden: colors-cold.conv.lighten(35%),
    output: colors-cold.output.lighten(65%),
    bias: rgb("#FFFFFF"),
    accent: colors-cold.softmax,
  ),
)

// The role keys a palette dict may carry; a partial dict overlays brand.
#let palette-roles = ("input", "hidden", "output", "bias", "accent")

// 70% black, the caption grey used across the package.
#let mlp-grey = rgb("#5C5C5C")

#let mlp-fonts = (
  label: 8pt,
  sub: 6.5pt,
  activation: 6.5pt,
  badge: 6pt,
  title: 10pt,
  stub: 7pt,
  edge-label: 6.5pt,
  matrix-label: 8.5pt,
)

// Every arrowhead in the MLP renderer is a filled stealth head.
#let stealth(paint) = (end: "stealth", fill: paint, scale: 0.6)
#let stealth2(paint) = (start: "stealth", end: "stealth", fill: paint, scale: 0.6)
