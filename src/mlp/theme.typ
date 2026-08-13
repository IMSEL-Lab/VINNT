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
  // Pure grayscale (ColorBrewer Greys): survives any reproduction.
  greys: (
    input: rgb("#F0F0F0"),
    hidden: rgb("#BDBDBD"),
    output: rgb("#636363"),
    bias: rgb("#FFFFFF"),
    accent: rgb("#000000"),
  ),
  // The grayscale ladder with a teal output and accent, so one hue pops.
  teal: (
    input: rgb("#F0F0F0"),
    hidden: rgb("#BDBDBD"),
    output: rgb("#35978F"),
    bias: rgb("#FFFFFF"),
    accent: rgb("#01665E"),
  ),
  // The first colors of lilaq's default cycle (petroff10), so MLP figures
  // sit next to lilaq plots without a second color language.
  lilaq: (
    input: rgb("#3F90DA"),
    hidden: rgb("#FFA90E"),
    output: rgb("#BD1F01"),
    bias: rgb("#FFFFFF"),
    accent: rgb("#832DB6"),
  ),
  // Every role white, so the figure is line art; roles are told apart by
  // position and labels only.
  white: (
    input: rgb("#FFFFFF"),
    hidden: rgb("#FFFFFF"),
    output: rgb("#FFFFFF"),
    bias: rgb("#FFFFFF"),
    accent: rgb("#000000"),
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
// The optional <role>-text keys pin the in-node ink for nodes whose fill is
// still the palette's own role color; any overridden fill (per-layer fill,
// node-style, values ramp) falls back to the automatic contrast flip.
#let palette-roles = (
  "input", "hidden", "output", "bias", "accent",
  "input-text", "hidden-text", "output-text", "bias-text",
)

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
