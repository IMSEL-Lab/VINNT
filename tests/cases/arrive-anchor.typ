#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

// arrive-offset spreads touch-layer arrivals along the landing edge chosen by
// the routing mode; `auto` spaces each fan evenly, ordered by route start.

#let src(n) = conv(widths: (0.3,), height: 2.5, depth: 2.5,
  name: "s" + str(n), label: "s" + str(n), offset: 1.1,
)

#let cat = concat(height: 3.2, depth: 3.2, name: "cat", label: "concat", offset: 2.6)

// Three routes fanning onto the top edge, spaced by hand.
#draw-network(
  (src(1), src(2), src(3), cat),
  connections: (
    connection(from: "s1", to: "cat", touch-layer: true, pos: auto, arrive-offset: -0.35),
    connection(from: "s2", to: "cat", touch-layer: true, pos: auto, arrive-offset: 0),
    connection(from: "s3", to: "cat", touch-layer: true, pos: auto, arrive-offset: 0.35),
  ),
)

#v(9mm)

// The same three, spaced automatically.
#draw-network(
  (src(1), src(2), src(3), cat),
  connections: (
    connection(from: "s1", to: "cat", touch-layer: true, pos: auto, arrive-offset: auto),
    connection(from: "s2", to: "cat", touch-layer: true, pos: auto, arrive-offset: auto),
    connection(from: "s3", to: "cat", touch-layer: true, pos: auto, arrive-offset: auto),
  ),
)

#v(9mm)

// Five routes; auto respaces the fan.
#draw-network(
  (src(1), src(2), src(3), src(4), src(5), cat),
  connections: (
    connection(from: "s1", to: "cat", touch-layer: true, pos: auto, arrive-offset: auto),
    connection(from: "s2", to: "cat", touch-layer: true, pos: auto, arrive-offset: auto),
    connection(from: "s3", to: "cat", touch-layer: true, pos: auto, arrive-offset: auto),
    connection(from: "s4", to: "cat", touch-layer: true, pos: auto, arrive-offset: auto),
    connection(from: "s5", to: "cat", touch-layer: true, pos: auto, arrive-offset: auto),
  ),
)
