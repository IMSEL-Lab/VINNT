#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

// Tier 2 — per-layer constructors; cutoff 6 collapses the 8-wide layers.
#draw-mlp((
  mlp-layer(4,  label: "input"),
  mlp-layer(8,  label: "h1", activation: "relu"),
  mlp-layer(8,  label: "h2", activation: "relu"),
  mlp-layer(3,  label: "output", activation: "softmax"),
), bias: true, cutoff: 6)

#v(8mm)

// collapse-to 7 keeps three neurons each side; badges under every column
#draw-mlp((4, 12, 3), cutoff: 8, collapse-to: 7, count-badges: true)

#v(8mm)

// show-all exempts one layer from the figure cutoff
#draw-mlp((3, mlp-layer(11, show-all: true), 2))
