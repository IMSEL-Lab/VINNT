// Validation: reject unknown options, dangling names and hand-written
// dictionaries before anything is drawn.

#import "keys.typ": layer-keys, connection-keys, group-keys

// The marker every constructor stamps on its result. Its presence is how
// validation tells a constructed value from a hand-written dictionary.
#let ctor-marker = "vinnt-ctor"

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
