# What the target figures revealed

Six figures were written as aspirational source first, then mocked in CeTZ so
they could be looked at. The point was to find the design decisions by drawing,
rather than by reasoning in the abstract. These are what turned up.

The sketches in this folder are scaffolding and should be deleted once the real
renderers exist. `mock.typ` is not a proposal for the implementation.

---

## 1. `draw-network` opens its own canvas — this blocks everything

`src/draw.typ:59` calls `canvas(...)` inside `draw-network`. A figure therefore
cannot contain two renderers, because a canvas cannot be nested in a canvas.
Figures 3, 4 and 6 all needed the isometric blocks mocked by hand for exactly
this reason.

Every composed figure the package is meant to enable is blocked by this. The
fix is to split each renderer into a function returning **canvas content** and a
thin wrapper that opens a canvas around it:

    #let network-content(layers, ..) = { /* draw calls only */ }
    #let draw-network(layers, ..) = canvas(length: .., network-content(layers, ..))

This is API-visible and belongs in 0.2, before anything else is built on top.

- [ ] Split every renderer into content-producing and canvas-opening halves

## 2. `mlp()` must be a layer constructor, `draw-mlp()` the wrapper

Figure 4 settles the question from the earlier discussion. A CNN backbone
flattening into a classifier head is one figure with one baseline and one arrow
crossing between vocabularies. If `draw-mlp` were a top-level function with its
own canvas, this would require aligning two outputs by hand — the exact problem
the library exists to abolish.

So `mlp(layers: (128, 64, 10), name: "head")` sits in the layer list like any
other block, and `draw-mlp(...)` is a convenience wrapper for the MLP-only case
(figure 5). Not the other way round.

- [ ] `mlp()` as a layer constructor; `draw-mlp()` as a wrapper over it

## 3. Collapsed columns must carry a width badge

The cutoff-driven ellipsis works — in figure 5 the 8-wide hidden layers collapse
and the 4-wide input does not, with no per-layer flag. But once a column is
collapsed the drawing no longer states the true width, so the figure has lost
information. Both figures 4 and 5 needed a separate count annotation underneath.

That means the ellipsis and the count are one feature, not two. Collapsing
should emit the badge automatically rather than leaving it to the user.

- [ ] Collapsing a column implies a width annotation

## 4. Labels need a shared baseline, not a per-block one

Visible in figure 5: the `input` label sits higher than `h1` and `h2` because
each label hangs off the bottom of its own column, and the columns differ in
height. The isometric renderer has the same problem for blocks of differing
height. Labels should align to a figure-wide baseline row.

- [ ] Figure-wide label baseline, not per-block offsets

## 5. Flat blocks need a secondary text line

Every flat block in figures 2, 3 and 6 wants two lines — a role name and a
qualifier (`Backbone` / `CSPDarknet`, `RGB` / `640x640x3`). No current
constructor has this; `conv()` has `label:` only. Either `label:` accepts a
two-part value or a `sub:` key is added.

- [ ] Decide `sub:` versus a structured `label:`

## 6. Lanes must be shared between renderers, not reinvented

Figure 6 puts two branches in parallel in the flat view. The isometric renderer
already has lane machinery (`lane-unit`, `branch()`). If the flat renderer grows
its own, the two views of the same network will disagree about geometry, which
destroys the entire "one description, many views" thesis.

- [ ] Flat renderer reuses the existing lane and routing machinery

## 7. Merge semantics must exist in both views

Two lanes entering one block, as in figure 6. The isometric side has `concat()`
and `sum()`. If the flat view cannot express the same thing, the description
stops being renderer-independent.

- [ ] `concat()`/`sum()` render in the flat view too

## 8. Block relationships are connections, not block properties

Figure 6 marks two backbones as sharing weights. That is a relationship between
two named blocks, which is exactly what `connections:` already expresses. It
should be a connection with a distinct style, not a `weights: "shared"` key on
the block. Same argument will apply to weight tying, EMA teachers, and
stop-gradient annotations.

- [ ] Express block-to-block relations through `connections:`

## 9. Callouts need anchors on both ends

The magnification lines in figures 3 and 6 are hand-placed and it shows — the
attachment points are arbitrary and the lines are not symmetric. A real
implementation needs named anchors on the source box and the detail panel, and
a rule for which corners connect. This is fiddlier than it looks and is the
least-solved part of the sketches.

- [ ] Anchor model for magnification callouts

---

## The open decision: where does detail come from?

Figure 3 carries both candidate APIs in its header comment.

**Option A** — the expansion is carried inline on the block, via `detail:`.
Easy to type, self-contained, and works when an overview box does not correspond
to one contiguous run of layers. But the network is described twice, which is
exactly the drift the library exists to prevent.

**Option B** — describe the network once and `collapse:` regions into overview
boxes. One source of truth, reuses the existing `groups:` mechanism, and a
changed channel count propagates to both views. Harder, and awkward when the
overview is a coarser abstraction than the layer list rather than a grouping of
it.

B is the better fit for the stated thesis. A is the better fit for figure 6,
where "Gated fusion" expands into something that is not a slice of a linear
trunk at all.

They are not exclusive: `collapse:` for the common case, `detail:` as the escape
hatch when the overview is not a partition of the trunk. That is probably the
answer, but it should be decided deliberately rather than drifted into.

- [ ] Decide: `collapse:`, `detail:`, or both
