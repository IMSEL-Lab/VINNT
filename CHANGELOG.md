# Changelog

## 0.2.0

### Added

- `draw-mlp(layers, ..)` — neuron-and-edge MLP diagrams, a second renderer
  alongside the isometric blocks. Columns are integers or `mlp-layer(..)` /
  `mlp-gap(..)` constructors; extra edges (skip arcs with an optional ⊕ merge,
  recurrent loops, per-edge restyles) are `mlp-edge(..)` values. `mlp-content`
  is the same figure without the canvas, for embedding in a CeTZ canvas of
  your own. The default palette is `blues` — a print-safe single-hue
  luminance ladder, so the input, hidden and output roles survive grayscale
  reproduction — with `classic` (the green-input, blue-hidden, red-output
  convention of published MLP figures), `brand`, `greys` (pure grayscale),
  `teal` (the grey ladder with a teal output, one hue pops), `lilaq` (the
  first colors of lilaq's default plot cycle), `white` (every fill white,
  accent black — the uncolored textbook line-art figure), `warm` and `cold`
  as named alternatives, all exported as `mlp-palettes`.
- Contrast-aware in-node ink: everything drawn inside a node (inside labels,
  the split Σ and f, in-node glyphs, value text, the inside bias label, the
  dropout X) picks white or black automatically from the node's effective
  fill by perceived luminance. Palette dicts accept the optional keys
  `input-text`, `hidden-text`, `output-text` and `bias-text` to pin the ink
  for a role; a pinned color applies only while the node keeps the palette's
  own role fill, and any per-layer fill, `node-style` fill or `values` ramp
  falls back to the automatic flip.
- Wide layers collapse past a `cutoff` into a vertical ellipsis with the true
  count badged beneath; `mlp-gap` elides depth the same way horizontally.
- Weight-driven edge styling from explicit matrices (the $Wx$ orientation,
  shape-checked), a function over indices, or seeded deterministic random
  values — encoded as color by sign (blue positive, red negative), thickness
  and opacity by magnitude, and a `"dash"` channel that renders negative
  edges dashed by default, so sign survives grayscale; pass `weight-encode`
  without it for all-solid edges.
- Activation display as captions, in-node glyphs, transfer-function block
  icons, or split Σ-then-curve nodes, with a sixteen-name curve catalog and a
  layer-spanning bracket for softmax and argmax.
- Bias nodes, labelled "bias" in small grey text above the node by default
  (`bias-label-pos: "inside"` restores the classic in-node $1$, and
  `bias-label: none` drops the label), io stubs, node states (dropped,
  dimmed, highlighted, excluded),
  per-neuron and per-edge style hooks, square and split node shapes, node
  values as fill, `direction: "up"`, and the package's typos-are-errors
  validation contract throughout, `did-you-mean` included.

## 0.1.1

### Breaking

- Layers, connections and groups are written with their constructors only.
  `(type: "conv", label: "a")` becomes `conv(label: "a")`; connections and
  groups become `connection(from: .., to: ..)` and `group(from: .., to: ..)`.
  A plain dictionary in any of those positions is an error. A dictionary of
  options still spreads into a constructor as `conv(..opts)`.

### Internal

- `src/lib.typ` is split into focused modules with `lib.typ` as a thin
  re-export. Rendered output is unchanged.

## 0.1.0

First release.
