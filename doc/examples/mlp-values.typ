#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-mlp((
  mlp-layer(3, values: (0.20, 0.95, 0.50), show-value-text: true),
  mlp-layer(4, values: (0.70, 0.10, 0.85, 0.40), show-value-text: true),
  mlp-layer(2, values: (0.05, 0.90), show-value-text: true),
), node-size: 0.26)
