// Options every drawn layer understands; `sum` and `branch` have their own sets below.
#let layer-common-keys = (
  "type", "name", "label", "legend", "offset", "shape", "repeat",
  "height", "depth", "channels", "fill", "opacity", "image",
  "show-connection", "connection-label",
  "label-orient", "label-dx", "label-dy", "label-anchor", "label-angle",
)

// What each type adds on top of the common set.
#let layer-extra-keys = (
  input: ("width", "input-style"),
  conv: ("widths", "bandfill", "show-relu", "xlabel", "ylabel", "zlabel"),
  convres: ("widths", "bandfill", "show-relu", "xlabel", "ylabel", "zlabel"),
  custom: ("width", "widths", "bandfill", "show-relu", "input-style",
           "xlabel", "ylabel", "zlabel"),
  deconv: ("width",),
  concat: ("width",),
  convsoftmax: ("width",),
  softmax: ("width", "classes"),
  output: ("width", "classes"),
  pool: (),
  unpool: (),
  gap: (),
  fc: (),
)

#let layer-keys = {
  let m = (:)
  for (ty, extra) in layer-extra-keys { m.insert(ty, layer-common-keys + extra) }
  // A node, not a block: radius and symbol instead of a width, and no shape.
  m.insert("sum", (
    "type", "name", "label", "legend", "offset", "height", "depth", "channels",
    "fill", "opacity", "radius", "symbol", "stroke",
    "show-connection", "connection-label",
    "label-orient", "label-dx", "label-dy", "label-anchor", "label-angle",
  ))
  // A container: it draws no block of its own, so no block options apply.
  m.insert("branch", (
    "type", "name", "branches", "spread", "spread-mode", "lead", "rejoin-lead", "open",
  ))
  m
}

#let connection-keys = (
  "from", "to", "type", "mode", "pos", "label", "opacity", "color", "dash",
  "thickness", "legend", "touch-layer", "arrive-offset", "clearance", "layers",
)

#let group-keys = ("from", "to", "label", "offset", "color")

// Levenshtein distance, used to suggest the key an unknown one was probably meant to be.
#let edit-distance(a, b) = {
  let a = a.clusters()
  let b = b.clusters()
  let prev = range(b.len() + 1)
  for i in range(1, a.len() + 1) {
    let cur = (i,)
    for j in range(1, b.len() + 1) {
      let cost = if a.at(i - 1) == b.at(j - 1) { 0 } else { 1 }
      cur.push(calc.min(cur.at(j - 1) + 1, prev.at(j) + 1, prev.at(j - 1) + cost))
    }
    prev = cur
  }
  prev.last()
}

// The nearest candidate, when it is near enough to be worth naming.
#let did-you-mean(key, candidates) = {
  if type(key) != str { return "" }
  let best = none
  let best-d = 0
  for k in candidates {
    let d = edit-distance(key, k)
    if best == none or d < best-d { best = k; best-d = d }
  }
  if best != none and best-d <= calc.max(2, int(key.len() / 3)) {
    " Did you mean \"" + best + "\"?"
  } else { "" }
}

// The marker every constructor stamps on its result. Its presence is how
// validation tells a constructed value from a hand-written dictionary.
#let ctor-marker = "vinnt-ctor"

#let check-keys(what, where, dict, allowed) = {
  for k in dict.keys() {
    if k == ctor-marker { continue }
    if k not in allowed {
      panic(
        "vinnt: unknown " + what + " option \"" + k + "\" " + where + "."
          + did-you-mean(k, allowed)
          + " Options accepted here: " + allowed.sorted().join(", ") + "."
      )
    }
  }
}

#let check-layer(l, where) = {
  if type(l) != dictionary {
    panic(
      "vinnt: " + where + " must be a constructor call such as conv(...); got "
        + repr(l) + "."
    )
  }
  if ctor-marker not in l {
    let ty = l.at("type", default: none)
    let hint = if type(ty) == str and ty in layer-keys {
      " Write it as " + ty + "(...) instead."
    } else {
      " Write it with one of the constructors: "
        + layer-keys.keys().sorted().join(", ") + "."
    }
    panic(
      "vinnt: " + where + " is a plain dictionary. Every layer comes from "
        + "a constructor." + hint
    )
  }
  if "type" not in l {
    panic(
      "vinnt: " + where + " has no `type`. Every layer states one; the "
        + "constructors fill it in. Known types: "
        + layer-keys.keys().sorted().join(", ") + "."
    )
  }
  let ty = l.at("type")
  if type(ty) != str or ty not in layer-keys {
    panic(
      "vinnt: unknown layer type " + repr(ty) + " on " + where + "."
        + did-you-mean(ty, layer-keys.keys())
        + " Known types: " + layer-keys.keys().sorted().join(", ") + "."
    )
  }
  check-keys("layer", "on " + where + " (type \"" + ty + "\")", l, layer-keys.at(ty))
}

// Every name declared anywhere in the layer tree, branches included.
#let collect-names(layers) = {
  let names = ()
  for l in layers {
    if type(l) != dictionary { continue }
    let n = l.at("name", default: none)
    if n != none { names.push(n) }
    if l.at("type", default: none) == "branch" {
      for sub in l.at("branches", default: ()) {
        if type(sub) == array { names += collect-names(sub) }
      }
    }
  }
  names
}

#let check-layers(layers, where) = {
  if type(layers) != array {
    panic("vinnt: " + where + " must be an array of layers; got " + repr(layers) + ".")
  }
  for (i, l) in layers.enumerate() {
    let w = where + " " + str(i)
    check-layer(l, w)
    if l.at("type") == "branch" {
      let subs = l.at("branches", default: ())
      if type(subs) != array {
        panic(
          "vinnt: `branches` on " + w + " must be an array of layer arrays, "
            + "one per parallel path; got " + repr(subs) + "."
        )
      }
      for (j, sub) in subs.enumerate() {
        check-layers(sub, w + ", branch " + str(j) + ", layer")
      }
    }
  }
}

#let check-connections(connections, names) = {
  if type(connections) != array {
    panic("vinnt: `connections` must be an array; got " + repr(connections) + ".")
  }
  for (i, c) in connections.enumerate() {
    if type(c) != dictionary {
      panic("vinnt: connection " + str(i) + " must be a connection(..) call; got " + repr(c) + ".")
    }
    if ctor-marker not in c {
      panic(
        "vinnt: connection " + str(i) + " is a plain dictionary. "
          + "Write it as connection(from: .., to: .., ..)."
      )
    }
    for k in ("from", "to") {
      if k not in c {
        panic(
          "vinnt: connection " + str(i) + " has no `" + k + "`. A connection "
            + "names the two layers it runs between, so both layers need a `name`."
        )
      }
    }
    let where = "on connection " + str(i) + " (" + repr(c.at("from")) + " -> " + repr(c.at("to")) + ")"
    check-keys("connection", where, c, connection-keys)
    let inline = c.at("layers", default: none)
    if inline != none {
      for (j, l) in inline.enumerate() {
        check-layer(l, "connection " + str(i) + " inline layer " + str(j))
      }
    }
    for k in ("from", "to") {
      if c.at(k) not in names {
        panic(
          "vinnt: connection " + str(i) + " refers to " + repr(c.at(k))
            + ", which is not the `name` of any layer." + did-you-mean(c.at(k), names)
        )
      }
    }
  }
}

#let check-groups(groups, names) = {
  if type(groups) != array {
    panic("vinnt: `groups` must be an array; got " + repr(groups) + ".")
  }
  for (i, g) in groups.enumerate() {
    if type(g) != dictionary {
      panic("vinnt: group " + str(i) + " must be a group(..) call; got " + repr(g) + ".")
    }
    if ctor-marker not in g {
      panic(
        "vinnt: group " + str(i) + " is a plain dictionary. "
          + "Write it as group(from: .., to: .., ..)."
      )
    }
    for k in ("from", "to") {
      if k not in g {
        panic(
          "vinnt: group " + str(i) + " has no `" + k + "`. A group spans from "
            + "one named layer to another, inclusive, and the two may be the same."
        )
      }
    }
    check-keys("group", "on group " + str(i), g, group-keys)
    for k in ("from", "to") {
      if g.at(k) not in names {
        panic(
          "vinnt: group " + str(i) + " refers to " + repr(g.at(k))
            + ", which is not the `name` of any layer." + did-you-mean(g.at(k), names)
        )
      }
    }
  }
}

// Constructors. A private sentinel, so an absent option stays absent rather than becoming `none`.
#let unset = (vinnt-unset: true)

#let mk(ty, args) = {
  let l = (type: ty, vinnt-ctor: true)
  for (k, v) in args { if v != unset { l.insert(k, v) } }
  check-layer(l, "this " + ty + " layer")
  l
}

#let input(
  name: unset, label: unset, legend: unset, offset: unset, shape: unset, repeat: unset,
  width: unset, height: unset, depth: unset, channels: unset,
  fill: unset, opacity: unset, image: unset, input-style: unset,
  show-connection: unset, connection-label: unset,
  label-orient: unset, label-dx: unset, label-dy: unset, label-anchor: unset, label-angle: unset,
) = mk("input", (
  name: name, label: label, legend: legend, offset: offset, shape: shape, repeat: repeat,
  width: width, height: height, depth: depth, channels: channels,
  fill: fill, opacity: opacity, image: image, input-style: input-style,
  show-connection: show-connection, connection-label: connection-label,
  label-orient: label-orient, label-dx: label-dx, label-dy: label-dy,
  label-anchor: label-anchor, label-angle: label-angle,
))

#let conv(
  name: unset, label: unset, legend: unset, offset: unset, shape: unset, repeat: unset,
  widths: unset, height: unset, depth: unset, channels: unset,
  fill: unset, bandfill: unset, opacity: unset, image: unset, show-relu: unset,
  show-connection: unset, connection-label: unset,
  xlabel: unset, ylabel: unset, zlabel: unset,
  label-orient: unset, label-dx: unset, label-dy: unset, label-anchor: unset, label-angle: unset,
) = mk("conv", (
  name: name, label: label, legend: legend, offset: offset, shape: shape, repeat: repeat,
  widths: widths, height: height, depth: depth, channels: channels,
  fill: fill, bandfill: bandfill, opacity: opacity, image: image, show-relu: show-relu,
  show-connection: show-connection, connection-label: connection-label,
  xlabel: xlabel, ylabel: ylabel, zlabel: zlabel,
  label-orient: label-orient, label-dx: label-dx, label-dy: label-dy,
  label-anchor: label-anchor, label-angle: label-angle,
))

#let convres(
  name: unset, label: unset, legend: unset, offset: unset, shape: unset, repeat: unset,
  widths: unset, height: unset, depth: unset, channels: unset,
  fill: unset, bandfill: unset, opacity: unset, image: unset, show-relu: unset,
  show-connection: unset, connection-label: unset,
  xlabel: unset, ylabel: unset, zlabel: unset,
  label-orient: unset, label-dx: unset, label-dy: unset, label-anchor: unset, label-angle: unset,
) = mk("convres", (
  name: name, label: label, legend: legend, offset: offset, shape: shape, repeat: repeat,
  widths: widths, height: height, depth: depth, channels: channels,
  fill: fill, bandfill: bandfill, opacity: opacity, image: image, show-relu: show-relu,
  show-connection: show-connection, connection-label: connection-label,
  xlabel: xlabel, ylabel: ylabel, zlabel: zlabel,
  label-orient: label-orient, label-dx: label-dx, label-dy: label-dy,
  label-anchor: label-anchor, label-angle: label-angle,
))

#let deconv(
  name: unset, label: unset, legend: unset, offset: unset, shape: unset, repeat: unset,
  width: unset, height: unset, depth: unset, channels: unset,
  fill: unset, opacity: unset, image: unset,
  show-connection: unset, connection-label: unset,
  label-orient: unset, label-dx: unset, label-dy: unset, label-anchor: unset, label-angle: unset,
) = mk("deconv", (
  name: name, label: label, legend: legend, offset: offset, shape: shape, repeat: repeat,
  width: width, height: height, depth: depth, channels: channels,
  fill: fill, opacity: opacity, image: image,
  show-connection: show-connection, connection-label: connection-label,
  label-orient: label-orient, label-dx: label-dx, label-dy: label-dy,
  label-anchor: label-anchor, label-angle: label-angle,
))

#let pool(
  name: unset, label: unset, legend: unset, offset: unset, shape: unset, repeat: unset,
  height: unset, depth: unset, channels: unset,
  fill: unset, opacity: unset, image: unset,
  show-connection: unset, connection-label: unset,
  label-orient: unset, label-dx: unset, label-dy: unset, label-anchor: unset, label-angle: unset,
) = mk("pool", (
  name: name, label: label, legend: legend, offset: offset, shape: shape, repeat: repeat,
  height: height, depth: depth, channels: channels,
  fill: fill, opacity: opacity, image: image,
  show-connection: show-connection, connection-label: connection-label,
  label-orient: label-orient, label-dx: label-dx, label-dy: label-dy,
  label-anchor: label-anchor, label-angle: label-angle,
))

#let unpool(
  name: unset, label: unset, legend: unset, offset: unset, shape: unset, repeat: unset,
  height: unset, depth: unset, channels: unset,
  fill: unset, opacity: unset, image: unset,
  show-connection: unset, connection-label: unset,
  label-orient: unset, label-dx: unset, label-dy: unset, label-anchor: unset, label-angle: unset,
) = mk("unpool", (
  name: name, label: label, legend: legend, offset: offset, shape: shape, repeat: repeat,
  height: height, depth: depth, channels: channels,
  fill: fill, opacity: opacity, image: image,
  show-connection: show-connection, connection-label: connection-label,
  label-orient: label-orient, label-dx: label-dx, label-dy: label-dy,
  label-anchor: label-anchor, label-angle: label-angle,
))

#let concat(
  name: unset, label: unset, legend: unset, offset: unset, shape: unset, repeat: unset,
  width: unset, height: unset, depth: unset, channels: unset,
  fill: unset, opacity: unset, image: unset,
  show-connection: unset, connection-label: unset,
  label-orient: unset, label-dx: unset, label-dy: unset, label-anchor: unset, label-angle: unset,
) = mk("concat", (
  name: name, label: label, legend: legend, offset: offset, shape: shape, repeat: repeat,
  width: width, height: height, depth: depth, channels: channels,
  fill: fill, opacity: opacity, image: image,
  show-connection: show-connection, connection-label: connection-label,
  label-orient: label-orient, label-dx: label-dx, label-dy: label-dy,
  label-anchor: label-anchor, label-angle: label-angle,
))

#let gap(
  name: unset, label: unset, legend: unset, offset: unset, shape: unset, repeat: unset,
  height: unset, depth: unset, channels: unset,
  fill: unset, opacity: unset, image: unset,
  show-connection: unset, connection-label: unset,
  label-orient: unset, label-dx: unset, label-dy: unset, label-anchor: unset, label-angle: unset,
) = mk("gap", (
  name: name, label: label, legend: legend, offset: offset, shape: shape, repeat: repeat,
  height: height, depth: depth, channels: channels,
  fill: fill, opacity: opacity, image: image,
  show-connection: show-connection, connection-label: connection-label,
  label-orient: label-orient, label-dx: label-dx, label-dy: label-dy,
  label-anchor: label-anchor, label-angle: label-angle,
))

#let fc(
  name: unset, label: unset, legend: unset, offset: unset, shape: unset, repeat: unset,
  height: unset, depth: unset, channels: unset,
  fill: unset, opacity: unset, image: unset,
  show-connection: unset, connection-label: unset,
  label-orient: unset, label-dx: unset, label-dy: unset, label-anchor: unset, label-angle: unset,
) = mk("fc", (
  name: name, label: label, legend: legend, offset: offset, shape: shape, repeat: repeat,
  height: height, depth: depth, channels: channels,
  fill: fill, opacity: opacity, image: image,
  show-connection: show-connection, connection-label: connection-label,
  label-orient: label-orient, label-dx: label-dx, label-dy: label-dy,
  label-anchor: label-anchor, label-angle: label-angle,
))

#let softmax(
  name: unset, label: unset, legend: unset, offset: unset, shape: unset, repeat: unset,
  width: unset, height: unset, depth: unset, channels: unset, classes: unset,
  fill: unset, opacity: unset, image: unset,
  show-connection: unset, connection-label: unset,
  label-orient: unset, label-dx: unset, label-dy: unset, label-anchor: unset, label-angle: unset,
) = mk("softmax", (
  name: name, label: label, legend: legend, offset: offset, shape: shape, repeat: repeat,
  width: width, height: height, depth: depth, channels: channels, classes: classes,
  fill: fill, opacity: opacity, image: image,
  show-connection: show-connection, connection-label: connection-label,
  label-orient: label-orient, label-dx: label-dx, label-dy: label-dy,
  label-anchor: label-anchor, label-angle: label-angle,
))

#let convsoftmax(
  name: unset, label: unset, legend: unset, offset: unset, shape: unset, repeat: unset,
  width: unset, height: unset, depth: unset, channels: unset,
  fill: unset, opacity: unset, image: unset,
  show-connection: unset, connection-label: unset,
  label-orient: unset, label-dx: unset, label-dy: unset, label-anchor: unset, label-angle: unset,
) = mk("convsoftmax", (
  name: name, label: label, legend: legend, offset: offset, shape: shape, repeat: repeat,
  width: width, height: height, depth: depth, channels: channels,
  fill: fill, opacity: opacity, image: image,
  show-connection: show-connection, connection-label: connection-label,
  label-orient: label-orient, label-dx: label-dx, label-dy: label-dy,
  label-anchor: label-anchor, label-angle: label-angle,
))

#let output(
  name: unset, label: unset, legend: unset, offset: unset, shape: unset, repeat: unset,
  width: unset, height: unset, depth: unset, channels: unset, classes: unset,
  fill: unset, opacity: unset, image: unset,
  show-connection: unset, connection-label: unset,
  label-orient: unset, label-dx: unset, label-dy: unset, label-anchor: unset, label-angle: unset,
) = mk("output", (
  name: name, label: label, legend: legend, offset: offset, shape: shape, repeat: repeat,
  width: width, height: height, depth: depth, channels: channels, classes: classes,
  fill: fill, opacity: opacity, image: image,
  show-connection: show-connection, connection-label: connection-label,
  label-orient: label-orient, label-dx: label-dx, label-dy: label-dy,
  label-anchor: label-anchor, label-angle: label-angle,
))

#let custom(
  name: unset, label: unset, legend: unset, offset: unset, shape: unset, repeat: unset,
  width: unset, widths: unset, height: unset, depth: unset, channels: unset,
  fill: unset, bandfill: unset, opacity: unset, image: unset, show-relu: unset,
  input-style: unset, show-connection: unset, connection-label: unset,
  xlabel: unset, ylabel: unset, zlabel: unset,
  label-orient: unset, label-dx: unset, label-dy: unset, label-anchor: unset, label-angle: unset,
) = mk("custom", (
  name: name, label: label, legend: legend, offset: offset, shape: shape, repeat: repeat,
  width: width, widths: widths, height: height, depth: depth, channels: channels,
  fill: fill, bandfill: bandfill, opacity: opacity, image: image, show-relu: show-relu,
  input-style: input-style, show-connection: show-connection, connection-label: connection-label,
  xlabel: xlabel, ylabel: ylabel, zlabel: zlabel,
  label-orient: label-orient, label-dx: label-dx, label-dy: label-dy,
  label-anchor: label-anchor, label-angle: label-angle,
))

#let sum(
  name: unset, label: unset, legend: unset, offset: unset,
  height: unset, depth: unset, channels: unset,
  radius: unset, symbol: unset, fill: unset, stroke: unset, opacity: unset,
  show-connection: unset, connection-label: unset,
  label-orient: unset, label-dx: unset, label-dy: unset, label-anchor: unset, label-angle: unset,
) = mk("sum", (
  name: name, label: label, legend: legend, offset: offset,
  height: height, depth: depth, channels: channels,
  radius: radius, symbol: symbol, fill: fill, stroke: stroke, opacity: opacity,
  show-connection: show-connection, connection-label: connection-label,
  label-orient: label-orient, label-dx: label-dx, label-dy: label-dy,
  label-anchor: label-anchor, label-angle: label-angle,
))

// `branches` is an array of layer arrays, one per parallel path.
#let branch(
  branches: (),
  name: unset, spread: unset, spread-mode: unset,
  lead: unset, rejoin-lead: unset, open: unset,
) = mk("branch", (
  branches: branches, name: name, spread: spread, spread-mode: spread-mode,
  lead: lead, rejoin-lead: rejoin-lead, open: open,
))

#let connection(
  from: unset, to: unset, type: unset, mode: unset, pos: unset, clearance: unset,
  label: unset, legend: unset, color: unset, dash: unset, thickness: unset,
  opacity: unset, touch-layer: unset, arrive-offset: unset, layers: unset,
) = {
  let c = (vinnt-ctor: true)
  for (k, v) in (
    from: from, to: to, type: type, mode: mode, pos: pos, clearance: clearance,
    label: label, legend: legend, color: color, dash: dash, thickness: thickness,
    opacity: opacity, touch-layer: touch-layer, arrive-offset: arrive-offset, layers: layers,
  ) { if v != unset { c.insert(k, v) } }
  for k in ("from", "to") {
    if k not in c { panic("vinnt: connection(..) needs `" + k + "`, the name of a layer.") }
  }
  c
}

#let group(from: unset, to: unset, label: unset, offset: unset, color: unset) = {
  let g = (vinnt-ctor: true)
  for (k, v) in (from: from, to: to, label: label, offset: offset, color: color) {
    if v != unset { g.insert(k, v) }
  }
  for k in ("from", "to") {
    if k not in g { panic("vinnt: group(..) needs `" + k + "`, the name of a layer.") }
  }
  g
}
