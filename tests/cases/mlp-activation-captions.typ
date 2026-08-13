#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

// Tier 1 — figure-wide options.
#draw-mlp((4, 16, 16, 3), activation: "relu", bias: true, cutoff: 8)

#v(8mm)

// per-layer activations, arbitrary content in caption style, rows above
#draw-mlp((
  mlp-layer(3),
  mlp-layer(4, activation: "tanh"),
  mlp-layer(2, activation: [my $phi$]),
), label-pos: "above")
