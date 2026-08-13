// The activation curve catalog. Each glyph is the bare silhouette of its
// function - curve only, no axes - drawn inside a box of the given size
// centered on `center`. Paths are authored in a normalized [-1, 1] square.
//
// The three smooth-kink curves are deliberately distinct: elu saturates
// left, softplus is everywhere-smooth, and gelu/silu dip below zero before
// the rise.

#import "@preview/cetz:0.5.2": draw
#import "keys.typ": glyph-names

// Resolve an alias to its canonical curve name.
#let canonical(name) = {
  if name == "linear" { "identity" } else if name == "heaviside" { "step" } else if name == "logistic" { "sigmoid" } else if name == "swish" { "silu" } else { name }
}

#let g-pt(center, s, p) = (center.at(0) + p.at(0) * s / 2, center.at(1) + p.at(1) * s / 2)

#let g-poly(center, s, st, pts) = draw.line(..pts.map(p => g-pt(center, s, p)), stroke: st)

#let g-bezier(center, s, st, a, b, c1, c2) = draw.bezier(
  g-pt(center, s, a), g-pt(center, s, b), g-pt(center, s, c1), g-pt(center, s, c2),
  stroke: st,
)

// Draw one glyph. `size` is the full width of the glyph box in canvas units;
// for the in-node style that is ~60% of the node diameter.
#let glyph(name, center, size, paint, thickness: 0.6pt) = {
  let st = (paint: paint, thickness: thickness)
  let n = canonical(name)
  if n == "identity" {
    g-poly(center, size, st, ((-1, -0.85), (1, 0.85)))
  } else if n == "step" {
    // One-sided: baseline at zero, jump to 0.85 at x = 0.
    g-poly(center, size, st, ((-1, 0), (0, 0), (0, 0.85), (1, 0.85)))
  } else if n == "sign" {
    // Symmetric discontinuity: two flat rails joined by a thin jump stroke,
    // so it cannot read as an S at small sizes.
    g-poly(center, size, st, ((-1, -0.8), (0, -0.8)))
    g-poly(center, size, st, ((0, 0.8), (1, 0.8)))
    g-poly(center, size, (paint: paint, thickness: thickness * 0.55), ((0, -0.8), (0, 0.8)))
  } else if n == "sigmoid" {
    g-bezier(center, size, st, (-1, -0.5), (1, 0.5), (0.35, -0.5), (-0.35, 0.5))
  } else if n == "tanh" {
    g-bezier(center, size, st, (-1, -0.85), (1, 0.85), (0.55, -0.85), (-0.55, 0.85))
  } else if n == "relu" {
    g-poly(center, size, st, ((-1, -0.45), (0, -0.45), (1, 0.75)))
  } else if n == "leaky-relu" {
    g-poly(center, size, st, ((-1, -0.75), (0, -0.45), (1, 0.75)))
  } else if n == "elu" {
    g-bezier(center, size, st, (-1, -0.7), (0, -0.25), (-0.5, -0.7), (-0.25, -0.62))
    g-poly(center, size, st, ((0, -0.25), (1, 0.75)))
  } else if n == "softplus" {
    g-bezier(center, size, st, (-1, -0.6), (1, 0.75), (0.25, -0.6), (0.3, 0.05))
  } else if n == "gelu" {
    g-bezier(center, size, st, (-1, -0.5), (-0.1, -0.68), (-0.6, -0.52), (-0.4, -0.68))
    g-bezier(center, size, st, (-0.1, -0.68), (1, 0.75), (0.3, -0.68), (0.45, 0.05))
  } else if n == "silu" {
    g-bezier(center, size, st, (-1, -0.45), (0, -0.72), (-0.6, -0.5), (-0.35, -0.72))
    g-bezier(center, size, st, (0, -0.72), (1, 0.75), (0.4, -0.72), (0.5, 0.0))
  } else if n == "saturate" {
    g-poly(center, size, st, ((-1, -0.7), (-0.4, -0.7), (0.4, 0.7), (1, 0.7)))
  } else {
    panic(
      "vinnt: no glyph named " + repr(name) + "; the catalog is "
        + glyph-names.join(", ") + "."
    )
  }
}
