// Projection and layout math. Everything here is pure; `ctx` only supplies
// the depth multiplier.

// How far a layer's top and side faces lean right, in canvas units.
#let depth-shear(depth, depth-multiplier: 0.3) = depth * depth-multiplier

// Smallest offset that lets a connection descend between two layers without crossing them.
#let min-clear-offset(depth, depth-multiplier: 0.3) = 2 * depth-shear(depth, depth-multiplier: depth-multiplier)

#let get-depth-offsets(ctx, d) = {
  let s = depth-shear(d, depth-multiplier: ctx.depth-multiplier)
  (s, s)
}

#let get-y-offset-for-center-on-axis(ctx, h, d, axis-y) = {
  let (_, oy) = get-depth-offsets(ctx, d)
  axis-y - h / 2 - oy / 2
}

#let get-perspective-center-y(y-offset, h, oy) = {
  y-offset + h / 2 + oy / 2
}

#let get-layer-anchors(x, y, w, h, ox, oy) = {
  let center-x = x + w/2 + ox/2
  let center-y = y + h/2 + oy/2
  (
    west: (x, center-y),
    east: (x + w + ox, center-y),
    true_west: (x + ox/2, center-y),
    true_east: (x + w + ox/2, center-y),
    north: (center-x, y + h + oy),
    south: (center-x, y),
    anchor: (center-x, center-y),
    near: (center-x, center-y),
    northeast: (x + w + ox, y + h + oy),
    southeast: (x + w + ox, y),
    northwest: (x, y + h + oy),
    southwest: (x, y),
  )
}

#let coord-along-path(start, end, pos: 1.0) = {
  (start.at(0) + (end.at(0) - start.at(0)) * pos,
   start.at(1) + (end.at(1) - start.at(1)) * pos)
}

#let get-circle-boundary-point(from-pt, center-pt, radius) = {
  let dx = center-pt.at(0) - from-pt.at(0)
  let dy = center-pt.at(1) - from-pt.at(1)
  let dist = calc.sqrt(dx * dx + dy * dy)
  if dist > 0 {
    let ux = dx / dist
    let uy = dy / dist
    (center-pt.at(0) - ux * radius, center-pt.at(1) - uy * radius)
  } else {
    (center-pt.at(0) + radius, center-pt.at(1))
  }
}
