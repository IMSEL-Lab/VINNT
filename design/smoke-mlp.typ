// Scratch smoke sheet for the draw-mlp implementation. Deleted before release.
#import "../src/lib.typ": draw-mlp, mlp-layer, mlp-gap, mlp-edge, mlp-palettes

#set page(width: auto, height: auto, margin: 6mm)

// 1. Tier 0 - bare counts
#draw-mlp((4, 6, 6, 3))
#pagebreak()

// 2. Tier 1 - figure-wide options
#draw-mlp((4, 16, 16, 3), activation: "relu", bias: true, cutoff: 8)
#pagebreak()

// 3. Tier 2 - per-layer constructors (the fig5 target)
#draw-mlp((
  mlp-layer(4,  label: "input"),
  mlp-layer(8,  label: "h1", activation: "relu"),
  mlp-layer(8,  label: "h2", activation: "relu"),
  mlp-layer(3,  label: "output", activation: "softmax"),
), bias: true, cutoff: 6)
#pagebreak()

// 4. Tier 3 - hooks and data
#draw-mlp((4, 8, 3),
  weights: (l, i, j) => calc.sin(l * 7 + i * 3 + j * 1.7),
  node-label: (l, i) => $a_#i^((#l))$,
  edge-style: (l, i, j) => if i == j { (dash: "dashed") },
)
#pagebreak()

// 5. direction up, auto labels, badges everywhere, title
#draw-mlp((3, 5, 2), direction: "up", layer-labels: auto, count-badges: true,
  activation: "tanh", title: [A small MLP], node-label: auto)
#pagebreak()

// 6. glyph catalog sheet, one layer per glyph name (in-node style)
#draw-mlp((
  mlp-layer(3, activation: "identity", label: "identity"),
  mlp-layer(3, activation: "step", label: "step"),
  mlp-layer(3, activation: "sign", label: "sign"),
  mlp-layer(3, activation: "sigmoid", label: "sigmoid"),
  mlp-layer(3, activation: "tanh", label: "tanh"),
  mlp-layer(3, activation: "relu", label: "relu"),
), activation-style: "glyph", layer-pitch: 1.4, node-size: 0.24)
#pagebreak()

#draw-mlp((
  mlp-layer(3, activation: "leaky-relu", label: "leaky-relu"),
  mlp-layer(3, activation: "elu", label: "elu"),
  mlp-layer(3, activation: "softplus", label: "softplus"),
  mlp-layer(3, activation: "gelu", label: "gelu"),
  mlp-layer(3, activation: "silu", label: "silu"),
  mlp-layer(3, activation: "saturate", label: "saturate"),
  mlp-layer(3, activation: "softmax", label: "softmax"),
), activation-style: "glyph", layer-pitch: 1.4, node-size: 0.24)
#pagebreak()

// 7. block style + label-pos above
#draw-mlp((3, 4, 2), activation: "relu", activation-style: "block",
  layer-labels: auto, label-pos: "above")
#pagebreak()

// 8. split style, square inputs, bias (perceptron-ish)
#draw-mlp((
  mlp-layer(3, label: "inputs"),
  mlp-layer(1, label: "neuron", activation: "step", sub: "threshold"),
), activation-style: "split", input-style: "square", bias: true,
  io-stubs: "out", node-size: 0.22)
#pagebreak()

// 9. input arrows + io-stubs out + node-label auto
#draw-mlp((3, 4, 2), input-style: "arrows", io-stubs: "out", node-label: auto)
#pagebreak()

// 10. explicit weight matrices + edge label + matrix labels
#draw-mlp((2, 3, 2),
  weights: (
    ((0.9, -0.4), (0.2, 0.8), (-0.7, 0.1)),
    ((0.5, -0.9, 0.3), (-0.2, 0.6, -0.5)),
  ),
  edge-labels: ((l: 1, i: 1, j: 1, label: auto),),
  matrix-labels: true,
)
#pagebreak()

// 11. random weights, all three encode channels, io-stubs both
#draw-mlp((4, 6, 4), weights: "random", seed: 7,
  weight-encode: ("color", "thickness", "opacity"), io-stubs: true)
#pagebreak()

// 12. mlp-gap with label and pitch
#draw-mlp((
  mlp-layer(4, label: "input"),
  mlp-layer(8, label: "h1"),
  mlp-gap(label: [$times$ 6 identical layers]),
  mlp-layer(8, label: "h48"),
  mlp-layer(3, label: "output"),
), cutoff: 6)
#pagebreak()

// 13. extra edges: skip arc with sum, recurrent loop, single restyled edge,
//     arc-below skip
#draw-mlp((3, 5, 5, 2),
  edges: (
    mlp-edge(from: "l1", to: "l3", sum: true, label: [skip]),
    mlp-edge(from: "l2", to: "l2", style: "loop"),
    mlp-edge(from: "l2.1", to: "l3.5", style: "arc-below"),
    mlp-edge(from: (1, 2), to: (2, 3), paint: rgb("#73000A"), thickness: 1.2pt),
  ),
)
#pagebreak()

// 14. node states: dropped, dimmed, highlighted, exclude
#draw-mlp((
  mlp-layer(5, dropped: (2,), dimmed: (4,), label: "states"),
  mlp-layer(5, highlighted: (1,), exclude: (3,), label: "more"),
  mlp-layer(2, label: "out"),
))
#pagebreak()

// 15. values mode (3B1B), value text, custom palette dict
#draw-mlp((
  mlp-layer(4, values: (0.05, 0.4, 0.85, 1.0), show-value-text: true),
  mlp-layer(3, values: (0.6, 0.1, 0.95), show-value-text: true),
), palette: (hidden: rgb("#466A9F"), input: rgb("#466A9F")), node-size: 0.24)
#pagebreak()

// 16. edge-filter (banded connectivity) + representative edge label
#draw-mlp((4, 4, 4),
  edge-filter: (l, i, j) => calc.abs(i - j) <= 1,
  edge-labels: ((l: 1, i: 2, j: 2, label: $w_22$),),
)
#pagebreak()

// 17. warm and cold palettes side by side
#draw-mlp((3, 4, 2), palette: "warm")
#draw-mlp((3, 4, 2), palette: "cold")
#pagebreak()

// 18. debug grid + node-label left/right + per-layer node-size and fill
#draw-mlp((
  mlp-layer(3, node-label: auto, node-label-pos: "left"),
  mlp-layer(4, node-size: 0.24, fill: rgb("#CED318")),
  mlp-layer(2, node-label: auto, node-label-pos: "right"),
), debug: true, title: [debug])
