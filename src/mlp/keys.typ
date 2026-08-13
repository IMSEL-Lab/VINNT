// Option tables for the MLP constructors and the draw-mlp figure options,
// plus the figure defaults and the activation glyph catalog names.

#let mlp-layer-keys = (
  "type", "count", "name", "label", "sub", "activation", "fill", "stroke",
  "shape", "node-size", "node-label", "node-label-pos", "values",
  "show-value-text", "dropped", "dimmed", "highlighted", "exclude",
  "show-all", "bias", "node-style",
)

#let mlp-gap-keys = ("type", "label", "pitch")

#let mlp-edge-keys = (
  "type", "from", "to", "style", "paint", "thickness", "dash", "opacity",
  "arrow", "label", "sum",
)

#let mlp-figure-keys = (
  // layout
  "direction", "unit", "node-size", "node-pitch", "layer-pitch", "title",
  "debug",
  // ellipsis
  "cutoff", "collapse-to", "count-badges",
  // nodes
  "palette", "node-shape", "node-stroke", "node-label", "input-style",
  // edges
  "edge-stroke", "edge-opacity", "arrows", "io-stubs", "stub-labels",
  "edge-filter", "edges", "edge-style",
  // weights
  "weights", "weight-encode", "weight-colors", "weight-range",
  "weight-thickness", "seed",
  // edge and matrix labels
  "edge-labels", "matrix-labels",
  // bias
  "bias", "bias-label", "bias-label-pos",
  // captions
  "layer-labels", "label-pos", "activation", "activation-style",
)

#let mlp-figure-defaults = (
  direction: "right",
  unit: 1cm,
  node-size: 0.17,
  node-pitch: 0.6,
  layer-pitch: 2.2,
  title: none,
  debug: false,
  cutoff: 10,
  collapse-to: 5,
  count-badges: auto,
  palette: "blues",
  node-shape: "circle",
  node-stroke: (paint: black, thickness: 0.6pt),
  node-label: none,
  input-style: "nodes",
  edge-stroke: (paint: rgb("#5C5C5C"), thickness: 0.4pt),
  edge-opacity: 50%,
  arrows: "none",
  io-stubs: false,
  stub-labels: auto,
  edge-filter: none,
  edges: (),
  edge-style: none,
  weights: none,
  weight-encode: ("color", "thickness", "dash"),
  weight-colors: (positive: rgb("#0571B0"), negative: rgb("#CA0020")),
  weight-range: auto,
  weight-thickness: (0.2pt, 1.1pt),
  seed: 42,
  edge-labels: (),
  matrix-labels: false,
  bias: false,
  bias-label: [bias],
  bias-label-pos: "above",
  layer-labels: none,
  label-pos: "below",
  activation: none,
  activation-style: "caption",
)

// The activation curve catalog, canonical names and aliases. validate.typ
// checks against this list; glyphs.typ draws it.
#let glyph-names = (
  "identity", "linear", "step", "heaviside", "sign", "sigmoid", "logistic",
  "tanh", "relu", "leaky-relu", "elu", "softplus", "gelu", "silu", "swish",
  "saturate",
)

// Activations with no per-neuron curve: in any glyph-bearing style they
// render as a layer-spanning bracket instead.
#let bracket-activations = ("softmax", "argmax")
