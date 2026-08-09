// Constructors: the one way a layer, connection or group is written.

#import "validate.typ": check-layer

// A private sentinel, so an absent option stays absent rather than becoming `none`.
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
