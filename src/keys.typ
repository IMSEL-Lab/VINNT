// Option tables: which keys each layer type, connection and group accepts.

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
