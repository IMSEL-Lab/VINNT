#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

// The full glyph catalog as single-neuron layers, curve inside each node.
#let sheet(names) = draw-mlp(
  names.map(n => mlp-layer(1, activation: n, label: n)),
  activation-style: "glyph", node-size: 0.3, layer-pitch: 1.7,
)

#sheet(("identity", "step", "sign", "sigmoid", "tanh", "relu", "leaky-relu", "elu"))

#v(6mm)

// second half of the catalog, then the aliases
#sheet(("softplus", "gelu", "silu", "saturate", "linear", "heaviside", "logistic", "swish"))

#v(6mm)

// softmax has no per-neuron curve: a layer-spanning bracket instead
#draw-mlp((
  mlp-layer(2),
  mlp-layer(4, activation: "relu"),
  mlp-layer(3, activation: "softmax"),
), activation-style: "glyph")

#v(6mm)

// block style: the transfer-function icon in the activation row
#draw-mlp((2, 3, 2), activation: "tanh", activation-style: "block")
