#import "manual-lib.typ": *

#set document(title: "The VINNT manual", author: "J.C. Vaught")
#set page(
  paper: "a4",
  margin: (x: 2.6cm, y: 2.4cm),
  numbering: "1",
  number-align: center,
)
#set text(size: 10pt, lang: "en", hyphenate: true)
#set par(justify: true, leading: 0.62em)
#show raw: set text(font: "DejaVu Sans Mono")
#show raw.where(block: false): set text(size: 0.88em)
#show link: set text(fill: atlantic)

#set heading(numbering: "1.1")
#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  block(above: 0pt, below: 16pt, {
    text(size: 8pt, fill: garnet, weight: "bold", tracking: 1.2pt,
      upper[Chapter #counter(heading).display("1")])
    v(2pt)
    text(size: 20pt, weight: "bold", it.body)
    v(3pt)
    line(length: 100%, stroke: 1.5pt + garnet)
  })
}
#show heading.where(level: 2): it => block(above: 15pt, below: 7pt,
  text(size: 12.5pt, weight: "bold", fill: garnet, it))
#show heading.where(level: 3): it => block(above: 11pt, below: 5pt,
  text(size: 10.5pt, weight: "bold", it.body))

#set page(numbering: none)
#align(center)[
  #v(3cm)
  #text(size: 30pt, weight: "bold")[VINNT]
  #v(2pt)
  #text(size: 13pt, fill: grey-70)[Vision Illustration of Neural Networks in Typst]
  #v(1.4cm)
  #block(width: 80%, image("build/types-overview.pdf", width: 100%))
  #v(1.4cm)
  #text(size: 10pt)[Version 0.2.0 · J.C. Vaught]
  #v(4pt)
  #text(size: 9pt, fill: grey-70)[Every figure in this manual is compiled from the code printed beside it.]
]

#pagebreak()
#set page(numbering: "1")
#counter(page).update(1)

#outline(depth: 2, indent: 1.2em)

= What this is

VINNT draws layered neural network architectures as isometric block diagrams, the
kind that open a paper's method section. It is a Typst package built on
#link("https://typst.app/universe/package/cetz/")[CeTZ].

You describe the network as an array of layers. The package works out the
geometry, the spacing, the arrows between blocks, the routing of any skip
connection you add, and the legend.

It also draws the other canonical figure --- the neuron-and-edge diagram, a
circle per unit --- with `draw-mlp`, which has a chapter of its own
(chapter 14).

#ex("basics-minimal", fig-width: 78%,
  caption: [Three convolutions, no options at all. Sizes, spacing and arrows are defaults.])

== How this manual is organised

Every option is shown on its own, usually across several figures, because one
picture of an option tells you it exists and three tell you what it does. Where
an option has a failure mode, the failure is shown next to the fix. Each chapter
ends with a composite figure built from what the chapter covered, and chapter 15
is nothing but composites.

Complete published architectures --- AlexNet, VGG, ResNet, U-Net, FCN-8,
YOLO26-n and six RGB-IR fusion variants --- are not here. They are whole
readable files in `examples/` in the repository, and they are better read as
files than quoted as fragments.

== Installing

#snippet(```typ
#import "@preview/vinnt:0.2.0": draw-network, conv, pool, input
```)

Every example in this manual assumes an import like that one. Import
`draw-network` plus whichever constructors you use, or take everything with
`: *`, which is what the examples here do.

#warn[
  VINNT is not yet published on Typst Universe. Until it is, point the import at
  a local copy: `#import "path/to/src/lib.typ": *`, which is what every example
  in this manual does.
]

== The shape of a figure

#snippet(```typ
#draw-network(
  layers,
  connections: (),
  groups: (),
  ...
)
```)

Everything in this manual is either an option on a layer, an option on a
connection or a group, or one of those figure-wide settings.

= Writing a layer

A layer is a constructor call. Every type has one, named after it, and its
arguments are the options:

#ex("basics-ctor", fig-width: 88%)

A constructor's signature is exactly the set of options that type accepts, so
an editor can list them while you type, and Typst rejects a misspelled argument
by name before the package ever sees it. A plain dictionary in the layer list
is an error rather than a second way to write the same thing, so every figure
reads the same. When options arrive as a dictionary anyway --- shared settings,
an imported dump --- spread it into the constructor: `conv(..opts)`.

== Options that do not exist are errors

An option a layer type does not read is rejected, not ignored:

#snippet(```
error: unknown layer option "hieght" on layer 3 (type "conv").
Did you mean "height"? Options accepted here: bandfill, channels,
connection-label, depth, fill, height, image, label, ...
```)

This matters more than it sounds. A key that is quietly ignored produces a
figure that is merely wrong, and a wrong figure reads as the package being
broken rather than as the typo it is. The check covers layer options, connection
options, group options, unknown layer types, a layer with no `type`, and a
connection or group naming a layer that has no such `name`.

#note[
  The suggestion searches the options that type actually accepts, so `widths` on
  a `pool` is caught as readily as `hieght` on a `conv`. The first is spelled
  correctly and still means nothing there.
]

== Naming a layer

#opt("name", default: "none")[
  An identifier for this layer. Never printed. Connections and groups find a
  layer by it, and nothing else does, so a layer with no name cannot be
  referred to.
]

#ex-wide("basics-named", fig-width: 82%)

== The list is just an array

Nothing requires you to write layers out one by one. The list is an array and a
constructor is a function, so ordinary Typst builds both. Sharing options across
several layers is a spread:

#ex-wide("basics-shared", fig-width: 74%)

And generating layers is a `map`:

#ex-wide("basics-loop", fig-width: 82%)

This is the difference between a figure you maintain and a figure you rewrite.
Section 15.5 takes it further.

= Layer types

Fourteen types are predefined. Each carries a colour, a default size, a default
legend entry, and in three cases a behaviour.

#ex-wide("types-overview", fig-width: 96%, fig-height: 7cm,
  caption: [Also predefined: `input`, `pool`, `unpool`, `convsoftmax`, `custom`.])

Type governs colour and defaults, not capability. Any type can be resized,
recoloured, relabelled and given an image. Choose by what the block *means*: the
type decides what the legend calls it and what colour a reader will come to
associate with it across your figures.

== The convolution family

`conv` and `convres` differ only in colour and legend text. `custom` is the same
block with no meaning attached, and is the one you extend (chapter 9).

#ex-wide("types-conv-family", fig-width: 72%)

== Pooling attaches to the block in front

#opt("offset", default: "auto", applies: [read specially by `pool` and `unpool`])[
  On `pool` and `unpool`, leaving `offset` unset attaches the layer to the block
  before it, with no arrow between them. That is what makes a
  convolution-plus-pool read as one stage rather than two.
]

#ex-wide("types-pool-attached", fig-width: 100%, fig-height: 5cm)

Give one an `offset` and it detaches, and the axis arrow appears:

#ex("types-pool-detached", fig-width: 92%)

An encoder-decoder uses both, `pool` on the way down and `unpool` on the way up:

#ex-wide("types-pool-unpool", fig-width: 88%)

== The sum node

`sum` is a node, not a block. It has a `radius` where other types have a width,
and a `symbol` you can replace.

#opt("radius", default: "0.4", applies: [`sum`])[Size of the disc.]
#opt("symbol", default: "+", applies: [`sum`])[Any content, centred in the disc.]
#opt("stroke", default: "black", applies: [`sum`])[Outline colour.]

#ex-wide("types-sum-variants", fig-width: 76%)

== Pooling to a vector, and joining

`gap` collapses a feature map to a vector and is small by default. `concat`
joins two paths, and is the usual target for a fan of arriving routes
(section 10.6).

#ex-wide("types-gap-concat", fig-width: 82%)

== Classifier heads

`fc`, `softmax`, `convsoftmax` and `output` are the tail of a classifier. `fc`
with `depth: 0` draws as a flat rectangle, which is what a vector looks like.

#ex-wide("types-heads", fig-width: 76%)

== The input layer

`input` defaults to a flat plane with no thickness, which is what an image is.
Give it a `width` and a `depth` to make it a block instead. It is also the one
type with no outgoing arrow by default (section 10.9).

#ex-wide("types-input-plane", fig-width: 82%, fig-height: 5cm)

== Putting the types together

Nothing below sets a size, a colour or a gap. It is types, labels and channel
counts only, and it is already a readable figure.

#ex-wide("types-classifier", fig-width: 100%, fig-height: 7.5cm)

= Sizing a block

A block has three dimensions. `height` and `depth` are the spatial extent of the
tensor; thickness is `width` or `widths`, and conventionally means channel
count.

#opt("height", default: "5, varies by type")[Vertical extent, in canvas units.]
#opt("depth", default: "5, varies by type")[Extent along the projection. `0` draws a flat rectangle.]

#ex("size-height", fig-width: 88%)
#ex("size-depth", fig-width: 88%)

== Thickness

#opt("width", default: "varies", applies: [`input`, `deconv`, `concat`, `convsoftmax`, `softmax`, `output`, `custom`])[
  A single thickness.
]
#opt("widths", default: "(1,)", applies: [`conv`, `convres`, `custom`])[
  An array of thicknesses, drawing one band per entry inside a single block.
]

#ex("size-width", fig-width: 88%)

`widths` is how a stage of two or three convolutions at one resolution is
normally drawn: one block, banded, rather than three blocks in a row.

#ex("size-widths-count", fig-width: 88%)

The bands need not be equal, which is how you draw a bottleneck:

#ex-wide("size-widths-uneven", fig-width: 52%, fig-height: 4.6cm)

#warn[
  `width` and `widths` are different options and not interchangeable. No type
  accepts both except `custom`, and using the wrong one is an error naming the
  other.
]

== Flat layers

#ex("size-2d", fig-width: 62%)

== Sizing from the tensor shape

Stating three numbers per block and keeping them consistent across a pyramid is
the tedious part of drawing one of these, and the part that rots when the model
changes.

#opt("shape", default: "none")[
  The tensor this layer produces, as `(channels, height, width)`. Height, depth
  and width are derived from it.
]

#ex-wide("size-shape-basic", fig-width: 76%, fig-height: 5cm)

Across a pyramid it is the whole geometry:

#ex-wide("size-shape-pyramid", fig-width: 88%, fig-height: 7.5cm)

Both axes are logarithmic:

$ "height", "depth" = 1.2 log_2("spatial") - 3.2, quad "width" = 0.075 log_2("channels") $

Linear spatial extent does not work. Across a 640-to-20 pyramid it puts the
smallest block at a quarter of a unit against 8 for the input, which is
invisible.

=== Shape supplies defaults, not values

Anything you state explicitly wins, field by field, so a block can take its
width and depth from its shape while its height is forced:

#ex("size-shape-override", fig-width: 88%)

=== Changing the mapping

#opt("shape-scale", default: "(spatial: (1.2, -3.2), channels: (0.075, 0.0))", applies: [`draw-network`])[
  Slope and intercept for each axis, applied to the base-2 logarithm. The
  constants are absolute rather than normalised across a figure, so the same
  shape gives the same size everywhere and two figures stay comparable.
]

#ex-wide("size-shape-scale", fig-width: 62%, fig-height: 5cm)

#note[
  Only `conv`, `convres` and `custom` take a derived width, because only those
  three use thickness to mean channel count. The others have a fixed thickness
  that says something else, and keep it.
]

== By hand against by shape

The same three blocks, written both ways. The first drifts the moment the model
changes; the second cannot.

#ex("size-by-hand", fig-width: 100%)
#ex("size-by-shape", fig-width: 100%)

= Spacing

#opt("offset", default: "auto")[
  The gap between this layer and the one before it. `auto` computes it from the
  drawing; a number states it directly.
]

#ex("spacing-default", fig-width: 88%)

Automatic spacing covers the previous block's isometric lean, adds a fixed strip
of white space, and widens where a connection descends into the gap.

== Why a constant offset fails

A block drawn in isometric projection leans right by `depth × depth-multiplier`.
A gap narrower than that lean buys no visible space at all: the next block is
drawn inside the previous one's sheared face, and the arrow between them
disappears behind it.

#ex-wide("spacing-tight-bad", fig-width: 100%, fig-height: 5cm,
  caption: [`offset: 1.2` against a depth-7 block, whose lean is 2.1.])

#ex("spacing-tight-good", fig-width: 100%,
  caption: [The same blocks with the offsets removed.])

That is why `auto` is the default. A constant that works for one size of block
fails for the next, and a figure that computes its own offsets ends up restating
the size pyramid twice, with nothing to catch the two copies drifting apart.

== Spacing by hand

A number overrides the automatic gap for one layer, and means what it always
meant:

#ex("spacing-numbers", fig-width: 88%)

Two helpers are exported for figures that do compute their own geometry:

#snippet(```typ
depth-shear(6)
min-clear-offset(6)
```)

A connection descending between two blocks arrives at the midpoint of the arrow
joining them, so it clears the lean only when half the offset exceeds it. That
is what `min-clear-offset` returns, and what automatic spacing applies for you:

#ex-wide("spacing-conn-widens", fig-width: 82%)

#note[
  Both helpers take a `depth-multiplier` argument, which must match the one
  passed to `draw-network`. The default multiplier of `0.3` has no exact binary
  representation, so `depth-shear(4.5)` is `1.3499999999999999`. Compare with a
  tolerance, if you compare at all.
]

== The white space constant

#opt("auto-gap", default: "0.55", applies: [`draw-network`])[
  How much visible white space an automatic offset adds, once the lean is
  covered.
]

#ex("spacing-gap-narrow", fig-width: 92%)
#ex("spacing-gap-wide", fig-width: 92%)

= Labels

#opt("label", default: "none")[
  Text under the block. Any content, so markup and line breaks work.
]

#ex("label-basic", fig-width: 82%)
#ex("label-multiline", fig-width: 82%)

== Channel numbers

#opt("channels", default: "none")[
  Numbers along the top of the block, one per band. At most one extra entry is
  allowed, and becomes the diagonal axis label. Strings work as well as numbers.
]

#ex("label-channels-bands", fig-width: 82%)

The extra entry is where spatial resolution usually goes:

#ex-wide("label-channels-axis", fig-width: 88%, fig-height: 5cm)

An empty string labels the axis and nothing else:

#ex-wide("label-channels-strings", fig-width: 82%, fig-height: 5cm)

#warn[
  More than one extra entry is an error from inside the package, reported as an
  array index out of bounds rather than as a message about `channels`. If you
  see that, count your bands.
]

== Axis names

#opt("xlabel", default: "none", applies: [`conv`, `convres`, `custom`])[]
#opt("ylabel", default: "none", applies: [`conv`, `convres`, `custom`])[]
#opt("zlabel", default: "none", applies: [`conv`, `convres`, `custom`])[
  Names for the three axes of one block, for the figure that has to explain the
  projection itself.
]

#ex("label-axes", fig-width: 52%, fig-height: 5cm)

== Labelling the arrow between two blocks

#opt("connection-label", default: "none")[
  Text on the axis arrow *after* the layer that declares it.
]

#ex("label-connection", fig-width: 82%)

== When labels collide

Labels sit at a fixed spot beneath each block, so long labels on closely spaced
blocks overlap:

#ex-wide("label-crowded-bad", fig-width: 88%, fig-height: 5cm)

There are three fixes, and which to reach for depends on how crowded the row is.
Rotating trades horizontal space, which is scarce, for vertical space, which is
usually free:

#ex-wide("label-crowded-orient", fig-width: 88%, fig-height: 5cm)

Dropping one label to a second row clears a single collision without rotating
anything:

#ex-wide("label-crowded-stagger", fig-width: 88%, fig-height: 5cm)

Anchoring the outer labels by their facing edges fans them sideways:

#ex-wide("label-anchor-fan", fig-width: 88%)

== The placement options

#opt("label-orient", default: "\"horizontal\"")[
  `"horizontal"`, `"diagonal"` or `"vertical"`. Each preset pairs its angle with
  the anchor that places it correctly, so a diagonal label points its end at its
  own block and a vertical one hangs centred beneath it. Any other value is an
  error.
]

#ex-wide("label-orient-compare", fig-width: 76%)

#opt("label-dx", default: "0")[Horizontal shift.]
#opt("label-dy", default: "0")[Vertical shift.]
#opt("label-anchor", default: "set by the preset")[
  Which point of the text is pinned to the label position. Labels anchor on
  their baseline rather than their bounding box, so a label with descenders sits
  level with one without. Use `"base-east"` and `"base-west"` to anchor
  horizontally while keeping that alignment.
]
#opt("label-angle", default: "0deg")[
  An arbitrary angle. Setting both this and `label-orient` is an error, since
  the right anchor for an arbitrary rotation depends on where you want the text.
]

#ex("label-angle-free", fig-width: 52%, fig-height: 4.6cm)

= Images inside blocks

#opt("image", default: "none")[
  Content drawn on the block's face, sheared to match the projection. The string
  `"default"` uses the bundled photograph. Any content works, not only images.
]

#ex("image-input-default", fig-width: 72%)

Any Typst image:

#ex-wide("image-input-custom", fig-width: 54%, fig-height: 5cm)

Nothing restricts this to the input. Putting a picture on a later block is how a
figure shows what a stage produces:

#ex-wide("image-on-block", fig-width: 72%)

== Content that is not an image

#ex-wide("image-content-symbol", fig-width: 72%, fig-height: 5cm)
#ex-wide("image-content-text", fig-width: 72%, fig-height: 5cm)

= Colour

#opt("fill", default: "set by the type and palette")[
  Block colour. Edge and band colours are derived from it, so a recoloured block
  stays internally consistent.
]
#opt("opacity", default: "0.7, varies by type")[How solid the block is.]

#ex("color-fill-compare", fig-width: 100%)
#ex("color-opacity-compare", fig-width: 100%)

== Activation bands

A darker band at the end of a convolution conventionally marks the activation.

#opt("show-relu", default: "false", applies: [`draw-network`; `conv`, `convres`, `custom`])[
  Turn bands on for a whole figure with the `draw-network` argument, and
  override on any one layer.
]
#opt("bandfill", default: "derived from fill", applies: [`conv`, `convres`, `custom`])[
  Band colour. Undeclared, it is derived from the layer's own fill, so a
  recoloured block gets a matching band rather than one from the palette.
]

#ex("color-relu-off", fig-width: 66%)
#ex("color-relu-on", fig-width: 66%)
#ex-wide("color-bandfill", fig-width: 66%)

== Palettes

#opt("palette", default: "\"warm\"", applies: [`draw-network`])[`"warm"` or `"cold"`.]

#ex("palette-warm", fig-width: 88%)
#ex("palette-cold", fig-width: 88%)

A palette sets defaults only. Any `fill` you state wins, so a figure can sit on
a palette and still recolour three blocks --- or ignore the palette entirely and
put the whole figure on a scheme of your own:

#ex-wide("color-brand", fig-width: 88%)

= Blocks of your own

`custom` is the generic block: no meaning attached, every option available.

#ex-wide("custom-basic", fig-width: 92%, fig-height: 5cm)

It takes bands and an activation band exactly as a convolution does:

#ex-wide("custom-bands", fig-width: 52%, fig-height: 5cm)

#opt("legend", default: "the type's default name")[
  What this layer is called in the legend. Layers sharing a legend name appear
  once, so a colour used by four blocks produces one entry.
]

#ex-wide("custom-legend", fig-width: 76%)

== Building a vocabulary

A `custom` layer with its options fixed is a function returning a layer, so
your own block types are a few lines. This is the intended way to draw something
the package has no name for --- attention, a gate, a state-space block --- rather
than repurposing a type that means something else to a reader.

#ex-wide("custom-vocabulary", fig-width: 82%)

Once the vocabulary exists, a figure is written in it:

#ex-wide("custom-transformer", fig-width: 88%, fig-height: 7.5cm)

= Connections

Arrows along the main axis are drawn for you. Anything else --- a skip, a
residual add, a lateral feed, an auxiliary path --- goes in `connections`, as a
list of routes between two named layers.

#opt("from", default: "required")[Name of the layer the route leaves.]
#opt("to", default: "required")[Name of the layer it arrives at.]

#ex-wide("conn-basic", fig-width: 82%)

== Routing modes

#opt("mode", default: "\"air\"")[
  `"air"` runs over the top of the stack, `"flat"` underneath, `"depth"` along
  the projection's own axis.
]

#ex-wide("conn-mode-air", fig-width: 82%, fig-height: 5cm)
#ex-wide("conn-mode-flat", fig-width: 82%, fig-height: 5cm)
#ex-wide("conn-mode-depth", fig-width: 82%, fig-height: 5cm)

== Lane heights

#opt("pos", default: "auto")[
  How far the route sits from the centre axis. `auto` ranks routes by how far
  they reach, so a route spanning more blocks sits higher and a longer route
  always arcs over a shorter one instead of crossing it.
]

#ex-wide("conn-lanes-auto", fig-width: 88%)

Routes of equal reach share a height. Where two of them overlap, the second goes
to the opposite side of the axis at the same height, rather than being pushed
further out than its reach warrants:

#ex-wide("conn-lanes-overlap", fig-width: 88%)

A number overrides all of it for one route:

#ex-wide("conn-lanes-manual", fig-width: 62%, fig-height: 5cm)

#opt("lane-unit", default: "0.75", applies: [`draw-network`])[
  Spacing between automatic heights.
]
#opt("clearance", default: "0.7")[
  How far the lowest automatic route sits from the blocks.
]

#ex-wide("conn-lane-unit", fig-width: 88%)

== Where a route arrives

#opt("touch-layer", default: "false")[
  Arrive on the target block itself rather than on the axis arrow in front of
  it. The edge follows the routing mode: air lands on the top edge, flat on the
  bottom, depth on the left.
]

#ex-wide("conn-touch-compare", fig-width: 88%)

All three modes, arriving on the same block:

#ex-wide("conn-touch-modes", fig-width: 88%)

#note[
  A route arriving on the bottom or left edge has its final stretch drawn behind
  the block, because those edges are on the far side and the route genuinely
  passes underneath before reaching them. Blocks are semi-transparent, so it
  shows faintly rather than disappearing.
]

== Fanning several routes into one block

Two routes in the same mode would otherwise land on the same point, with their
arrowheads stacked.

#opt("arrive-offset", default: "auto")[
  Position along the arrival edge. `auto` spaces a whole fan evenly and leaves a
  lone arrival centred.
]

#ex-wide("conn-arrive-auto", fig-width: 88%)

Routes are grouped by the edge they land on, then spread across it: `k` routes
divide the edge into `k + 1` intervals and sit at the interior boundaries, so
the outermost pair is inset rather than sitting on the corners. They are ordered
by where each route starts, so a fan does not cross itself, and adding a route
respaces the rest.

A number places one arrival yourself, measured along the edge:

#ex-wide("conn-arrive-manual", fig-width: 82%)

#note[
  The offset runs *along the edge*, not in $x$. The top and bottom edges of a
  block's west side follow the isometric depth direction, so shifting
  horizontally would walk the arrival off the block. The edge is
  $sqrt(2) dot "depth" dot "depth-multiplier"$ for top and bottom arrivals and
  the block height for left ones, so a deeper block accommodates a wider fan.
]

== Telling routes apart

A residual add, a concat feed and an auxiliary supervision path are different
things, and by default they all look the same.

#opt("color", default: "palette")[Paint for the line and its arrowheads.]
#opt("dash", default: "none")[Any Typst dash pattern, e.g. `"dashed"`, `"dotted"`.]
#opt("thickness", default: "1")[
  Multiplies the palette stroke width, so it composes with `stroke-thickness`
  rather than fighting it.
]

#ex-wide("conn-style-compare", fig-width: 88%)

Arrowheads take the line colour, since a coloured line with black arrowheads
reads as a bug rather than a choice.

== Routes in the legend

#opt("legend", default: "none")[
  Adds a line-sample legend entry rather than a colour swatch, since what
  distinguishes a route is its stroke and not a fill. Routes sharing a name
  appear once.
]
#opt("main-legend", default: "none", applies: [`draw-network`])[
  Names the automatic axis arrows. Without it a legend can explain every skip in
  a figure and say nothing about the arrows carrying the forward pass.
]

#ex-wide("conn-legend", fig-width: 76%)

== Labelling a route

#opt("label", default: "none")[Text on the route.]

#ex-wide("conn-label", fig-width: 76%)

== Suppressing an axis arrow

#opt("show-connection", default: "true; false on input")[
  Whether to draw the axis arrow *after* this layer.
]

#ex("conn-noarrow", fig-width: 88%)

The input layer is the one that defaults to `false`, which is why an image
usually sits detached. Set it `true` to join it up:

#ex("conn-input-arrow", fig-width: 76%)

== Two composites

A residual block is a `sum` node plus one route:

#ex-wide("conn-residual-block", fig-width: 92%, fig-height: 7cm)

An encoder-decoder is a size pyramid plus two routes arriving on their targets:

#ex-wide("conn-unet-skips", fig-width: 92%, fig-height: 7cm)

= Groups and repeats

Backbone, neck and head are the phrases anyone uses out loud to explain one of
these figures. `groups` draws them, as labelled brackets under a span of layers.

#opt("from", default: "required")[First layer of the span, by name.]
#opt("to", default: "required")[Last layer of the span, inclusive. May be the same layer.]
#opt("label", default: "none")[Bracket text.]

#ex-wide("groups-basic", fig-width: 88%)

A group of one is allowed and common, since a head is often a single block:

#ex-wide("groups-single", fig-width: 82%)

The bracket covers the drawn footprint rather than the front faces, so it sits
under the whole block including its lean, and its ends are inset slightly so two
adjacent groups read as two rather than as one continuous rule.

== Tinting and stacking

#opt("color", default: "grey")[Tints one bracket.]
#opt("offset", default: "1.15")[
  Pushes the bracket further down, which is how you stack a group that encloses
  other groups onto its own row.
]

#ex-wide("groups-color", fig-width: 88%)
#ex-wide("groups-stacked", fig-width: 88%)

Brackets are placed below everything else in the figure, including a route
running underneath the stack, so the two never collide:

#ex-wide("groups-clear-routes", fig-width: 82%)

== Repeated blocks

Depth-scaled models stack the same block several times. Writing that as extra
entries in `widths` makes it *look* repeated, but the package has no idea it is:
it cannot label the repeat or bracket it, and the figure claims one wide block
rather than several.

#opt("repeat", default: "1")[
  Marks the block as repeated in series. It is drawn once, with a bracket above
  it carrying the count. Ignored on `pool`, `unpool` and `sum`.
]

#ex("repeat-basic", fig-width: 82%)

The count costs no horizontal space, so it stays legible at any depth:

#ex("repeat-counts", fig-width: 88%)

#note[
  Ghosted copies were tried first and rejected. An outline behind the block
  reads as an empty box rather than as another one of the same block, and
  drawing N of them is either misleading about the count or unreadable once N is
  large. A bracket states the count instead of depicting it.
]

=== The pool pitfall

`repeat` describes one layer entry, not a run of them. Putting it on a
convolution that has a pool attached reads as though the pool repeats too:

#ex("repeat-pool-bad", fig-width: 66%)

Split it instead. Let the repeat cover the plain convolutions, and draw the last
one on its own with the pool attached:

#ex-wide("repeat-pool-good", fig-width: 82%, fig-height: 5cm)

For the same reason a repeated *pair*, such as attention-then-MLP, cannot be
expressed with `repeat` at all. Section 15.5 shows what to do instead.

== A composite

#ex-wide("groups-composite", fig-width: 96%, fig-height: 7cm)

= Parallel branches

`draw-network` advances one cursor along one axis, so anything genuinely
parallel --- two detection heads, the two paths inside a CSP block, a two-stream
fusion --- would have to be collapsed into a single block with arrows pointed at
it. A `branch` entry draws it as it is.

#opt("branches", default: "required")[
  An array of layer arrays, one per parallel path. Each is walked exactly as the
  trunk is, so anything that works on the trunk works inside a branch.
]

#ex-wide("branch-two", fig-width: 74%)

== Separation and count

#opt("spread", default: "6")[
  Separation between paths, centred on the trunk. An odd count puts one path on
  the trunk line; an even count leaves it empty.
]
#opt("lead", default: "2.0")[How far the fan-out and rejoin arrows run.]
#opt("entry-gap", default: "0")[
  Extra flat run before the fan splits, without changing `lead` --- more
  approach space, same fan shape. Negative removes run.
]
#opt("exit-gap", default: "0")[
  The same after the rejoin, before the next block.
]

#ex-wide("branch-three", fig-width: 74%)
#ex-wide("branch-spread", fig-width: 74%)

Branches need not be the same length. The rejoin waits for the longest rather
than cutting the others short:

#ex-wide("branch-uneven", fig-width: 82%)

A filled dot marks each point where flow divides or meets, and where a tooth
leaves a spine that passes through. Merging routes terminate at the dot, and a
single arrow leaves it for the next block.

== Stacking along the projection

#opt("spread-mode", default: "\"vertical\"")[
  `"depth"` stacks the paths along the projection's 45-degree axis instead of
  straight up, so they read as parallel copies sitting behind one another.
]
#opt("rejoin-lead", default: "the value of lead")[
  Widens the rejoin side alone. Depth mode often wants this, since its return
  spine descends past each block's lower-right corner, which is exactly where
  diagonal dimension labels sit.
]

#ex-wide("branch-depth", fig-width: 74%)

The fan-out and rejoin become two parallel spines with horizontal teeth --- a
parallelogram, rather than the mirrored hexagon a vertical split produces.
Neither 45 is a free angle: it is the one the projection already uses. This is
the natural way to draw a set of detection heads:

#ex-wide("branch-depth-three", fig-width: 82%, fig-height: 7.5cm)

== Open at one end

#opt("open", default: "none")[
  `"start"` draws no fan-out, `"end"` no rejoin. A branch with nothing before it
  is open at the start by definition.
]

A branch open at the start is how a multi-input network begins:

#ex-wide("branch-open-start", fig-width: 78%)

Open at the end, one trunk fans out into independent outputs:

#ex-wide("branch-open-end", fig-width: 78%)

== Nesting

A branch may contain branches, since walking a branch is the same operation as
walking the trunk.

#ex-wide("branch-nested", fig-width: 74%, fig-height: 7cm)

== Branches are not a separate world

Named layers inside a branch join the same table the trunk uses, so connections,
groups and automatic lane ranking all reach into them. A group naming any layer
inside a branch widens to the branch's whole drawn extent, plumbing included.

#ex-wide("branch-connections", fig-width: 88%, fig-height: 7.5cm)

== Two composites

#ex-wide("branch-two-stream", fig-width: 88%, fig-height: 8cm)

#ex-wide("branch-inception", fig-width: 76%, fig-height: 7cm)

= The figure as a whole

== Legends

#opt("show-legend", default: "false", applies: [`draw-network`])[
  Collects every layer type used into a legend, in order of first appearance.
]
#opt("legend-title", default: "\"Layers\"", applies: [`draw-network`])[Heading of the box.]

#ex("legend-basic", fig-width: 88%)
#ex-wide("legend-names", fig-width: 76%)

Layer swatches and route samples share one box. The sample column widens when
any route entry is present, so a dash pattern has room to read, and the layer
swatches widen with it so nothing floats away from its label:

#ex-wide("legend-mixed", fig-width: 82%)

== Fitting the page

#opt("scale", default: "100%", applies: [`draw-network`])[
  Shrinks or grows the whole figure, text included.
]

#ex("scale-100", fig-width: 100%)
#ex("scale-55", fig-width: 100%)

A long network is wider than a page at its natural size, and `scale` is the
first thing to reach for. If it makes the text too small to read, the next thing
to try is `label-orient: "diagonal"` (section 6.5), which usually buys back
enough horizontal space to raise the scale again.

== Line weight

#opt("stroke-thickness", default: "1", applies: [`draw-network`])[
  Multiplies every stroke in the figure. Connection `thickness` multiplies on
  top of this.
]

Worth raising when a figure is reduced for a two-column layout, where hairlines
start dropping out at print resolution:

#ex("stroke-thin", fig-width: 82%)
#ex("stroke-thick", fig-width: 82%)

== The projection

#opt("depth-multiplier", default: "0.3", applies: [`draw-network`])[
  How far blocks lean, which is the strength of the isometric projection. It
  also changes what `depth-shear` and `min-clear-offset` return, so pass the
  same value to those.
]

#ex("depth-flat", fig-width: 76%)
#ex("depth-strong", fig-width: 76%)

= Neuron diagrams

Everything so far has drawn a network as blocks. The other canonical figure
draws it as neurons --- a circle per unit, an edge per weight, the picture every
introduction to the subject opens with. `draw-mlp` draws that figure. It is a
second renderer, not a new mode: it shares the package's constructors,
validation and palettes and nothing else, it opens its own canvas, and how it
composes with `draw-network` in a single figure is deliberately not yet
decided.

#ex("mlp-tier0", fig-width: 80%,
  caption: [Four counts, no other options. This is the whole program.])

The zero-configuration output is the textbook look: circles, plain grey edges
drawn behind the nodes, no arrowheads, no bias nodes, and the input, hidden and
output roles told apart by fill. Every default follows a documented convention,
and everything past the defaults is an option below.

#note[
  Indexing is 1-based everywhere. Layers count left to right and neurons top to
  bottom within a layer; under `direction: "up"` layers run bottom to top and
  neurons left to right. Every index an option takes --- `dropped`, `exclude`,
  `edge-labels`, weight matrices, `mlp-edge` endpoints --- means the *true*
  index of that neuron, whether or not its column is collapsed.
]

== Four tiers

The layer list is an array whose entries are integers, `mlp-layer(..)` values
or `mlp-gap(..)` values, mixed freely. An integer `n` is shorthand for
`mlp-layer(n)`, and a plain dictionary is an error, exactly as in
`draw-network`. The first tier past bare counts is figure-wide options:

#ex("mlp-tier1", fig-width: 88%,
  caption: [Collapsed columns state their true width; bias nodes appear above
    each feeding layer.])

The second is per-layer constructors:

#ex-wide("mlp-tier2", fig-width: 76%, fig-height: 5cm)

And the third is functions over indices. Weights come from a file, labels from
a formula, styles from a predicate --- the escape hatches are callbacks, not
enumerations:

#ex-wide("mlp-tier3", fig-width: 56%, fig-height: 6.5cm,
  caption: [`w.json` holds one matrix per inter-layer gap. Positive weights are
    blue, negative red and dashed, and magnitude is thickness.])

Everything below is one of those tiers in detail.

== Writing a column

#opt("count", default: "required", applies: [`mlp-layer`])[
  The layer's true width, as a positional integer of at least 1. Everything
  else about a column is named.
]
#opt("name", default: "auto", applies: [`mlp-layer`])[
  A reference for `mlp-edge`, never printed. Layers auto-name themselves
  `"l1"`, `"l2"`, ... by position and gaps `"g1"`, `"g2"`, ...; a user name
  replaces the auto name, shares its namespace, and collides loudly.
]

A gap column stands for elided depth --- the "six more of these" of a network
too deep to draw in full:

#ex-wide("mlp-gap", fig-width: 82%)

#opt("label", default: "none", applies: [`mlp-gap`])[
  Caption in the label row, where the count usually goes.
]
#opt("pitch", default: "0.6 × layer-pitch", applies: [`mlp-gap`])[
  The width the gap column occupies.
]

A gap has no neurons. It cannot start or end an edge, it cannot sit first or
last, and it breaks adjacency: the edge stubs entering and leaving it fade out
rather than faking a connection across the elision. For the same reason a layer
followed by a gap draws no bias node.

== Layout

#opt("node-size", default: "0.17")[
  Node radius, in canvas units. Half the side length for squares. Also an
  `mlp-layer` option, so one layer can be drawn larger.
]
#opt("node-pitch", default: "0.6")[Spacing between neuron centers within a layer.]
#opt("layer-pitch", default: "2.2")[Spacing between layer columns.]

#ex("mlp-pitch", fig-width: 76%)

Unequal layers are always centered on the flow axis. That is not a knob:
every published version of this figure does it, and a version that does not
reads as a mistake.

#opt("unit", default: "1cm", applies: [`draw-mlp`])[
  The canvas unit. It scales the geometry; text sizes are absolute, so a
  smaller unit buys a denser figure with the same size labels.
]
#opt("title", default: "none")[Centered above the figure.]
#opt("debug", default: "false")[
  Draws the slot grid and the caption baseline rows in faint garnet. Useful
  for exactly one thing, which is seeing why something landed where it did.
]

#ex("mlp-debug", fig-width: 76%)

The dashed rows under the columns are shared, figure-wide baselines: one row
for labels (with `sub` lines directly beneath), one for activation captions,
one for count badges, in that order. Captions of a short column and a tall one
sit level because the rows belong to the figure, not to the column, and a row
that is empty for the whole figure takes no space.

== Wide layers collapse

A 4--1024--10 classifier is a real network and an impossible figure. Drawing
every neuron of a wide layer is the failure mode:

#ex-wide("mlp-wide-bad", fig-width: 40%, fig-height: 7cm,
  caption: [24 neurons drawn honestly, with `cutoff: none`. The figure is all
    layer and no network.])

#opt("cutoff", default: "10")[
  A layer with `count > cutoff` collapses: its first and last neurons drawn, a
  vertical ellipsis between them, and a badge stating the true count. `none`
  disables collapsing for the figure.
]

#ex("mlp-wide-good", fig-width: 72%,
  caption: [The same network with the default cutoff.])

#opt("collapse-to", default: "5")[
  How many slots a collapsed column occupies --- odd and at least 3, since the
  middle slot holds the ellipsis. At `5`, the drawn neurons are 1, 2,
  count−1 and count. `cutoff` must exceed `collapse-to`, since collapsing a
  layer below that would not shorten it, and violating the pair is an error.
]

#ex("mlp-collapse-to", fig-width: 72%)

#opt("show-all", default: "false", applies: [`mlp-layer`])[
  Exempts one layer from the figure `cutoff`.
]

#ex("mlp-show-all", fig-width: 66%)

#opt("count-badges", default: "auto")[
  `auto` badges collapsed columns only; `true` badges every column; `false`
  none. A collapsed column always states its true width unless you say
  `false`, because a figure that hides forty neurons and does not say so is
  lying about the model.
]

#ex("mlp-badges", fig-width: 72%)

Edges attach only to drawn neurons. Naming an elided neuron --- in an
`mlp-edge` endpoint, say --- is an error that lists the indices that *are*
drawn.

== Color

#opt("palette", default: "\"blues\"")[
  `"blues"`, `"classic"`, `"brand"`, `"greys"`, `"teal"`, `"lilaq"`,
  `"white"`, `"warm"`, `"cold"`, or a dictionary with
  keys among `input`, `hidden`, `output`, `bias` and `accent`, plus the
  optional ink keys `input-text`, `hidden-text`, `output-text` and
  `bias-text` described below. A partial dictionary overlays the blues
  palette; an unknown palette name is an error rather than a silent fallback.
]

The default is `blues` --- light input, mid hidden, dark output, a single-hue
ColorBrewer ladder, and the fills every figure in this chapter wears unless it
says otherwise. The three roles are steps in luminance rather than changes of
hue, so they stay apart when the figure is printed black-and-white or
photocopied. `classic` is the green-input, blue-hidden, red-output TikZ
convention most published MLP figures copy; its roles sit at near-equal
luminance, which is exactly what a grayscale printer collapses, so it is a
named option here rather than the default. `brand` is the package's house
scheme in sand and grey with a garnet accent. `greys` is the ColorBrewer
Greys ladder, pure grayscale for a venue that prints nothing else. `teal`
keeps that grey ladder but moves the output to teal, so exactly one hue
pops. `lilaq` takes the first colors of the lilaq plotting package's default
cycle, so an MLP can sit beside lilaq plots without a second color language.
`white` keeps every fill white with a black accent --- the uncolored
line-art figure textbooks print, its roles told apart by position and labels
alone. `warm` and `cold` are derived from the isometric block palettes, so a
document can keep its blocks and its neurons on one scheme.

#ex("mlp-palette-greys", fig-width: 76%)
#ex("mlp-palette-teal", fig-width: 76%)
#ex("mlp-palette-lilaq", fig-width: 76%)
#ex("mlp-palette-white", fig-width: 76%)
#ex("mlp-palette-warm", fig-width: 76%)
#ex("mlp-palette-cold", fig-width: 76%)

#opt("fill", default: "role color", applies: [`mlp-layer`])[
  Node fill for one layer. The role assignment is positional: first layer
  input, last output, the rest hidden.
]

#ex-wide("mlp-palette-custom", fig-width: 62%)

The named palettes are exported as `mlp-palettes`, so a scheme of your own can
start from one instead of from nothing:

#ex("mlp-palette-derive", fig-width: 76%)

Whatever the palette, everything drawn inside a node --- an inside label, the
$Sigma$ and $f$ of a split node, an in-node glyph, value text, the inside
bias label, the dropout X --- picks black or white by the perceived luminance
of the node's effective fill, so a dark scheme never buries its own ink. A
palette dictionary can pin that ink per role instead, through the optional
keys `input-text`, `hidden-text`, `output-text` and `bias-text`. A pinned
color applies only while the node still wears the palette's own role fill; a
per-layer `fill`, a `node-style` fill or a `values` ramp falls back to the
automatic flip, since ink chosen against one fill cannot be trusted against
another. No built-in palette sets these keys.

#ex("mlp-palette-text", fig-width: 66%,
  caption: [The hidden fill is dark, so its ink would flip to white; the
    `hidden-text` key pins it instead. The other roles keep the automatic
    choice --- black on the light input, white on the dark blues output.])

=== Values as fill

#opt("values", default: "none", applies: [`mlp-layer`])[
  An array of floats in 0..1, one per neuron. The fill becomes a ramp from
  white to the layer's role color --- the activations-as-brightness view
  3Blue1Brown made standard.
]
#opt("show-value-text", default: "false", applies: [`mlp-layer`])[
  Prints the value, two decimals, inside the node. Requires `values`, and wins
  over an inside node label. Text flips to white on dark fills.
]

#ex("mlp-values", fig-width: 66%)

== Node shapes and the input

#opt("node-shape", default: "\"circle\"")[
  `"circle"`, `"square"` or `"split"`, for the whole figure. The per-layer
  `shape` option takes the same values and wins.
]
#opt("shape", default: "figure node-shape", applies: [`mlp-layer`])[]

`split` is the classic summation-then-squash view of a unit: a slightly larger
circle with a vertical divider, $Sigma$ in the left half, the activation curve
(or $f$ when the layer has none) in the right.

#ex("mlp-shapes", fig-width: 66%)

#opt("node-stroke", default: "(paint: black, thickness: 0.6pt)")[
  The node outline, for the whole figure; per-layer `stroke` wins.
]
#opt("input-style", default: "\"nodes\"")[
  `"square"` draws layer 1 as squares, the AIMA convention for
  values-not-units. `"arrows"` replaces the layer-1 nodes with labelled stub
  arrows into layer 2, perceptron style; the layer-1 `count` still says how
  many.
]

#ex("mlp-input-square", fig-width: 66%)
#ex("mlp-input-arrows", fig-width: 66%)

== Node labels

#opt("node-label", default: "none")[
  `none`, `auto`, or a function. At the figure level the function takes
  `(l, i)`; on a layer it takes `(i)` and wins. `auto` is role-based math over
  true indices: $x_i$ on the input, $h_i^((k))$ on hidden layer $k$ (plain
  $h_i$ when there is only one), $hat(y)_i$ on the output --- so a collapsed
  layer labels its last two drawn neurons $n-1$ and $n$, not 4 and 5.
]

#ex("mlp-node-labels", fig-width: 76%)

#opt("node-label-pos", default: "\"inside\"", applies: [`mlp-layer`])[
  `"inside"` shrinks the label to fit the node; `"left"` and `"right"` set it
  beside, which is where a label goes once nodes carry glyphs or values.
]

#ex("mlp-node-label-pos", fig-width: 72%)

Inside labels yield gracefully: value text wins over an inside label, and the
glyph activation style and the split shape suppress inside labels entirely
rather than overprinting a curve.

== Marking neurons

Four per-layer index arrays mark neurons, and a neuron may appear in at most
one of them --- overlap is an error, not a merge.

#opt("dropped", default: "()", applies: [`mlp-layer`])[
  An X through the node and its edges omitted --- the dropout figure as
  Srivastava et al.\ drew it.
]
#opt("dimmed", default: "()", applies: [`mlp-layer`])[
  The node and its edges at reduced opacity. De-emphasis without deletion.
]
#opt("highlighted", default: "()", applies: [`mlp-layer`])[
  An accent ring around the node, its edges at full opacity. How you trace one
  path through a network.
]
#opt("exclude", default: "()", applies: [`mlp-layer`])[
  Not drawn at all, edges omitted. Referring to an excluded neuron from an
  edge endpoint is an error.
]

#ex("mlp-states", fig-width: 66%,
  caption: [In the hidden layer: neuron 2 dropped, 4 dimmed, 5 highlighted,
    and 6 excluded --- the column is one node shorter than its count.])

#opt("node-style", default: "none", applies: [`mlp-layer`])[
  A function from neuron index to a dictionary of `fill`, `stroke`, `size`,
  `shape` --- or `none` to leave the neuron alone. Applied last, after every
  other node option.
]

#ex("mlp-node-style", fig-width: 72%)

== Edges

#opt("edge-stroke", default: "(paint: #5C5C5C, thickness: 0.4pt)")[
  The base stroke of every adjacent-pair edge, before opacity.
]
#opt("edge-opacity", default: "50%")[
  Applied to the stroke paint. Edges draw before nodes and the fan of a dense
  layer overlaps itself; at partial opacity it reads as texture rather than
  ink.
]

#ex("mlp-edge-stroke", fig-width: 76%)

#opt("arrows", default: "\"none\"")[
  `"all"` puts a small stealth head on every inter-layer edge. The textbook
  default is none: flow is left to right and saying so ninety-six times adds
  clutter, not information.
]

#ex("mlp-arrows", fig-width: 72%)

#opt("io-stubs", default: "false")[
  `true`, `"in"` or `"out"`: short stub arrows entering layer 1 and leaving
  layer L, one per drawn neuron. The input side is suppressed under
  `input-style: "arrows"`, which already draws them.
]
#opt("stub-labels", default: "auto")[
  `auto` labels in-stubs $x_i$ and out-stubs $hat(y)_i$; `none` labels
  nothing; a function `(side, i)` labels however you like, with `side` one of
  `"in"` and `"out"`.
]

#ex("mlp-io-stubs", fig-width: 72%)
#ex("mlp-stub-labels", fig-width: 72%)

#opt("edge-filter", default: "none")[
  A predicate `(l, i, j)` over the adjacent-pair edge set --- gap `l` sits
  between layers `l` and `l+1`, `i` is the source neuron, `j` the target.
  Returning `false` drops the edge. Sparse connectivity as a function rather
  than an enumeration.
]

#ex("mlp-edge-filter", fig-width: 72%,
  caption: [Full fan into the first gap, one-to-one in the second.])

#opt("edge-labels", default: "()")[
  An array of `(l: .., i: .., j: .., label: ..)` dictionaries naming edges to
  label; omitting `label` (or passing `auto`) typesets $w_(j i)^((l))$. This
  is deliberately per-edge: the convention is one representative label, not a
  hundred unreadable ones.
]

#ex("mlp-edge-labels", fig-width: 72%)

#opt("matrix-labels", default: "false")[
  `true` centers $W^((l))$ in each inter-layer gap, above the fan --- the
  Goodfellow compact annotation. A function `(l)` supplies your own; returning
  `none` skips a gap.
]

#ex("mlp-matrix-labels", fig-width: 76%)

== Weights

#opt("weights", default: "none")[
  An array of matrices, a function `(l, i, j)` returning a float, or
  `"random"`. When set, edge appearance encodes the values.
]

Matrix orientation is the $W x$ convention and worth stating precisely.
`weights.at(l - 1)` maps gap $l$, has `counts[l+1]` rows by `counts[l]`
columns, and entry $[j][i]$ is the weight of the edge from neuron $i$ of layer
$l$ into neuron $j$ of layer $l+1$. A mismatched matrix is an error stating
both the expected and the received shape.

#ex-wide("mlp-weights-explicit", fig-width: 56%, fig-height: 5.6cm)

#opt("weight-encode", default: "(\"color\", \"thickness\", \"dash\")")[
  Which channels carry the value: any subset of `"color"`, `"thickness"`,
  `"opacity"`, `"dash"`. With $t = min(|w| \/ "range", 1)$, color paints by
  sign, thickness interpolates `weight-thickness` by $t$, opacity runs 15% to
  100% by $t$ in place of `edge-opacity`, and dash draws negative edges
  dashed, positive solid.
]
#opt("weight-colors", default: "(positive: #0571B0, negative: #CA0020)")[
  The sign colors --- blue positive, red negative, the ColorBrewer endpoints
  the Playground and 3Blue1Brown made the convention. A partial dictionary
  overlays the default.
]
#opt("weight-range", default: "auto")[
  The $|w|$ that saturates the encoding. `auto` takes the maximum over the
  data: full matrices for the array form, collapsed entries included, so the
  visible encoding stays honest about the true scale; drawn edges only for
  the function and `"random"` forms.
]
#opt("weight-thickness", default: "(0.2pt, 1.1pt)")[
  Thickness at zero and at saturation.
]
#opt("seed", default: "42")[
  For `weights: "random"`. Typst has no random source, so the values are a
  deterministic hash of the seed and the edge indices --- the same seed always
  draws the same figure.
]

#ex("mlp-weights-random", fig-width: 82%)
#ex("mlp-weights-opacity", fig-width: 76%)

Sign carried by color alone does not survive a grayscale printer or every
reader's eyes. The `"dash"` member is the accessibility channel --- negative
edges render dashed, positive stay solid --- and it sits in the default set,
so the sign survives the photocopier without being asked for. Passing
`weight-encode` without the member draws every edge solid, for the occasional
dense fan where the dashes read as noise:

#ex("mlp-weights-dash", fig-width: 76%)

#note[
  Bias edges are not covered by `weights` --- those matrices describe $W$, not
  $b$ --- and `edge-filter` and `edge-style` do not see them either. Letting a
  weight matrix silently mis-size against `counts + 1` is the kind of trap
  this package exists to reject.
]

== Bias nodes

#opt("bias", default: "false")[
  A bias node above each of layers 1 to $L-1$, one `node-pitch` above the
  column's top slot, filled from the palette's `bias` role, with an edge to
  every drawn neuron of the next layer. Also an `mlp-layer` option, so one
  layer can opt out (or in).
]
#opt("bias-label", default: "[bias]")[
  The label on every bias node. `none` suppresses it.
]
#opt("bias-label-pos", default: "\"above\"")[
  Where the label sits. `"above"`, the default, renders it over the node in
  small grey text, where a word fits; `"inside"` is the classic in-node
  placement for short content like `$1$`.
]

#ex("mlp-bias", fig-width: 76%,
  caption: [`bias-label-pos: "inside"` restores the classic in-node $1$.])
#ex("mlp-bias-off", fig-width: 76%,
  caption: [`bias: true` on the figure, `bias: false` on layer 2.])

`bias: true` on the last layer is an error --- there is no next layer to feed
--- and a layer immediately followed by an `mlp-gap` draws none, since bias
edges across an elision would fake adjacency.

== Captions

#opt("label", default: "none", applies: [`mlp-layer`, `mlp-gap`])[
  The column's caption in the label row. Any content.
]
#opt("sub", default: "none", applies: [`mlp-layer`])[
  A second caption line, smaller and lighter, directly beneath the label.
]
#opt("layer-labels", default: "none")[
  `auto` captions the roles: "input", "hidden 1" ... "hidden k", "output"
  (just "hidden" when there is one). An array gives one entry per layer,
  `none` entries included. A per-layer `label` wins over both.
]

#ex("mlp-layer-labels", fig-width: 76%)
#ex-wide("mlp-captions-sub", fig-width: 66%)

#opt("label-pos", default: "\"below\"")[
  Which side of the columns the caption rows sit on. A `sub` still reads
  beneath its label either way.
]

#ex("mlp-label-pos", fig-width: 76%)

== Activations

#opt("activation", default: "none")[
  The figure-wide activation, applied to layers 2 to $L$; layer 1 never
  defaults to one. The per-layer `activation` wins, including `none` to
  exempt a layer and including layer 1 if you insist.
]
#opt("activation-style", default: "\"caption\"")[
  How activations are shown: `"caption"`, `"glyph"`, `"block"` or `"split"`.
]

`caption` typesets the name, small, in the activation baseline row. Any string
or content is accepted --- nothing errors here, because anything renders as
text:

#ex("mlp-act-caption", fig-width: 72%)

`glyph` draws the bare curve inside each neuron of the layer --- curve only, no
axes:

#ex("mlp-act-glyph", fig-width: 72%)

`block` draws one small transfer-function icon in the activation row under the
column --- the MATLAB/Hagan convention, placed where it cannot collide with
edges:

#ex("mlp-act-block", fig-width: 72%)

`split` forces the split node shape for layers with an activation --- $Sigma$
then the curve:

#ex("mlp-act-split", fig-width: 72%)

The full catalog, one silhouette per name:

#ex-wide("mlp-glyph-catalog", fig-width: 100%, fig-height: 3.4cm,
  caption: [`linear`, `heaviside`, `logistic` and `swish` are aliases of
    `identity`, `step`, `sigmoid` and `silu`. The three smooth kinks differ
    deliberately: `elu` saturates left, `softplus` is everywhere-smooth,
    `gelu` and `silu` dip below zero before the rise.])

`softmax` and `argmax` have no per-neuron curve --- the function couples the
whole layer --- so in any glyph-bearing style they render as a right-side
bracket spanning the layer, named beside it:

#ex("mlp-softmax", fig-width: 72%)

An activation name outside the catalog is an error under `"glyph"`, `"block"`
and `"split"`, and the error lists the catalog. Under `"caption"` it is just
text.

== Extra edges

Everything beyond the adjacent-pair fan --- a skip, a recurrent loop, one
restyled edge --- is an `mlp-edge(..)` in the figure's `edges` array. An
endpoint is `"name.index"` for one neuron, `"name"` for a whole layer, or the
positional forms `(layer, index)` and `(layer,)`. What the edge *is* follows
from its endpoints. An adjacent node pair restyles the existing edge rather
than duplicating it (and re-adds the single link if `edge-filter` removed it).
A non-adjacent node pair is a new arc routed above the network, or below with
`style: "arc-below"`. A non-adjacent layer pair is one layer-level skip arc,
column top to column top. An adjacent layer pair restyles every edge in that
gap. And `from` equal to `to`, layer-level, is a recurrent self-loop.

#ex-wide("mlp-skip", fig-width: 76%)

#opt("sum", default: "false", applies: [`mlp-edge`])[
  Terminates a layer-level skip in a small circled plus before the target
  layer --- the ResNet merge. On any other kind of edge it is an error.
]

#ex("mlp-recurrent", fig-width: 66%)

#ex-wide("mlp-edge-single", fig-width: 62%,
  caption: [An adjacent pair restyled and labelled, and a node-level skip
    routed underneath.])

#opt("style", default: "auto", applies: [`mlp-edge`])[
  `"straight"`, `"arc-above"`, `"arc-below"` or `"loop"`. `auto` picks
  straight for adjacent endpoints, an arc above for skips, a loop when the
  endpoints match.
]
#opt("paint", default: "edge default; accent for skips and loops", applies: [`mlp-edge`])[]
#opt("thickness", default: "edge default", applies: [`mlp-edge`])[]
#opt("dash", default: "none", applies: [`mlp-edge`])[]
#opt("opacity", default: "edge default; 100% for skips and loops", applies: [`mlp-edge`])[]
#opt("arrow", default: "true for skips and loops, false for adjacent", applies: [`mlp-edge`])[
  A stealth head at `to`.
]
#opt("label", default: "none", applies: [`mlp-edge`])[
  At the arc apex, or the midpoint of a straight edge.
]

#opt("edge-style", default: "none")[
  The last word on adjacent-pair edges: a function `(l, i, j)` returning a
  dictionary of `paint`, `thickness`, `dash`, `opacity` --- or `none` to leave
  the edge alone. Style precedence over an edge is base stroke, then weight
  encoding, then dimmed and highlighted states, then `mlp-edge` overrides,
  then this hook.
]

== Growing upward

#opt("direction", default: "\"right\"")[
  `"up"` is the Goodfellow/AIMA orientation: input at the bottom, output at
  the top. It is a coordinate swap after layout, so every option means what it
  meant. Captions move to the left of their rows, badges to the right, and
  `label-pos` is ignored.
]

#ex-wide("mlp-direction-up", fig-width: 34%, fig-height: 7.5cm)

== Embedding in a canvas

`draw-mlp` is exactly `canvas(length: unit, mlp-content(..))`, and
`mlp-content` is exported. Inside your own CeTZ canvas the figure is draw
content like any other, with the first column centered at the origin and the
flow axis on $y = 0$:

#ex-wide("mlp-embed", fig-width: 56%, fig-height: 5cm)

== Typos are errors here too

The MLP renderer keeps the package's validation contract: unknown options on
every constructor and on the figure, plain dictionaries, bad counts, gap
placement, name collisions, index ranges and the mutual exclusivity of the
marking arrays, `values` length, `cutoff` against `collapse-to`, palette names
and keys, glyph names when a glyph is required, weight shapes per gap,
`weight-encode` members, endpoint resolution, and `edge-labels` that name no
drawn edge. The voice is the same, `did-you-mean` included:

#snippet(```
error: unknown draw-mlp option "cutof" on the figure.
Did you mean "cutoff"? Options accepted here: activation,
activation-style, arrows, bias, bias-label, bias-label-pos, ...
```)

#ex("mlp-cutoff-fix", fig-width: 72%,
  caption: [The fix. One letter, and the figure it was always meant to be.])

#opt("`weights` matrix N (layers N -> N+1) must be R x C")[
  The matrix facing a gap has the wrong shape. The message states the
  expected and the received shape, and restates the target-major orientation
  while it is at it.
]
#opt("activation \"X\" on layer N has no glyph")[
  A glyph-bearing style needs a curve from the catalog; the message lists it,
  suggests the nearest name, and notes that under `"caption"` anything is
  text.
]
#opt("mlp-edge endpoint refers to \"X\", which is not the name of any layer")[
  A dangling endpoint, with a `did-you-mean` over the names that exist. Gaps,
  excluded neurons and elided neurons get their own messages, each saying why
  the endpoint cannot take an edge.
]

== A composite

Weights, bias, stubs, captions, a collapse and a title --- everything this
chapter covered, in one figure that is still eleven lines:

#ex-wide("mlp-composite", fig-width: 84%, fig-height: 8cm)

= Patterns

Everything here is built only from what the preceding chapters covered. These
are not architectures to copy so much as shapes to recognise: most figures are
one of them with different labels.

== A classifier

Types, shapes and two groups.

#ex-wide("recipe-classifier", fig-width: 100%, fig-height: 8.5cm)

== An encoder-decoder

A size pyramid down and back up, with skips arriving on their targets. The two
`deconv` blocks take their size from `shape` exactly as the encoder does, so the
figure is symmetric because the model is, not because it was measured.

#ex-wide("recipe-encoder-decoder", fig-width: 100%, fig-height: 8.5cm)

== Residual stages

`repeat` for the blocks inside a stage, a `sum` node for each add, and two route
colours to separate an identity shortcut from a projected one.

#ex-wide("recipe-residual-stage", fig-width: 100%, fig-height: 8.5cm)

== A multi-scale head

A depth-mode branch, open at the end, is what a detector's heads look like.

#ex-wide("recipe-multiscale", fig-width: 92%, fig-height: 8.5cm)

== A repeated pair

`repeat` cannot express a repeated *pair* (section 11.3), so build the list
instead. Twelve blocks are written once, and the count lives in the `range`
rather than in the figure:

#ex-wide("recipe-programmatic", fig-width: 100%, fig-height: 7.5cm)

This is the general answer to any figure that is getting long. The layer list is
an array and a constructor is a function; anything Typst can do to those, you
can do to a figure.

= Every option

The tables below are generated from the package itself rather than written out
here, so an option cannot exist without appearing in this chapter.

== Options by layer type

#layer-key-table()

== Connection options

#key-table(connection-keys, exclude: ())

== Group options

#key-table(group-keys, exclude: ())

== Options of the MLP renderer

#mlp-key-table()

Plus the exports themselves: `draw-mlp`, `mlp-content`, the `mlp-layer`,
`mlp-gap` and `mlp-edge` constructors, and the `mlp-palettes` dictionary.

== Arguments to draw-network

#snippet(```typ
#draw-network(
  layers,
  connections: (),
  groups: (),
  palette: "warm",
  show-legend: false,
  legend-title: "Layers",
  main-legend: none,
  scale: 100%,
  stroke-thickness: 1,
  depth-multiplier: 0.3,
  lane-unit: 0.75,
  shape-scale: (spatial: (1.2, -3.2), channels: (0.075, 0.0)),
  auto-gap: 0.55,
  show-relu: false,
)
```)

== Also exported

#snippet(```typ
depth-shear(depth, depth-multiplier: 0.3)
min-clear-offset(depth, depth-multiplier: 0.3)
```)

Plus a constructor per layer type, and `connection(..)` and `group(..)`.

== Coverage

#undocumented((
  "name", "label", "legend", "offset", "shape", "repeat", "height", "depth",
  "channels", "fill", "opacity", "image", "show-connection", "connection-label",
  "label-orient", "label-dx", "label-dy", "label-anchor", "label-angle",
  "width", "widths", "bandfill", "show-relu", "input-style",
  "xlabel", "ylabel", "zlabel", "classes", "radius", "symbol", "stroke",
  "branches", "spread", "spread-mode", "lead", "rejoin-lead", "open",
  "entry-gap", "exit-gap",
  "from", "to", "mode", "pos", "clearance", "color", "dash", "thickness",
  "touch-layer", "arrive-offset", "layers",
))

#mlp-undocumented((
  "count", "name", "label", "sub", "activation", "fill", "stroke", "shape",
  "node-size", "node-label", "node-label-pos", "values", "show-value-text",
  "dropped", "dimmed", "highlighted", "exclude", "show-all", "bias",
  "node-style", "pitch",
  "from", "to", "style", "paint", "thickness", "dash", "opacity", "arrow",
  "sum",
  "direction", "unit", "node-pitch", "layer-pitch", "title", "debug",
  "cutoff", "collapse-to", "count-badges", "palette", "node-shape",
  "node-stroke", "input-style", "edge-stroke", "edge-opacity", "arrows",
  "io-stubs", "stub-labels", "edge-filter", "edges", "edge-style", "weights",
  "weight-encode", "weight-colors", "weight-range", "weight-thickness",
  "seed", "edge-labels", "matrix-labels", "bias-label", "bias-label-pos",
  "layer-labels", "label-pos", "activation-style",
))

= Errors

Every message the package raises, and what causes it.

#opt("unknown layer option \"X\" on layer N (type \"T\")")[
  `X` is not an option of that type. The message lists what is, and suggests the
  nearest match. A correctly spelled option belonging to a *different* type
  gives this too --- `widths` on a `pool`, `width` on a `conv`.
]

#opt("unknown layer type \"X\" on layer N")[
  Not one of the fourteen. See section 16.1.
]

#opt("layer N is a plain dictionary")[
  Every layer comes from a constructor. Write `(type: "conv", ..)` as
  `conv(..)`; a dictionary of options spreads into it as `conv(..opts)`.
]

#opt("connection N refers to \"X\", which is not the `name` of any layer")[
  Either the target has no `name`, or the reference is misspelled. Groups give
  the same message.
]

#opt("connection N has no `from`")[
  A route names both layers it runs between.
]

#opt("`branches` on layer N must be an array of layer arrays")[
  A common slip is passing one layer list rather than a list of them. Two
  branches of one layer each is `((conv(),), (conv(),))`.
]

#opt("branch open must be \"start\" or \"end\"")[]
#opt("label-orient must be \"horizontal\", \"diagonal\" or \"vertical\"")[]
#opt("Use either label-orient or label-angle, not both")[
  The right anchor for an arbitrary rotation depends on where you want the text,
  so the package will not guess.
]

#opt("shape must be (channels, height, width)")[Three numbers, in that order.]

#opt("array index out of bounds (index: 1, len: 1)")[
  Raised from inside `src/lib.typ` rather than as a message of the package's
  own. Almost always `channels` with more entries than the layer has bands, plus
  one. Either add matching `widths` entries or remove channel entries.
]

#opt("unexpected argument: X")[
  Typst's own message, from a constructor given an option that does not exist.
  It is raised before the package sees the call, which is one reason to prefer
  constructors.
]

= Where to go next

Complete architectures are in `examples/` in the repository, and their rendered
output in `gallery/`. They are ordinary Typst files, meant to be read and
copied:

#block(inset: (left: 6pt))[
  #set text(size: 9.5pt)
  / `examples/networks/`: AlexNet, LeNet-5, VGG16, VGG19, ResNet18, U-Net, FCN-8
    and YOLO26-n, plus five RGB-IR fusion variants of the last one.
  / `examples/features/`: every predefined layer type side by side in both
    palettes, and a figure exercising every feature at once.
  / `examples/mlp/`: the neuron diagrams of chapter 14 --- the classic
    three-layer figure, a Playground-style random-weight network, a Rosenblatt
    perceptron, a Goodfellow-orientation textbook figure, a dropout figure,
    and a deep network with a gap, a skip and a recurrent loop.
  / `examples/imported/`: figures generated from a traced PyTorch model rather
    than written by hand, using `tools/import_model.py`.
]

The YOLO26-n example is the one to read if you want to see the automatic
machinery carrying a whole figure. Every block states its tensor shape, every
gap is automatic, every lane height is automatic, and the three detection heads
are a depth-mode branch. Nothing in it is sized or positioned by hand.

This manual is itself plain text. `doc/manual.typ` and the 179 files in
`doc/examples/` are the whole of it, each example a standalone figure that
compiles on its own. That source, rather than this PDF, is what to point a
language model at.
