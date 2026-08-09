// Importing traced model dumps produced by tools/import_model.py.

#import "ctor.typ": input, conv, convres, deconv, pool, unpool, concat, gap, fc, softmax, convsoftmax, output, custom, sum, group

// The constructor for each importable layer type, so imported dumps go
// through the same argument checking as hand-written layers.
#let layer-ctors = (
  input: input, conv: conv, convres: convres, deconv: deconv,
  pool: pool, unpool: unpool, concat: concat, gap: gap, fc: fc,
  softmax: softmax, convsoftmax: convsoftmax, output: output,
  custom: custom, sum: sum,
)

// Turn an imported model dump into a layer list; `label` picks "leaf", "path", "op", "shape" or none.
#let from-shapes(
  data,
  label: "leaf",
  defaults: (:),
  by-op: (:),
  overrides: (:),
  drop: (),
) = {
  data.at("layers", default: ()).filter(r => r.at("name") not in drop).map(r => {
    let shape = r.at("shape", default: none)
    let text-of(kind) = {
      if kind == none { none }
      else if kind == "op" { r.at("op", default: "") }
      else if kind == "path" { r.at("path", default: r.name) }
      else if kind == "shape" and shape != none and shape.len() == 3 {
        str(shape.at(0)) + "×" + str(shape.at(1))
      } else if kind == "shape" and shape != none { str(shape.at(0)) }
      else if kind == "shape" { none }
      else {
        let parts = r.at("path", default: r.name).split(".")
        let last = parts.last()
        if parts.len() > 1 and last.matches(regex("^[0-9]+$")).len() > 0 {
          parts.at(parts.len() - 2) + "." + last
        } else { last }
      }
    }

    let ty = r.at("type")
    if type(ty) != str or ty not in layer-ctors {
      panic(
        "vinnt: imported layer " + repr(r.at("name")) + " has type " + repr(ty)
          + ", which no constructor matches. Importable types: "
          + layer-ctors.keys().sorted().join(", ") + "."
      )
    }
    let l = (
      name: r.at("name"),
      offset: auto,
    )
    let lbl = text-of(label)
    if lbl != none and lbl != "" { l.insert("label", lbl) }

    if shape != none and shape.len() == 3 {
      l.insert("shape", (shape.at(0), shape.at(1), shape.at(2)))
      l.insert("channels", (shape.at(0), shape.at(1)))
    } else if shape != none and shape.len() == 1 {
      l.insert("channels", (shape.at(0),))
    }

    if ty in ("conv", "convres", "custom") {
      l.insert("show-relu", r.at("relu", default: false))
    }
    let n = r.at("repeat", default: 1)
    if n > 1 { l.insert("repeat", n) }

    for (k, v) in defaults { l.insert(k, v) }
    for (k, v) in by-op.at(r.at("op", default: ""), default: (:)) { l.insert(k, v) }
    for (k, v) in overrides.at(r.at("name"), default: (:)) { l.insert(k, v) }
    layer-ctors.at(ty)(..l)
  })
}

// Stage brackets from the same dump, one per run of layers sharing a group.
#let groups-from-shapes(data, skip: ("input",), drop: (), ..rest) = {
  let runs = ()
  for r in data.at("layers", default: ()) {
    let g = r.at("group", default: "")
    if g in skip or g == "" or r.at("name") in drop { continue }
    if runs.len() > 0 and runs.last().label == g {
      runs.last().to = r.at("name")
    } else {
      runs.push((label: g, from: r.at("name"), to: r.at("name")))
    }
  }
  runs.map(g => group(from: g.from, to: g.to, label: g.label, ..rest.named()))
}
