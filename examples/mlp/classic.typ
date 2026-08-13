#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 6mm)

// The fig5 lecture-slide MLP, built with the real API. Hidden layers wider
// than the cutoff collapse automatically and state their true width in the
// badge row; `bias: true` adds the bias nodes.
#draw-mlp((
  mlp-layer(4, label: "input"),
  mlp-layer(8, label: "h1", activation: "ReLU"),
  mlp-layer(8, label: "h2", activation: "ReLU"),
  mlp-layer(3, label: "output", activation: "softmax"),
), bias: true, cutoff: 6, count-badges: true)
