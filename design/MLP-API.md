# `draw-mlp` — API specification

Status: **approved for implementation**. This document is the contract for the
0.2 `draw-mlp` feature. It supersedes the sketch notes in `fig5-mlp.typ` where
they disagree. The feature is deliberately **standalone**: it does not touch
`draw-network`, the isometric renderer, or `routing.typ`. Composition with the
block renderer is future work and explicitly out of scope here; the only
concession to that future is the content/canvas split (below), which costs
nothing now and saves an API break later.

Design inputs: the survey of sixteen MLP-drawing tools and the conventions
research (2026-08); `design/FINDINGS.md` items 1–4; `ROADMAP-V1.md` Tier 1 and
its prior-art appendix (`neuralnetwork.sty`, `nndiagram`, NN-SVG).

Guiding principle, in order of precedence.

1. **Zero-config output must look publication-ready.** `draw-mlp((4, 6, 6, 3))`
   with no other options is the bar NN-SVG sets.
2. **Every default follows a documented convention** (textbook look: circles,
   plain grey edges behind nodes, no arrowheads, no bias, activation named in
   the caption row).
3. **Every knob a super-user needs exists**, and the escape hatches are
   functions, not enumerations: node labels, per-edge styles, and connectivity
   are all specifiable as callbacks over indices.
4. **Typos are errors, not silence** — the same validation contract as the rest
   of the package, same message voice, `did-you-mean` included.

---

## 1. Exports

From `src/mlp/lib.typ`, re-exported by `src/lib.typ`:

| export | kind | purpose |
| --- | --- | --- |
| `draw-mlp(layers, ..opts)` | function → content | the command. Opens its own CeTZ canvas. |
| `mlp-content(layers, ..opts)` | function → CeTZ draw content | same figure without the canvas, for embedding in a user's own `canvas(...)`. `draw-mlp` is exactly `canvas(length: unit, mlp-content(..))`. |
| `mlp-layer(count, ..opts)` | constructor | one neuron column. |
| `mlp-gap(..opts)` | constructor | a horizontal "⋯ more layers" elision column. |
| `mlp-edge(from, to, ..opts)` | constructor | an extra edge (skip / recurrent / single link) or a style override for an existing adjacent-pair edge. |
| `mlp-palettes` | dict | the named palettes, exported so users can start from one and override. |

Everything else under `src/mlp/` is internal.

## 2. Architecture input — progressive disclosure

`layers` is an array. Each element is one of:

- an **integer** — shorthand for `mlp-layer(n)`;
- an **`mlp-layer(...)`** value;
- an **`mlp-gap(...)`** value.

Integers and constructors mix freely: `(4, mlp-layer(16, activation: "relu"), 3)`.
A plain dictionary (not from a constructor) is an error, same as the rest of
the package. An empty array, a zero or negative count, or a gap in first or
last position is an error.

Tier examples the manual must reproduce verbatim:

```typ
// Tier 0 — bare counts
#draw-mlp((4, 6, 6, 3))

// Tier 1 — figure-wide options
#draw-mlp((4, 16, 16, 3), activation: "relu", bias: true, cutoff: 8)

// Tier 2 — per-layer constructors (the fig5 target, honored)
#draw-mlp((
  mlp-layer(4,  label: "input"),
  mlp-layer(8,  label: "h1", activation: "relu"),
  mlp-layer(8,  label: "h2", activation: "relu"),
  mlp-layer(3,  label: "output", activation: "softmax"),
), bias: true, cutoff: 6)

// Tier 3 — hooks and data
#draw-mlp((4, 8, 3),
  weights: json("w.json"),
  node-label: (l, i) => $a_#i^((#l))$,
  edge-style: (l, i, j) => if i == j { (dash: "dashed") },
)
```

## 3. Conventions fixed by this spec

- **Indexing is 1-based everywhere**: layers left→right (or bottom→top when
  `direction: "up"`), neurons top→bottom (left→right when `"up"`). Stated in
  the manual up front, nndiagram-style.
- **Edges draw before nodes**; nodes paint over them. Edge endpoints trim at
  ±`node-size` along the flow axis.
- **Every arrowhead is filled stealth**, `scale: 0.6`, paint matching the
  stroke. No open barbs anywhere.
- **Layer captions, activation captions, and count badges sit on shared
  figure-wide baseline rows** (FINDINGS item 4), not per-column offsets. Row
  order below the columns: labels, then activation captions, then badges. Rows
  that are empty for the whole figure take no space.
- **Collapsing implies a count badge** (FINDINGS item 3): a collapsed column
  always states its true width unless `count-badges: false`.

## 4. `mlp-layer` — options

| option | type / values | default | meaning |
| --- | --- | --- | --- |
| `count` | positional int ≥ 1 | required | true layer width |
| `name` | str | auto `"l1"`, `"l2"`, … by position | reference for `mlp-edge`; user names win, collisions error |
| `label` | content \| str | `none` | caption in the label row |
| `sub` | content \| str | `none` | second caption line, smaller and lighter (FINDINGS item 5) |
| `activation` | str \| content \| `none` | figure `activation` for layers 2..L, `none` for layer 1 | see §7 |
| `fill` | color | role color from palette | node fill (first layer = input, last = output, rest = hidden) |
| `stroke` | stroke | figure `node-stroke` | node outline |
| `shape` | `"circle"` \| `"square"` \| `"split"` | figure `node-shape` | §8 |
| `node-size` | number | figure `node-size` | node radius (half-side for squares), canvas units |
| `node-label` | `none` \| `auto` \| fn(i) → content | figure `node-label` | label per neuron; `auto` → role-based math (§9) |
| `node-label-pos` | `"inside"` \| `"left"` \| `"right"` | `"inside"` | |
| `values` | array of float 0..1, length = count | `none` | 3Blue1Brown mode: fill encodes the value (white→role color ramp) |
| `show-value-text` | bool | `false` | print the value (2 decimals) inside the node; requires `values` |
| `dropped` | array of int | `()` | dropout: X through the node, its edges omitted (Srivastava fig. 1) |
| `dimmed` | array of int | `()` | node and its edges at reduced opacity |
| `highlighted` | array of int | `()` | accent ring around the node and full-opacity edges |
| `exclude` | array of int | `()` | not drawn at all, edges omitted (`neuralnetwork.sty` exclude) |
| `show-all` | bool | `false` | exempt this layer from the figure `cutoff` |
| `bias` | bool | figure `bias` (never on last layer) | per-layer override |
| `node-style` | fn(i) → dict \| none | `none` | per-neuron override: any of `fill`, `stroke`, `size`, `shape`. Applied last. |

All index arrays refer to true 1-based neuron indices; out-of-range is an
error naming the layer and the valid range. A neuron may appear in at most one
of `dropped` / `dimmed` / `highlighted` / `exclude`; overlap is an error.

## 5. `mlp-gap` — options

Draws a horizontal-ellipsis column standing for elided depth: three dots at
mid-height, short faded edge stubs entering and leaving, and an optional
caption in the label row (e.g. `[× 6 identical layers]`).

| option | type | default | meaning |
| --- | --- | --- | --- |
| `label` | content \| str | `none` | caption in the label row |
| `pitch` | number | 0.6 × figure `layer-pitch` | width this column occupies |

A gap has no neurons, cannot be an edge endpoint, and gets an auto name
`"g1"`, `"g2"`, … so error messages can point at it.

## 6. `draw-mlp` / `mlp-content` — figure options

### Layout

| option | type | default | meaning |
| --- | --- | --- | --- |
| `direction` | `"right"` \| `"up"` | `"right"` | `"up"` is the Goodfellow/AIMA orientation; implemented as a coordinate swap, captions move to the left of each row, badges to the right |
| `unit` | length | `1cm` | canvas length (`draw-mlp` only) |
| `node-size` | number | `0.17` | default node radius |
| `node-pitch` | number | `0.52` | spacing between neuron centers within a layer |
| `layer-pitch` | number | `2.2` | spacing between layer columns |
| `title` | content \| `none` | `none` | centered above the figure |
| `debug` | bool | `false` | draw slot grid and baseline rows in faint garnet |

Unequal layers are always vertically centered on the flow axis. Not a knob.

### Ellipsis (within a layer)

| option | type | default | meaning |
| --- | --- | --- | --- |
| `cutoff` | int \| `none` | `10` | a layer with `count > cutoff` collapses (nndiagram `size.cutoff`); `none` disables |
| `collapse-to` | odd int ≥ 3 | `5` | slots a collapsed column occupies; the middle slot is the vertical ellipsis, so `5` → 4 drawn neurons: indices 1, 2, count−1, count |
| `count-badges` | `auto` \| `true` \| `false` | `auto` | `auto`: badge under collapsed columns only; `true`: under every column; badges show the true count |

`cutoff` must exceed `collapse-to`; violating that is an error. Edges attach
only to drawn neurons. `node-label: auto` on a collapsed layer labels the last
two drawn neurons with their true indices (…, n−1, n).

### Nodes

| option | type | default | meaning |
| --- | --- | --- | --- |
| `palette` | `"blues"` \| `"classic"` \| `"brand"` \| `"greys"` \| `"teal"` \| `"lilaq"` \| `"warm"` \| `"cold"` \| dict | `"blues"` | role→color map with keys ⊆ `(input, hidden, output, bias, accent)`; a partial dict overlays the blues (default) palette; an unknown name is an **error** (no silent fallback) |
| `node-shape` | `"circle"` \| `"square"` \| `"split"` | `"circle"` | figure default; per-layer `shape` wins |
| `node-stroke` | stroke | `(paint: black, thickness: 0.8pt)` | |
| `node-label` | `none` \| `auto` \| fn(l, i) → content | `none` | figure default; per-layer `node-label` (fn(i)) wins |
| `input-style` | `"nodes"` \| `"square"` \| `"arrows"` | `"nodes"` | `"square"` renders layer 1 as squares (AIMA); `"arrows"` replaces layer-1 nodes with labelled stub arrows into layer 2 (perceptron style; layer-1 `count` still sets how many) |

Built-in palettes (`mlp-palettes`):

- `blues` — input `#DEEBF7`, hidden `#9ECAE1`, output `#3182BD` (ColorBrewer
  Blues), bias `#FFFFFF`, accent `#B2182B`. A single-hue luminance ladder:
  the roles stay distinguishable when printed black-and-white or photocopied.
  The default.
- `classic` — input `#80FF80` (TikZ `green!50`), hidden `#8080FF`
  (`blue!50`), output `#FF8080` (`red!50`), bias `#FFFFFF`, accent `#D62728`.
  The Fauske/tikz.net convention most published MLP figures copy; near-equal
  luminance across roles, so prefer `blues` when the figure may be printed
  in grayscale.
- `brand` — input `#FFF2E3` (sand), hidden `#ECECEC`, output `#466A9F`
  lightened 65%, bias `#FFFFFF`, accent `#73000A` (garnet). The fig5 look.
- `greys` — input `#F0F0F0`, hidden `#BDBDBD`, output `#636363` (ColorBrewer
  Greys), bias `#FFFFFF`, accent `#000000`. Pure grayscale.
- `teal` — the `greys` ladder with output `#35978F` and accent `#01665E`,
  so exactly one hue pops.
- `lilaq` — input `#3F90DA`, hidden `#FFA90E`, output `#BD1F01`, accent
  `#832DB6`: the first colors of lilaq's default cycle (petroff10), for
  documents whose plots are drawn with lilaq.
- `warm` / `cold` — derived from the corresponding `theme.typ` block palettes
  so a document using warm isometric figures can match its MLPs.

### Edges

| option | type | default | meaning |
| --- | --- | --- | --- |
| `edge-stroke` | stroke | `(paint: #5C5C5C, thickness: 0.4pt)` | base stroke before opacity |
| `edge-opacity` | ratio | `50%` | applied to `edge-stroke` paint |
| `arrows` | `"none"` \| `"all"` | `"none"` | arrowheads on inter-layer edges (stealth, small). Textbook default is none |
| `io-stubs` | `false` \| `true` \| `"in"` \| `"out"` | `false` | short stub arrows entering layer 1 / leaving layer L, one per (drawn) neuron |
| `stub-labels` | `auto` \| `none` \| fn(side, i) → content | `auto` | `auto` → $x_i$ on in-stubs, $hat(y)_i$ on out-stubs (only when `io-stubs` shows that side) |
| `edge-filter` | fn(l, i, j) → bool | `none` | connectivity predicate over the adjacent-pair edge set: gap `l` (1-based, between layers l and l+1), source neuron `i`, target `j`. `false` drops the edge. The `omit`/`keep` selector, done as a function |
| `edges` | array of `mlp-edge(..)` | `()` | extra edges and per-edge overrides, §10 |
| `edge-style` | fn(l, i, j) → dict \| none | `none` | style override for adjacent-pair edges: any of `paint`, `thickness`, `dash`, `opacity`. Applied **after** weight encoding — the last word |

### Weights (§11 for semantics)

| option | type | default | meaning |
| --- | --- | --- | --- |
| `weights` | `none` \| array of matrices \| fn(l, i, j) → float \| `"random"` | `none` | matrix `l` has `counts[l+1]` rows × `counts[l]` columns (target-major, the $W x$ convention); `"random"` generates deterministic values from `seed` |
| `weight-encode` | array ⊆ `("color", "thickness", "opacity", "dash")` | `("color", "thickness", "dash")` | which channels encode the weight; `"dash"` renders negative edges dashed `(2pt, 1.6pt)` while positive stay solid, so sign survives grayscale printing and color-vision deficiency — in the default set since the B/W-print pass |
| `weight-colors` | dict `(positive, negative)` | `(positive: #0571B0, negative: #CA0020)` | sign colors (blue-positive/red-negative — the 3Blue1Brown / ColorBrewer RdBu endpoints) |
| `weight-range` | `auto` \| float | `auto` | |w| that saturates the encoding; `auto` = max over the data |
| `weight-thickness` | pair of lengths | `(0.2pt, 1.1pt)` | thickness at 0 and at saturation |
| `seed` | int | `42` | for `weights: "random"` (small deterministic LCG — Typst has no RNG, and goldens must be stable) |

### Edge and matrix labels

| option | type | default | meaning |
| --- | --- | --- | --- |
| `edge-labels` | array of dicts `(l, i, j, label)` | `()` | label named edges; `label: auto` → $w_(j i)^((l))$. Deliberately per-edge: the convention is one representative label, not all |
| `matrix-labels` | `false` \| `true` \| fn(l) → content | `false` | `true` → $W^((l))$ centered in each inter-layer gap, above the edge fan (the Goodfellow compact annotation) |

### Bias

| option | type | default | meaning |
| --- | --- | --- | --- |
| `bias` | bool | `false` | bias node above each layer 1..L−1, one `node-pitch` above the top slot, labelled by `bias-label`, filled with palette `bias`, edges to every drawn neuron of the next layer |
| `bias-label` | content \| `none` | `[bias]` | `none` suppresses the label |
| `bias-label-pos` | `"above"` \| `"inside"` | `"above"` | `"above"` puts the label over the node in small grey text, where a word fits; `"inside"` is the classic look for short content like `$1$` |

Bias edges are styled as normal edges but are **not** covered by `weights`
matrices (those describe $W$, not $b$); `edge-style` and `edge-filter` do not
see them. Rationale: bias display is presentation, and letting the weight
matrix silently mis-size against `counts+1` is the kind of trap this package
exists to reject.

### Captions

| option | type | default | meaning |
| --- | --- | --- | --- |
| `layer-labels` | `none` \| `auto` \| array | `none` | `auto` → "input", "hidden 1"…"hidden k", "output" (single hidden layer: just "hidden"); array length L of content/str/none; per-layer `label` wins over both |
| `label-pos` | `"below"` \| `"above"` | `"below"` | which side of the columns the caption rows sit on |

## 7. Activation display

| option | values | default |
| --- | --- | --- |
| `activation-style` | `"caption"` \| `"glyph"` \| `"block"` \| `"split"` | `"caption"` |

- **caption** — the activation name, typeset small in the activation baseline
  row under (or above, per `label-pos`) the layer. Any string or content is
  accepted here.
- **glyph** — the tiny curve drawn inside each neuron of the layer (curve
  only, no axes, spanning ~60% of the node diameter, 0.6pt stroke in the
  node's stroke paint). Known-glyph names only.
- **block** — one small square (side ≈ 2×`node-size`, floored at 12pt so the
  curve stays resolvable) containing the glyph, its stroke scaling with the
  box (8% of the side, floored at 0.6pt), drawn in the activation row under
  the column: the MATLAB/Hagan transfer-function icon, placed where it
  cannot collide with edges.
- **split** — forces `shape: "split"` (§8) for layers with an activation:
  Σ in the left half, the glyph in the right.

Glyph catalog (name → silhouette): `identity`/`linear` (diagonal), `step`/
`heaviside` (staircase), `sign`, `sigmoid`/`logistic` (S through mid-height),
`tanh` (S through center), `relu` (flat-then-diagonal), `leaky-relu` (shallow
negative slope), `elu`, `softplus`, `gelu`, `silu`/`swish` (the three smooth-
kink curves differ slightly: elu saturates left, softplus is everywhere-smooth,
gelu/silu dip below zero before the rise), `saturate` (ramp with both rails).

`softmax` and `argmax` have **no per-neuron curve** — in any glyph-bearing
style they render instead as a right-side bracket spanning the layer with the
name beside it (caption row stays clean). In `"caption"` style they are plain
text like everything else.

An unknown activation name is an error **when a glyph is required**
(`"glyph"`, `"block"`, `"split"`), listing the catalog. In `"caption"` style
anything renders as text, so nothing errors.

## 8. Node shapes

- `circle` — radius `node-size`.
- `square` — side `2 × node-size`, axis-aligned.
- `split` — circle at `1.35 × node-size` with a vertical chord divider;
  $Sigma$ in the left half, the activation glyph (or $f$ when the layer has no
  activation) in the right. The classic perceptron summation-then-squash view.

## 9. `node-label: auto`

Role-based math, 1-based true indices: layer 1 → $x_i$; hidden layer k (of
several) → $h_i^((k))$ (single hidden layer: $h_i$); layer L → $hat(y)_i$.
Placed per `node-label-pos`; `inside` shrinks to fit the node. With
`input-style: "arrows"`, the layer-1 labels move onto the stubs.

## 10. `mlp-edge` — extra edges and overrides

```typ
mlp-edge(from: "l1.2", to: "l3.4", style: "arc-above", label: $w$)
mlp-edge(from: "l2", to: "l2", style: "loop")          // recurrent, whole layer
mlp-edge(from: (2, 1), to: (3, 4), thickness: 1.2pt)   // positional addressing
```

| option | type / values | default | meaning |
| --- | --- | --- | --- |
| `from`, `to` | `"name.index"` \| `"name"` \| `(layer, index)` \| `(layer,)` | required | node-level or layer-level endpoint; layer addressed by name or 1-based position |
| `style` | `"straight"` \| `"arc-above"` \| `"arc-below"` \| `"loop"` | auto | auto: `straight` for adjacent-pair endpoints, `arc-above` for skips, `loop` when `from` = `to` |
| `paint` | color | edge default / accent for skips | |
| `thickness` | length | edge default | |
| `dash` | dash spec | `none` | |
| `opacity` | ratio | edge default; `100%` for skips and loops | |
| `arrow` | bool | `true` for skip/loop, `false` for adjacent | stealth head at `to` |
| `label` | content \| `none` | `none` | at the arc apex / edge midpoint |
| `sum` | bool | `false` | terminate a layer-level skip in a small ⊕ node before the target layer (ResNet convention) |

Semantics.

- **Adjacent node pair** → a style override for that existing edge (it does
  not duplicate the line).
- **Non-adjacent node pair** → a new arc routed above (or below) the network,
  clearing the tallest intervening column.
- **Layer→layer** (no node index): adjacent pairs mean "restyle every edge in
  that gap"; non-adjacent pairs mean one layer-level skip arc from column top
  to column top (with optional `sum`).
- **from = to** (layer-level only) → recurrent self-loop arc over the column.

Endpoints referencing unknown names, out-of-range indices, gaps, or excluded
neurons are errors with `did-you-mean`.

## 11. Weight encoding

Applies to adjacent-pair edges only, when `weights` is set. Per edge with
value $w$: let $t = min(|w| / range, 1)$.

- `color` ∈ encode → paint = `weight-colors.positive` if $w ≥ 0$ else
  `.negative`.
- `thickness` ∈ encode → linear interpolation over `weight-thickness` by $t$.
- `opacity` ∈ encode → interpolate 15% → 100% by $t$ (replacing
  `edge-opacity`).
- `dash` ∈ encode → edges with $w < 0$ render dashed `(2pt, 1.6pt)`;
  positive edges stay solid. An accessibility opt-in so sign survives
  grayscale and color-vision deficits; not in the default encode set.

Matrix orientation: `weights.at(l-1)` maps gap `l`; entry `[j][i]` is the edge
from neuron `i` (layer l) to neuron `j` (layer l+1) — the $W x$ convention,
stated in the manual. Dimension mismatches error with both the expected and
received shapes. On collapsed layers only drawn edges are rendered, but
`weight-range: auto` still scans the full matrices, so the visible encoding is
honest about the true scale.

## 12. Geometry (normative)

- Column x-positions accumulate `layer-pitch` (gaps use their own `pitch`).
  The flow axis is y = 0; each column's slots center on it.
- Slot count: `min(count, collapse-to if collapsed)`. Vertical extent of a
  column: `(slots − 1) × node-pitch`.
- Collapsed column slot map (`collapse-to: 5`): slots 1, 2 → neurons 1, 2;
  slot 3 → three-dot vertical ellipsis (dots radius `0.13 × node-size`);
  slots 4, 5 → neurons count−1, count.
- Baseline rows (FINDINGS 4): row 0 sits `0.55` below the **figure-wide**
  lowest column extent (not per-column); rows step by `0.34`. Labels 8pt;
  subs and activation captions 7pt in 90% black; badges 6.5pt in 70% black.
  `sub` renders in the same row block as `label`, directly beneath it.
- Bias node: centered `node-pitch` above its column's top slot; when the next
  layer is taller, still relative to its own column (matching
  `neuralnetwork.sty`'s toprow).
- Skip arcs: cubic through a control height `0.75` above the tallest
  intervening column top (below for `arc-below`); loops are a small circular
  arc over the column, stealth head returning into the top node.
- `direction: "up"` swaps axes after all layout; caption rows sit left of the
  rows, badges right, title still on top.

## 13. Validation and errors

Reuse `edit-distance` / `did-you-mean` / `check-keys` from `src/validate.typ`
(pure helpers; importing them is not "connecting the renderers"). Error voice
matches the package: `vinnt: unknown mlp-layer option "shpae" on layer 2.
Did you mean "shape"? Options accepted here: …`. (The suggestion only fires
within the shared `did-you-mean` edit-distance threshold; a distant key like
"colour" lists the accepted options without a guess.)

Checks, at minimum: unknown options on every constructor and on `draw-mlp`
itself; non-constructor dictionaries; counts ≥ 1; gap placement; name
collisions; index ranges on `dropped`/`dimmed`/`highlighted`/`exclude` and
their mutual exclusivity; `values` length; `cutoff > collapse-to`;
`collapse-to` odd and ≥ 3; palette name/keys; glyph names when a glyph is
required; `weights` dimensions per gap; `weight-encode` members; `mlp-edge`
endpoint resolution; `edge-labels` entries resolving to real edges.

## 14. Module layout

```
src/mlp/
  keys.typ       option tables for mlp-layer, mlp-gap, mlp-edge, and the
                 draw-mlp figure options
  validate.typ   the checks in §13 (imports helpers from ../validate.typ)
  ctor.typ       mlp-layer, mlp-gap, mlp-edge — unset-sentinel pattern as
                 in ../ctor.typ
  theme.typ      mlp-palettes, stroke and font constants
  geom.typ       slot math, column layout, collapse mapping, baseline rows
  glyphs.typ     the activation curve paths, each `(size) => draw content`
  edges.typ      adjacent-pair edge set, filtering, weight encoding, extra-
                 edge routing
  draw.typ       mlp-content and draw-mlp
  lib.typ        public re-exports
```

`src/lib.typ` gains one line: `#import "mlp/lib.typ": draw-mlp, mlp-content,
mlp-layer, mlp-gap, mlp-edge, mlp-palettes`. No other existing file changes.
`typst.toml`'s `exclude` must be checked to ensure `src/mlp/` ships.

## 15. Test plan (`tests/cases/`, golden harness)

One case per feature axis, each a small single-variable figure:

`mlp-basic` (bare ints, zero config) · `mlp-ellipsis` (collapse + badges) ·
`mlp-bias` · `mlp-activation-captions` · `mlp-activation-glyphs` (a sheet
exercising the full catalog, incl. softmax bracket) · `mlp-activation-split` ·
`mlp-shapes` (square input + split hidden) · `mlp-weights` (explicit matrices,
color+thickness) · `mlp-weights-random` (seeded) · `mlp-extra-edges` (skip
arc with ⊕, recurrent loop, single restyled edge) · `mlp-node-states`
(dropped/dimmed/highlighted/exclude) · `mlp-labels` (node-label auto,
layer-labels auto, io-stubs, matrix-labels, title) · `mlp-direction-up` ·
`mlp-palette` (custom dict + per-layer fill) · `mlp-gap` · `mlp-edge-filter`
(+ representative edge-label) · `mlp-input-arrows` · `mlp-values`.

Error contract: `tests/error-cases/*.typ`, each expected to fail compilation,
first line a comment `// EXPECT: <substring of the error>`; checked by a new
`tests/check_errors.py` (run with `uv run`), kept separate from `regress.py`
so the golden harness stays untouched. Cases: typo'd option, out-of-range
index, weight shape mismatch, unknown glyph under `"glyph"`, unknown palette
name, plain-dict layer, dangling `mlp-edge` endpoint.

## 16. Example plan (`examples/mlp/`)

`classic.typ` (the fig5 figure via the real API) · `playground.typ` (random
weights, color+thickness, io-stubs, node labels) · `perceptron.typ` (one
split neuron, input arrows, bias — the Rosenblatt diagram) · `textbook.typ`
(`direction: "up"`, square inputs, monochrome palette, matrix labels) ·
`dropout.typ` (dropped + dimmed, Srivastava look) · `deep.typ` (mlp-gap,
skip arc with ⊕, recurrent loop). Each `#set page(width: auto, height: auto,
margin: 6mm)`, imports `../../src/lib.typ`, rendered into the gallery.

## 17. Implementation notes (as built)

The implementation deviates from the text above in these settled ways; this
section is normative over §1–§16 where they conflict.

- Unknown-option checks fire at draw time (the message needs the column
  position, which a constructor cannot know); constructors validate
  `count ≥ 1` immediately and stamp type + marker.
- The figure-level `activation` option exists as §4 describes; it was missing
  from the §6 tables.
- `weight-range: auto` scans full matrices for the array form, but only drawn
  edges for the function and `"random"` forms (a full scan of a callback over
  collapsed 1000-wide layers would be pathological).
- A layer immediately followed by an `mlp-gap` draws no bias node — bias
  edges across an elision would fake adjacency.
- In `direction: "up"` the caption rows are text columns, the activation
  column 1.27 left of the label column (0.34 would overlap); `label-pos` is
  ignored there. The title centers over the full horizontal extents actually
  used — left caption columns to right badge column — not over the flow axis.
- An adjacent node pair given an explicit `style: "arc-above"/"arc-below"`
  routes as an arc; `auto`/`straight` restyle the existing edge, and re-add
  the single link if `edge-filter` removed it.
- Edge style precedence: base → weight encoding → dimmed/highlighted opacity
  → `mlp-edge` override → `edge-style` hook.
- `weights` as an array always has L−1 entries, counting gaps (a matrix
  facing an `mlp-gap` is accepted and unused).
- `io-stubs` on the input side is suppressed under `input-style: "arrows"`
  (they would double up); `show-value-text` wins over an inside node label;
  inside labels are suppressed under glyph style and split shape.
- `weights: "random"`: per-edge hash `seed + l·73856093 + i·19349663 +
  j·83492791`, passed twice through `s·1664525 + 1013904223 mod 2³²`, mapped
  to [−1, 1]. Golden images depend on this exact sequence.
- In `direction: "up"`, `matrix-labels` render in the left caption column
  beside each gap rather than centered over the edge fan — deliberate, since
  the fan is horizontal there.
- Per-layer `shape: "split"` under the default `activation-style: "caption"`
  shows both the in-node glyph and the caption text; the orthogonal options
  compose as stated. `activation-style: "split"` is the recommended spelling
  and the one the manual teaches.
- A skip arc routed `arc-above` across a column that carries a recurrent
  loop will cross it; route such skips `arc-below` (or move the loop). A
  worked example belongs in the manual; the library does not auto-dodge.
- Every in-node text size (the split Σ and f, inside node labels, value
  text, the bias digit) scales with node size but floors at 6.5pt; a tight
  label beats an unreadable one.
- Dimmed state: node fill and stroke transparentize 55% (not 70%), dimmed
  edges multiply their opacity by 0.45 (not 0.3), so dimmed units stay
  visible at print size.
- The `sign` glyph is a true discontinuity — flat rails at ±0.8 joined by a
  thin vertical jump stroke — and `step` runs along the zero baseline before
  jumping to 0.85, so the two stay distinct from each other and from
  `sigmoid` at 6pt sizes.
- `"dash"` is a fourth accepted `weight-encode` member (negatives dashed
  `(2pt, 1.6pt)`). It entered the default set in the B/W-print pass, so
  weight sign survives grayscale reproduction; pass an explicit
  `weight-encode` without it for all-solid edges.
- The default palette moved twice on user direction: brand → classic
  (standard over house colors), then classic → `"blues"` (the ColorBrewer
  luminance ladder above) because classic's near-equal-luminance roles
  collapse under black-and-white printing. classic and brand remain available
  by name. Default `weight-colors` are the ColorBrewer RdBu endpoints
  `#0571B0`/`#CA0020`.
- The default bias label is the word `[bias]` above the node (user direction:
  the bare constant `1` inside the circle read as cryptic). `bias-label-pos:
  "inside"` restores the classic in-node placement for short content, and
  `bias-label: none` suppresses the label. A recurrent loop and a bias label
  can crowd each other over the same column; move one if they meet.

## 18. Out of scope (explicit)

Composition with `draw-network` and the `mlp()` block constructor (deferred by
decision, enabled later by `mlp-content`); legends; the Goodfellow one-node-
per-layer compact mode (future `shape: "block"` slot is reserved in the design
but not implemented); animation; GNNs. Batch-norm is not a neuron type
anywhere in the literature and is deliberately absent.
