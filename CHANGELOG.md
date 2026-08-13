# Changelog

## 0.2.0

### Added

- `draw-mlp(layers, ..)` — neuron-and-edge MLP diagrams, a second renderer
  alongside the isometric blocks. Columns are integers or `mlp-layer(..)` /
  `mlp-gap(..)` constructors; extra edges (skip arcs with an optional ⊕ merge,
  recurrent loops, per-edge restyles) are `mlp-edge(..)` values. `mlp-content`
  is the same figure without the canvas, for embedding in a CeTZ canvas of
  your own. The default palette is `classic` — the green-input, blue-hidden,
  red-output convention of published MLP figures — with `brand`, `warm` and
  `cold` as named alternatives, all exported as `mlp-palettes`.
- Wide layers collapse past a `cutoff` into a vertical ellipsis with the true
  count badged beneath; `mlp-gap` elides depth the same way horizontally.
- Weight-driven edge styling from explicit matrices (the $Wx$ orientation,
  shape-checked), a function over indices, or seeded deterministic random
  values — encoded as color by sign (blue positive, red negative), thickness
  and opacity by magnitude, and an opt-in `"dash"` channel that dashes
  negative edges so sign survives grayscale.
- Activation display as captions, in-node glyphs, transfer-function block
  icons, or split Σ-then-curve nodes, with a sixteen-name curve catalog and a
  layer-spanning bracket for softmax and argmax.
- Bias nodes, io stubs, node states (dropped, dimmed, highlighted, excluded),
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
