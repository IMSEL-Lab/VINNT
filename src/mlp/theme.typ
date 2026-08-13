// MLP palettes, strokes and font constants. The blues palette is the default:
// a single-hue luminance ladder (ColorBrewer Blues), so the three roles stay
// distinguishable on a black-and-white printer or photocopy. classic is the
// tikz.net/texample green/blue/red convention most published MLP figures
// copy; brand is the fig5 look; warm and cold derive from the isometric block
// palettes in ../theme.typ so a document using warm isometric figures can
// match its MLPs.

#import "../theme.typ": colors-warm, colors-cold

#let mlp-palettes = (
  blues: (
    input: rgb("#DEEBF7"),
    hidden: rgb("#9ECAE1"),
    output: rgb("#3182BD"),
    bias: rgb("#FFFFFF"),
    accent: rgb("#B2182B"),
  ),
  classic: (
    input: rgb("#80FF80"),
    hidden: rgb("#8080FF"),
    output: rgb("#FF8080"),
    bias: rgb("#FFFFFF"),
    accent: rgb("#D62728"),
  ),
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

// The role keys a palette dict may carry; a partial dict overlays blues.
#let palette-roles = ("input", "hidden", "output", "bias", "accent")

// 70% black, the caption grey used across the package.
#let mlp-grey = rgb("#5C5C5C")

// 90% black, the darker ink for print-size caption text (activation
// captions and subs); badges stay in mlp-grey one tier lighter.
#let mlp-caption-ink = rgb("#363636")

#let mlp-fonts = (
  label: 8pt,
  sub: 7pt,
  activation: 7pt,
  badge: 6.5pt,
  title: 10pt,
  stub: 7pt,
  edge-label: 7pt,
  matrix-label: 8.5pt,
)

// Every arrowhead in the MLP renderer is a filled stealth head.
#let stealth(paint) = (end: "stealth", fill: paint, scale: 0.6)
#let stealth2(paint) = (start: "stealth", end: "stealth", fill: paint, scale: 0.6)
