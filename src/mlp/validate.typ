// Validation for the MLP renderer: reject unknown options, bad counts,
// dangling endpoints and hand-written dictionaries before anything is drawn.
// The pure helpers come from ../validate.typ; the option tables from keys.typ.

#import "../validate.typ": edit-distance, did-you-mean, check-keys, ctor-marker
#import "keys.typ": (
  mlp-layer-keys, mlp-gap-keys, mlp-edge-keys, mlp-figure-keys,
  glyph-names, bracket-activations,
)
#import "theme.typ": mlp-palettes, palette-roles

// An enum option: the value must be one of the listed candidates.
#let check-enum(name, where, value, allowed) = {
  if allowed.contains(value) { return }
  let strs = allowed.filter(a => type(a) == str)
  panic(
    "vinnt: `" + name + "` " + where + " must be one of "
      + allowed.map(repr).join(", ") + "; got " + repr(value) + "."
      + did-you-mean(value, strs)
  )
}

#let is-num(v) = type(v) == int or type(v) == float

// ---------------------------------------------------------------------------
// Figure options

#let check-figure-opts(opts) = {
  if opts.pos().len() > 0 {
    panic(
      "vinnt: draw-mlp takes its options by name; got an unexpected "
        + "positional argument " + repr(opts.pos().at(0)) + "."
    )
  }
  check-keys("draw-mlp", "on the figure", opts.named(), mlp-figure-keys)
}

#let resolve-palette(p) = {
  if type(p) == str {
    if p not in mlp-palettes {
      panic(
        "vinnt: unknown palette " + repr(p) + "."
          + did-you-mean(p, mlp-palettes.keys())
          + " Named palettes: " + mlp-palettes.keys().sorted().join(", ")
          + "; or pass a dict with keys among " + palette-roles.join(", ") + "."
      )
    }
    return mlp-palettes.at(p)
  }
  if type(p) == dictionary {
    check-keys("palette", "on the figure", p, palette-roles)
    let base = mlp-palettes.brand
    for (k, v) in p {
      if type(v) != color {
        panic("vinnt: palette entry `" + k + "` must be a color; got " + repr(v) + ".")
      }
      base.insert(k, v)
    }
    return base
  }
  panic(
    "vinnt: `palette` must be a palette name (" + mlp-palettes.keys().sorted().join(", ")
      + ") or a dict of role colors; got " + repr(p) + "."
  )
}

#let check-figure-values(o) = {
  check-enum("direction", "on the figure", o.direction, ("right", "up"))
  if type(o.unit) != length {
    panic("vinnt: `unit` must be a length; got " + repr(o.unit) + ".")
  }
  for k in ("node-size", "node-pitch", "layer-pitch") {
    let v = o.at(k)
    if not is-num(v) or v <= 0 {
      panic("vinnt: `" + k + "` must be a positive number in canvas units; got " + repr(v) + ".")
    }
  }
  if type(o.debug) != bool { panic("vinnt: `debug` must be a bool; got " + repr(o.debug) + ".") }

  if o.cutoff != none and (type(o.cutoff) != int or o.cutoff < 1) {
    panic("vinnt: `cutoff` must be a positive integer or none; got " + repr(o.cutoff) + ".")
  }
  if type(o.collapse-to) != int or o.collapse-to < 3 or calc.rem(o.collapse-to, 2) == 0 {
    panic(
      "vinnt: `collapse-to` must be an odd integer of at least 3, so the "
        + "middle slot can hold the ellipsis; got " + repr(o.collapse-to) + "."
    )
  }
  if o.cutoff != none and o.cutoff <= o.collapse-to {
    panic(
      "vinnt: `cutoff` (" + str(o.cutoff) + ") must exceed `collapse-to` ("
        + str(o.collapse-to) + "); otherwise collapsing a layer would not "
        + "shorten it."
    )
  }
  check-enum("count-badges", "on the figure", o.count-badges, (auto, true, false))

  check-enum("node-shape", "on the figure", o.node-shape, ("circle", "square", "split"))
  check-enum("input-style", "on the figure", o.input-style, ("nodes", "square", "arrows"))
  if o.node-label != none and o.node-label != auto and type(o.node-label) != function {
    panic(
      "vinnt: `node-label` on the figure must be none, auto, or a function "
        + "(l, i) => content; got " + repr(o.node-label) + "."
    )
  }

  check-enum("arrows", "on the figure", o.arrows, ("none", "all"))
  check-enum("io-stubs", "on the figure", o.io-stubs, (false, true, "in", "out"))
  if o.stub-labels != auto and o.stub-labels != none and type(o.stub-labels) != function {
    panic(
      "vinnt: `stub-labels` must be auto, none, or a function "
        + "(side, i) => content; got " + repr(o.stub-labels) + "."
    )
  }
  for k in ("edge-filter", "edge-style") {
    let v = o.at(k)
    if v != none and type(v) != function {
      panic("vinnt: `" + k + "` must be none or a function (l, i, j); got " + repr(v) + ".")
    }
  }

  if type(o.edges) != array {
    panic("vinnt: `edges` must be an array of mlp-edge(..) values; got " + repr(o.edges) + ".")
  }
  for (i, e) in o.edges.enumerate() {
    if type(e) != dictionary or ctor-marker not in e or e.at("type", default: none) != "mlp-edge" {
      panic(
        "vinnt: `edges` entry " + str(i + 1) + " must come from mlp-edge(..); got "
          + repr(e) + "."
      )
    }
    check-keys("mlp-edge", "on edges entry " + str(i + 1), e, mlp-edge-keys)
    if "style" in e {
      check-enum("style", "on edges entry " + str(i + 1), e.style,
        ("straight", "arc-above", "arc-below", "loop"))
    }
    for k in ("arrow", "sum") {
      if k in e and type(e.at(k)) != bool {
        panic("vinnt: `" + k + "` on edges entry " + str(i + 1) + " must be a bool; got " + repr(e.at(k)) + ".")
      }
    }
  }

  let w = o.weights
  if w != none and type(w) != array and type(w) != function {
    if w != "random" {
      panic(
        "vinnt: `weights` must be none, an array of matrices, a function "
          + "(l, i, j) => float, or \"random\"; got " + repr(w) + "."
      )
    }
  }
  if type(o.weight-encode) != array {
    panic("vinnt: `weight-encode` must be an array; got " + repr(o.weight-encode) + ".")
  }
  for ch in o.weight-encode {
    check-enum("weight-encode", "member on the figure", ch, ("color", "thickness", "opacity"))
  }
  if type(o.weight-colors) != dictionary {
    panic("vinnt: `weight-colors` must be a dict (positive, negative); got " + repr(o.weight-colors) + ".")
  }
  check-keys("weight-colors", "on the figure", o.weight-colors, ("positive", "negative"))
  if o.weight-range != auto and (not is-num(o.weight-range) or o.weight-range <= 0) {
    panic("vinnt: `weight-range` must be auto or a positive number; got " + repr(o.weight-range) + ".")
  }
  if (type(o.weight-thickness) != array or o.weight-thickness.len() != 2
    or o.weight-thickness.any(t => type(t) != length)) {
    panic(
      "vinnt: `weight-thickness` must be a pair of lengths (at zero, at "
        + "saturation); got " + repr(o.weight-thickness) + "."
    )
  }
  if type(o.seed) != int {
    panic("vinnt: `seed` must be an integer; got " + repr(o.seed) + ".")
  }

  if type(o.edge-labels) != array {
    panic("vinnt: `edge-labels` must be an array of (l, i, j, label) dicts; got " + repr(o.edge-labels) + ".")
  }
  for (i, el) in o.edge-labels.enumerate() {
    if type(el) != dictionary {
      panic("vinnt: `edge-labels` entry " + str(i + 1) + " must be a dict (l, i, j, label); got " + repr(el) + ".")
    }
    check-keys("edge-labels", "on edge-labels entry " + str(i + 1), el, ("l", "i", "j", "label"))
    for k in ("l", "i", "j") {
      if k not in el or type(el.at(k)) != int {
        panic(
          "vinnt: `edge-labels` entry " + str(i + 1) + " needs integer `l`, `i` "
            + "and `j` (gap, source neuron, target neuron)."
        )
      }
    }
  }
  if o.matrix-labels != false and o.matrix-labels != true and type(o.matrix-labels) != function {
    panic("vinnt: `matrix-labels` must be false, true, or a function (l) => content; got " + repr(o.matrix-labels) + ".")
  }

  if type(o.bias) != bool { panic("vinnt: `bias` must be a bool; got " + repr(o.bias) + ".") }
  if o.layer-labels != none and o.layer-labels != auto and type(o.layer-labels) != array {
    panic("vinnt: `layer-labels` must be none, auto, or an array with one entry per layer; got " + repr(o.layer-labels) + ".")
  }
  check-enum("label-pos", "on the figure", o.label-pos, ("below", "above"))
  check-enum("activation-style", "on the figure", o.activation-style,
    ("caption", "glyph", "block", "split"))
}

// ---------------------------------------------------------------------------
// Columns

// Normalize the layers array into column records (kind, src, pos), checking
// element types, option keys, counts and gap placement. `pos` counts layers
// and gaps separately, matching the auto names l1, l2, ... and g1, g2, ...
#let normalize-columns(layers) = {
  if type(layers) != array {
    panic("vinnt: draw-mlp expects an array of layers; got " + repr(layers) + ".")
  }
  if layers.len() == 0 {
    panic("vinnt: draw-mlp got an empty `layers` array; a network needs at least one layer.")
  }
  let cols = ()
  let n-layer = 0
  let n-gap = 0
  for (idx, l) in layers.enumerate() {
    if type(l) == int {
      n-layer += 1
      if l < 1 {
        panic(
          "vinnt: layer " + str(n-layer) + " has count " + str(l)
            + "; every layer needs at least one neuron."
        )
      }
      cols.push((kind: "layer", src: (type: "mlp-layer", vinnt-ctor: true, count: l), pos: n-layer))
      continue
    }
    if type(l) != dictionary {
      panic(
        "vinnt: layers entry " + str(idx + 1) + " must be an integer, "
          + "mlp-layer(..) or mlp-gap(..); got " + repr(l) + "."
      )
    }
    if ctor-marker not in l {
      panic(
        "vinnt: layers entry " + str(idx + 1) + " is a plain dictionary. "
          + "Every column comes from a constructor; write it as mlp-layer(..) "
          + "or mlp-gap(..)."
      )
    }
    let ty = l.at("type", default: none)
    if ty == "mlp-layer" {
      n-layer += 1
      check-keys("mlp-layer", "on layer " + str(n-layer), l, mlp-layer-keys)
      cols.push((kind: "layer", src: l, pos: n-layer))
    } else if ty == "mlp-gap" {
      n-gap += 1
      check-keys("mlp-gap", "on gap " + str(n-gap) + " (\"g" + str(n-gap) + "\")", l, mlp-gap-keys)
      cols.push((kind: "gap", src: l, pos: n-gap))
    } else {
      panic(
        "vinnt: layers entry " + str(idx + 1) + " has type " + repr(ty)
          + "; draw-mlp accepts mlp-layer(..) and mlp-gap(..) columns only."
      )
    }
  }
  if cols.first().kind == "gap" or cols.last().kind == "gap" {
    panic(
      "vinnt: an mlp-gap cannot be the first or last column; it stands for "
        + "elided depth between real layers."
    )
  }
  cols
}

// Final column names: the user name where given, else l<pos> / g<pos>.
// User names win; collisions error.
#let resolve-names(cols) = {
  let names = ()
  for c in cols {
    let n = if c.kind == "gap" { "g" + str(c.pos) } else {
      c.src.at("name", default: "l" + str(c.pos))
    }
    if type(n) != str {
      panic("vinnt: `name` on layer " + str(c.pos) + " must be a string; got " + repr(n) + ".")
    }
    names.push(n)
  }
  for (i, n) in names.enumerate() {
    if names.slice(0, i).contains(n) {
      panic(
        "vinnt: two columns are both named " + repr(n) + ". Names must be "
          + "unique, and user names share one namespace with the auto names "
          + "l1, l2, ... and g1, g2, ..."
      )
    }
  }
  names
}

// Per-layer value checks: index arrays, their mutual exclusivity, values,
// enums and the last-layer bias rule.
#let check-layer-detail(src, pos, name, L) = {
  let where = "on layer " + str(pos) + " (\"" + name + "\")"
  let count = src.count

  let seen = (:)
  for key in ("dropped", "dimmed", "highlighted", "exclude") {
    let arr = src.at(key, default: ())
    if type(arr) != array {
      panic("vinnt: `" + key + "` " + where + " must be an array of neuron indices; got " + repr(arr) + ".")
    }
    for i in arr {
      if type(i) != int or i < 1 or i > count {
        panic(
          "vinnt: `" + key + "` index " + repr(i) + " " + where
            + " is out of range; the layer has neurons 1.." + str(count) + "."
        )
      }
      let k = str(i)
      if k in seen {
        panic(
          "vinnt: neuron " + str(i) + " " + where + " appears in both `"
            + seen.at(k) + "` and `" + key + "`; a neuron may be in at most "
            + "one of dropped, dimmed, highlighted, exclude."
        )
      }
      seen.insert(k, key)
    }
  }

  let values = src.at("values", default: none)
  if values != none {
    if type(values) != array or values.len() != count {
      panic(
        "vinnt: `values` " + where + " must be an array of " + str(count)
          + " floats in 0..1, one per neuron; got " + repr(values) + "."
      )
    }
    for v in values {
      if not is-num(v) or v < 0 or v > 1 {
        panic("vinnt: `values` entry " + repr(v) + " " + where + " is not a float in 0..1.")
      }
    }
  }
  if src.at("show-value-text", default: false) == true and values == none {
    panic("vinnt: `show-value-text` " + where + " requires `values`.")
  }

  if "shape" in src {
    check-enum("shape", where, src.shape, ("circle", "square", "split"))
  }
  if "node-label-pos" in src {
    check-enum("node-label-pos", where, src.node-label-pos, ("inside", "left", "right"))
  }
  if "node-size" in src and (not is-num(src.node-size) or src.node-size <= 0) {
    panic("vinnt: `node-size` " + where + " must be a positive number; got " + repr(src.node-size) + ".")
  }
  let nl = src.at("node-label", default: none)
  if nl != none and nl != auto and type(nl) != function {
    panic("vinnt: `node-label` " + where + " must be none, auto, or a function (i) => content; got " + repr(nl) + ".")
  }
  let ns = src.at("node-style", default: none)
  if ns != none and type(ns) != function {
    panic("vinnt: `node-style` " + where + " must be none or a function (i) => dict; got " + repr(ns) + ".")
  }
  for k in ("show-all", "bias") {
    if k in src and type(src.at(k)) != bool {
      panic("vinnt: `" + k + "` " + where + " must be a bool; got " + repr(src.at(k)) + ".")
    }
  }
  if pos == L and src.at("bias", default: false) == true {
    panic(
      "vinnt: `bias: true` " + where + " has no effect to draw; the last "
        + "layer has no next layer for a bias node to feed. Bias nodes exist "
        + "on layers 1.." + str(L - 1) + "."
    )
  }
}

// The glyph rule: under a glyph-bearing activation style, an activation must
// be a known curve name or one of the bracket activations.
#let check-glyph-activation(act, pos, name, style) = {
  if act == none { return }
  if type(act) == str and (glyph-names.contains(act) or bracket-activations.contains(act)) {
    return
  }
  let hint = if type(act) == str { did-you-mean(act, glyph-names + bracket-activations) } else { "" }
  panic(
    "vinnt: activation " + repr(act) + " on layer " + str(pos) + " (\"" + name
      + "\") has no glyph, and activation-style \"" + style + "\" needs one."
      + hint + " Known glyphs: " + glyph-names.join(", ")
      + ". softmax and argmax draw as a layer-spanning bracket instead; any "
      + "other name renders as text under activation-style: \"caption\"."
  )
}

// Weight matrices: one per gap, target-major (the W x convention).
#let check-weights(weights, counts) = {
  if type(weights) != array { return }
  let gaps = counts.len() - 1
  if weights.len() != gaps {
    panic(
      "vinnt: `weights` must contain " + str(gaps) + " matrices, one per "
        + "inter-layer gap; got " + str(weights.len()) + "."
    )
  }
  for l in range(gaps) {
    let m = weights.at(l)
    let want-rows = counts.at(l + 1)
    let want-cols = counts.at(l)
    let shape-err(got) = panic(
      "vinnt: `weights` matrix " + str(l + 1) + " (layers " + str(l + 1)
        + " -> " + str(l + 2) + ") must be " + str(want-rows) + " x "
        + str(want-cols) + " (rows x columns, target-major: entry [j][i] is "
        + "the weight into neuron j of layer " + str(l + 2) + "); got " + got + "."
    )
    if type(m) != array or m.any(row => type(row) != array) {
      shape-err(repr(m))
    }
    if m.len() != want-rows or m.any(row => row.len() != want-cols) {
      let cols-seen = m.map(row => row.len()).dedup()
      let cols-str = if cols-seen.len() == 1 { str(cols-seen.at(0)) } else { "ragged " + repr(cols-seen) }
      shape-err(str(m.len()) + " x " + cols-str)
    }
    for row in m {
      for v in row {
        if not is-num(v) {
          panic(
            "vinnt: `weights` matrix " + str(l + 1) + " contains " + repr(v)
              + "; every entry must be a number."
          )
        }
      }
    }
  }
}

// ---------------------------------------------------------------------------
// mlp-edge endpoints
//
// `index` is an array of layer records built by the renderer:
//   (col: col index, pos: layer ordinal, name, count, drawn: (ints),
//    excluded: (ints))
// Gaps appear in `gap-names` only, so they can be named in errors.

#let resolve-endpoint(v, index, gap-names, where) = {
  let layer-names = index.map(r => r.name)
  let by-name(n) = {
    if gap-names.contains(n) {
      panic(
        "vinnt: mlp-edge endpoint " + where + " refers to \"" + n + "\", "
          + "which is a gap; gaps have no neurons and cannot be edge endpoints."
      )
    }
    let hit = index.find(r => r.name == n)
    if hit == none {
      panic(
        "vinnt: mlp-edge endpoint " + where + " refers to \"" + n + "\", "
          + "which is not the name of any layer."
          + did-you-mean(n, layer-names)
      )
    }
    hit
  }
  let by-pos(p) = {
    if type(p) != int or p < 1 or p > index.len() {
      panic(
        "vinnt: mlp-edge endpoint " + where + " addresses layer " + repr(p)
          + "; this figure has layers 1.." + str(index.len()) + "."
      )
    }
    index.at(p - 1)
  }

  let rec = none
  let neuron = none
  if type(v) == str {
    let parts = v.split(".")
    if parts.len() == 2 and parts.at(1).match(regex("^[0-9]+$")) != none {
      rec = by-name(parts.at(0))
      neuron = int(parts.at(1))
    } else {
      rec = by-name(v)
    }
  } else if type(v) == array and v.len() >= 1 and v.len() <= 2 {
    let l = v.at(0)
    rec = if type(l) == str { by-name(l) } else { by-pos(l) }
    if v.len() == 2 { neuron = v.at(1) }
  } else {
    panic(
      "vinnt: mlp-edge endpoint " + where + " must be \"name.index\", "
        + "\"name\", (layer, index) or (layer,); got " + repr(v) + "."
    )
  }

  if neuron != none {
    let lw = "layer " + str(rec.pos) + " (\"" + rec.name + "\")"
    if type(neuron) != int or neuron < 1 or neuron > rec.count {
      panic(
        "vinnt: mlp-edge endpoint " + where + " names neuron " + repr(neuron)
          + " on " + lw + ", which has neurons 1.." + str(rec.count) + "."
      )
    }
    if rec.excluded.contains(neuron) {
      panic(
        "vinnt: mlp-edge endpoint " + where + " names neuron " + str(neuron)
          + " on " + lw + ", which is excluded and not drawn."
      )
    }
    if not rec.drawn.contains(neuron) {
      panic(
        "vinnt: mlp-edge endpoint " + where + " names neuron " + str(neuron)
          + " on " + lw + ", which the ellipsis elides. Edges attach only to "
          + "drawn neurons (" + rec.drawn.map(str).join(", ") + ")."
      )
    }
  }
  (col: rec.col, pos: rec.pos, name: rec.name, neuron: neuron)
}
