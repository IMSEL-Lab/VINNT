# Road to v1.0

Everything below should be addressed before the public release. v1.0 ships once
these are done and real users have tested the result.

Sources for these items: open issues on
[neural-netz](https://github.com/edgaremy/neural-netz/issues) (the package VINNT
forks), open issues on
[PlotNeuralNet](https://github.com/HarisIqbal88/PlotNeuralNet/issues) (76 open,
the visual language VINNT inherits), a survey of Typst Universe, a survey of the
LaTeX and standalone prior art (see the appendix), and a read of the current
source.

---

## Release plan

| Version | Content |
| --- | --- |
| **0.2** | `draw-mlp()` — node-and-edge diagrams. Plus all Tier 0 blockers. |
| **0.2.x** | Harden and document the torch importer. It already works; this is a docs and hardening pass, not new construction. |
| **0.3** | Box-and-arrow block renderer. |
| **0.4** | Transformers, built on the 0.3 renderer. |
| **1.0** | Public feedback absorbed, API frozen. |

Two notes on the ordering.

The **torch importer is not future work**. `tools/import_model.py` is 503 lines,
supports `--torchvision`, `--onnx` and `--checkpoint`, traces a real forward pass
through hooks rather than reading the module tree, and has already produced the
ResNet18, VGG16 and ViT-B/16 traces in `examples/imported/`. Nothing else on
Typst Universe does this, and PlotNeuralNet has been asked for it since 2021
(#124, #63) without ever shipping it. It belongs early, not at the end. The known
limitation is already stated in the script's docstring: leaf-module tracing
cannot observe a residual `out += identity`, because that is a tensor operation
and not a module, so such models import as their trunk and the skips are added by
hand. That is a shippable caveat as long as it is said plainly.

The **0.3 box renderer is a prerequisite, not a detour**. Attention blocks, layer
norms, residual streams and encoder/decoder stacks are drawn as labelled boxes
with arrows, not as isometric tensor prisms. The current vocabulary cannot
express them. Building the box renderer first is what makes 0.4 possible at all.

- [ ] **Decide the renderer boundary at 0.3, not at 0.4.** Three renderers under
      one roof — isometric prisms, neuron graphs, labelled boxes — is coherent
      only if they share connection routing, naming, theming and the legend.
      If each grows its own, the package fractures. Settle this before 0.4.

---

## Tier 0 — release blockers

Nothing ships until these are done.

### Correctness

- [ ] **Non-conv layers on connections are silently dropped.** `src/routing.typ:44`
      filters inlined connection layers with `if layer-type == "conv"`. Every
      other type is discarded with no error and no warning. This is
      neural-netz issue #2, still open upstream, inherited here. Dispatch
      through the same per-type draw path the main axis uses.
- [ ] **Add a regression case for the above.** No test covers it today, because
      `FCN-8.typ` is the only example that puts layers on a connection and it
      only ever uses `conv`.
- [ ] **Nested / multi-hop graphs may drop all but the first path.** neural-netz
      issue #1: only the first nested path renders; the reporter suspects
      `layer-positions` is not updated from `layer-position-ref` after
      `draw-connection-path`. Same code lineage, same function signature here.
      Reproduce against VINNT, then fix or confirm already fixed.
- [ ] **Audit for other silent-drop branches.** The two bugs above share a shape:
      an unmatched type falls off the end of an `if` and vanishes. Find the rest
      and make them either work or raise.

### Public API surface

- [ ] **Custom palettes.** `palette:` takes only `"warm"` or `"cold"`;
      `theme.palette-colors` (`src/theme.typ:63`) silently returns warm for any
      other value. Accept a dictionary so users can pass their own colors, and
      error on an unknown palette name instead of falling back. Covers
      PlotNeuralNet #104 (change colors) and #55 (box edge colors).
- [ ] **Font control.** `font-sizes` is a fixed module constant in `theme.typ`
      with no `draw-network` parameter. Expose font family and sizes. Covers
      PlotNeuralNet #105 and #132, both long open.
- [ ] **Dark mode / dark background support.** Needed for slides, and the first
      thing anyone will ask on the forum thread.
- [ ] **Freeze the public API.** Decide what `lib.typ` exports and commit to it —
      after v1.0 these names are a compatibility promise. Note anything
      currently exported that should not be.

### Packaging

- [ ] **Switch all examples to `@preview/vinnt:<version>`.** Every file in
      `examples/` currently imports `../../src/lib.typ`. Copy-pasted examples
      will fail for every user on Universe.
- [ ] **Update the README import note.** It still says "Not yet on Typst Universe
      so you will have to point the import at a local copy."
- [ ] **Verify `exclude` in `typst.toml`** covers everything and the shipped
      package actually compiles from a clean checkout of only the included files.

---

## Tier 1 — the things that win users

These are what make someone choose VINNT over fletcher, diagraph, or upstream.

### `draw-mlp()` — node-and-edge diagrams

No package on Typst Universe draws neuron-circle MLPs. The general graph tools
(fletcher, diagraph, autograph, gviz, h-graph) can be made to, but only by
hand-placing every node and edge. This is the single strongest argument for
VINNT existing as its own package rather than a patch to neural-netz.

- [x] Core: `draw-mlp((layer(4), layer(6), layer(3)))` — automatic column pitch,
      vertical centering across unequal layer sizes
- [x] `ellipsis: true` — collapse a wide layer to a few nodes plus a vertical
      ellipsis, correctly spaced
- [x] Per-layer and per-node fill, label, and annotation
- [x] Edge styling, including opacity or thickness driven by weight magnitude
      (PlotNeuralNet #59, edge thickness)
- [x] Bias nodes
- [x] Skip and recurrent edges — this is what gets RNN / sequence-model coverage
      almost for free (PlotNeuralNet #12 and #121, both long open)
- [ ] Decide and document how `draw-mlp` and `draw-network` compose in one figure

### Make the model importer prominent

`tools/import_model.py` plus `examples/imported/` already does what
PlotNeuralNet #124 and #63 have asked for since 2021 and never got: generate a
figure from a real PyTorch model. It is currently buried in a subfolder.

- [ ] Document the tracing workflow properly in the manual
- [ ] Feature it in the README, above the architecture gallery
- [ ] Confirm it works on a current torch release and state the supported version
- [ ] Note clearly what is and is not supported (ViT traces today — what fails?)

### Theming and annotation

- [ ] Arrow entries in the legend, not just block swatches (PlotNeuralNet #134)
- [ ] Notes / callouts attached to a block (PlotNeuralNet #70)
- [ ] Input caption support, especially under an image input (#119)
- [ ] Review label positioning options against #115 and #37

---

## Tier 2 — examples

Examples are the listing page. Each one below closes a real, still-open upstream
request or opens a new audience.

### New architectures

- [ ] **Autoencoder / VAE** — symmetric conv/deconv with a latent bottleneck.
      Cheap, and the hourglass is universally needed.
- [ ] **Diffusion U-Net** — U-Net plus timestep embedding and the denoise loop.
      Where the attention is right now; mostly routing that already works.
- [ ] **Siamese / two-tower** — parallel branches into a distance head. Covers
      retrieval, face ID, recommenders.
- [ ] **GAN** — generator, discriminator, real/fake branch (PlotNeuralNet #159
      thread interest, and a different audience entirely)
- [ ] **MobileNet / EfficientNet block detail** — a zoomed figure of
      depthwise-separable conv internals rather than a whole network. Proves
      VINNT does block diagrams, not just full-network pyramids.
- [ ] **1D signal CNN or PointNet** — shows the shape system is not image-only
- [ ] **RNN / LSTM unrolled** — via `draw-mlp` recurrent edges (#12, #121)
- [ ] **Minimal attention block** — not a full transformer, but #159 is the
      single most-requested PlotNeuralNet feature and something is better than
      nothing

### New feature examples

- [ ] **Theming showcase** — one network in warm, cold, custom, and dark
- [ ] **Paper integration** — the same figure inside a real `#figure()` with
      caption, cross-reference, and a two-column layout. The unspoken question
      every reader has is "will this break my document?"
- [ ] **Two networks in one document** (PlotNeuralNet #101)
- [ ] **Annotated figure** — callouts, dimension arrows, highlighted region,
      finished to paper quality
- [ ] **Escape hatch** — dropping into raw CeTZ for something VINNT does not
      model, so readers know they are not trapped
- [ ] **BatchNorm and other missing layer types** (PlotNeuralNet #33)
- [ ] **Custom stages / repeated blocks** (#75), **flatten pattern** (#169),
      **transfer learning** (#56), **pyramid shape** (#130)

---

## Tier 3 — documentation and positioning

The most common PlotNeuralNet issue is not "I cannot draw X." It is "I cannot
get it to run" — `pdflatex not found`, `init.tex not found`, `ModuleNotFoundError`,
`xdg-open not found on Windows`, `how do I use this on Mac`, `where is the .tex
file`, `how do I get a PNG`, `restricted \write18`, `Dockerizing`, `can we have
an Overleaf example`. Roughly half the open issue tracker. All of it disappears
in Typst.

- [ ] **Lead the README with that.** No LaTeX install, no Python step, compiles
      in the browser. It is a stronger opening than any feature list.
- [ ] **Lead with two figures side by side** — an isometric CNN and an MLP.
      "Both metaphors, one package" is a claim no competitor can make.
- [ ] **Manual completeness pass.** PlotNeuralNet #141 ("Add a documentation")
      has been open since 2022. `doc/vinnt-manual.pdf` exists — make sure it is
      genuinely complete and link it prominently.
- [ ] **Full option reference** — every key of every constructor, generated from
      `keys.typ` if possible so it cannot drift
- [ ] **Migration note for neural-netz users** — what is the same, what changed,
      what is fixed
- [ ] **Honest comparison section** — versus neural-netz, neural-viz, fletcher,
      and PlotNeuralNet. Being straight about this builds more trust than
      silence, and `ACKNOWLEDGEMENTS.md` already sets the right tone.
- [ ] **Gallery page with every example rendered**, so the listing has thumbnails

---

## Tier 4 — infrastructure

- [ ] **Expand the regression suite.** 17 cases in `tests/cases` today. Add
      coverage for connection layers of every type, nested graphs, each palette,
      and every example file compiling.
- [ ] **Compile every example as part of `regress.py`** — examples that break
      silently are worse than no examples.
- [ ] **Pin and document the CeTZ version.** `0.5.2` is imported in several
      places; make sure that is deliberate and stated.
- [ ] **CHANGELOG discipline** from here to v1.0.
- [ ] **Decide the version story** — 0.2.0 with `draw-mlp` for early feedback,
      then 1.0 once solid, rather than going straight to 1.0.

---

## Explicitly out of scope for v1.0

- Full transformer architectures. The block vocabulary does not fit, and a bad
  transformer figure is worse than none. A minimal attention block is in Tier 2;
  the full thing waits.
- Graph neural networks.
- Animation or interactivity.

---

## Appendix — prior art worth studying

Nothing here is a Typst competitor. These are the tools people currently use, and
they are where the design vocabulary and the good defaults already exist. The
LaTeX ones matter most, because their users are exactly the people VINNT is
trying to win.

### For `draw-mlp()` (0.2)

**[neuralnetwork.sty](https://ctan.org/pkg/neuralnetwork)** (Mark K Cowan, on
CTAN, source at [battlesnake/neural](https://github.com/battlesnake/neural)) —
the closest thing to a reference API for MLP drawing. Worth borrowing the shape
of almost wholesale.

- `\inputlayer[count=N]`, `\hiddenlayer[count=N]`, `\outputlayer[count=N]` for
  the common case, with a general `\layer` underneath for everything else. This
  is the right two-tier design: trivial things trivial, hard things possible.
- `\linklayers` as a separate step, so connections are not implied by adjacency.
- Environment-level `nodespacing`, `layerspacing`, `nodesize`, and `height` (the
  max node count in any layer, used to set the canvas).
- `toprow` reserves space for bias nodes; `biaspos` places them. Bias handling is
  a first-class concern, not an afterthought.
- `exclude` skips node indices within a layer.
- `\link` addresses a single connection by `from layer`/`from node`/`to layer`/
  `to node` with its own `style` and `labelpos`.
- `\setdefaultnodetext{}` / `\setdefaultlinklabel{}` — label content is a
  user-supplied macro over indices rather than a fixed string. Good idea.

**[nndiagram](https://github.com/ccfang2/nndiagram)** (R, generates TikZ) — has
solved several problems already on the 0.2 list, and the naming is worth copying:

- `nndiagram_oversize(input=3, hidden=c(6,4,6), size.cutoff=5)` — the ellipsis
  feature, driven by a **cutoff threshold** rather than a per-layer boolean. Any
  layer above the cutoff collapses automatically. Better default than
  `ellipsis: true`.
- `omit` and `keep` for connection subsets, e.g. `omit="->4"` — a small selector
  language over an O(n²) edge set. Much better than enumerating edges.
- `node.coverup` — deemphasise specific neurons with lighter colouring, for
  dropout figures and for highlighting a path through the network.
- `activation_curve()` — draws ReLU/sigmoid/step or a custom expression as a
  small inset plot. A neat companion figure; Lilaq would handle this in Typst.
- Consistent top-to-bottom, left-to-right neuron indexing, stated up front.

**[NN-SVG](https://github.com/daidedou/NN-SVG)** — the web tool most people reach
for. Study it for **defaults and proportions** rather than API: it produces
publication-quality FCNN and CNN figures with no configuration at all, which is
the bar for what `draw-mlp` should look like before any options are passed.

**[drawnn](https://github.com/xavigonzalvo/drawnn)** and
**[tikz-nef](https://ctan.org/pkg/tikz-nef)** — smaller, worth a skim.
[tikz.net/neural_networks](https://tikz.net/neural_networks/) and
[texample.net/neural-network](https://texample.net/neural-network/) are galleries
of hand-rolled TikZ MLPs; useful as a survey of what people actually draw when
nothing constrains them.

- [x] Review `neuralnetwork.sty`'s layer/link split before fixing the
      `draw-mlp` API
- [x] Adopt cutoff-driven ellipsis rather than a per-layer flag
- [x] Design a connection selector (`omit`/`keep`) rather than edge enumeration
- [x] Decide whether bias nodes are first-class, as in `neuralnetwork.sty`
- [ ] Compare default proportions against NN-SVG output side by side

### For the importer (0.2.x)

**[pytorch2tikz](https://github.com/fraunhoferhhi/pytorch2tikz)** (Fraunhofer HHI)
— the direct precedent: traces a running PyTorch model and emits PlotNeuralNet
TikZ. Same approach as `tools/import_model.py`, same fundamental limitations.
Worth reading for how they handle what tracing cannot see, and for how they
present those limits to users.

**[Netron](https://github.com/lutzroeder/netron)** — the standard model viewer,
reads ONNX, TorchScript, TF, CoreML, Keras and many more. Not a competitor;
its output is explicitly not publication-ready. But its **format coverage** is
the reference list for what `--onnx` should eventually accept, and its graph
extraction is battle-tested prior art.

- [ ] Read how pytorch2tikz communicates trace limitations
- [ ] Compare the ONNX path against Netron's format handling

### For the box renderer and transformers (0.3, 0.4)

- [ ] Survey how transformer figures are actually drawn in the literature
      (the *Attention Is All You Need* figure and its many descendants) before
      designing the block vocabulary
- [ ] **[TensorSpace](https://github.com/tensorspace-team/tensorspace)** — 3D
      layered visualisation in the browser; worth a look for how it handles
      depth and stacking, though the medium is very different
- [ ] Check [ashishpatel26/Tools-to-Design-or-Visualize-Architecture-of-Neural-Network](https://github.com/ashishpatel26/Tools-to-Design-or-Visualize-Architecture-of-Neural-Network)
      — a curated list of this whole tool space, for anything missed above
