#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#let curves = ("identity", "step", "sign", "sigmoid", "tanh", "relu",
  "leaky-relu", "elu", "softplus", "gelu", "silu", "saturate")
#draw-mlp(
  curves.map(g => mlp-layer(1, activation: g, label: g,
    fill: rgb("#ECECEC"))),
  activation-style: "block", node-size: 0.24,
  edge-filter: (l, i, j) => false, layer-pitch: 1.3,
)
