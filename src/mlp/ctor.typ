// Constructors for the MLP renderer: the one way a column or an extra edge
// is written. Same unset-sentinel pattern as ../ctor.typ. A trailing sink
// carries unknown options into the value so draw-time validation can report
// them with the column position attached ("on layer 2"), which a constructor
// cannot know.

// A private sentinel, so an absent option stays absent rather than becoming `none`.
#let unset = (vinnt-unset: true)

#let mk(ty, args, rest) = {
  if rest.pos().len() > 0 {
    panic(
      "vinnt: " + ty + "(..) got an unexpected positional argument "
        + repr(rest.pos().at(0)) + "; options are passed by name."
    )
  }
  let v = (type: ty, vinnt-ctor: true)
  for (k, val) in args { if val != unset { v.insert(k, val) } }
  for (k, val) in rest.named() { v.insert(k, val) }
  v
}

#let mlp-layer(
  count,
  name: unset, label: unset, sub: unset, activation: unset, fill: unset,
  stroke: unset, shape: unset, node-size: unset, node-label: unset,
  node-label-pos: unset, values: unset, show-value-text: unset,
  dropped: unset, dimmed: unset, highlighted: unset, exclude: unset,
  show-all: unset, bias: unset, node-style: unset,
  ..rest,
) = {
  if type(count) != int or count < 1 {
    panic(
      "vinnt: mlp-layer(..) needs a positive integer neuron count; got "
        + repr(count) + "."
    )
  }
  mk("mlp-layer", (
    count: count, name: name, label: label, sub: sub, activation: activation,
    fill: fill, stroke: stroke, shape: shape, node-size: node-size,
    node-label: node-label, node-label-pos: node-label-pos, values: values,
    show-value-text: show-value-text, dropped: dropped, dimmed: dimmed,
    highlighted: highlighted, exclude: exclude, show-all: show-all,
    bias: bias, node-style: node-style,
  ), rest)
}

#let mlp-gap(label: unset, pitch: unset, ..rest) = mk("mlp-gap", (
  label: label, pitch: pitch,
), rest)

#let mlp-edge(
  from: unset, to: unset,
  style: unset, paint: unset, thickness: unset, dash: unset, opacity: unset,
  arrow: unset, label: unset, sum: unset,
  ..rest,
) = {
  let v = mk("mlp-edge", (
    from: from, to: to, style: style, paint: paint, thickness: thickness,
    dash: dash, opacity: opacity, arrow: arrow, label: label, sum: sum,
  ), rest)
  for k in ("from", "to") {
    if k not in v {
      panic(
        "vinnt: mlp-edge(..) needs `" + k + "`: a node \"name.index\", a "
          + "layer name, or a (layer, index) pair."
      )
    }
  }
  v
}
