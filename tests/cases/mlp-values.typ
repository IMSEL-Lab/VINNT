#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

// 3Blue1Brown mode: fill encodes the value on a white-to-fill ramp; text
// flips to white over dark fills
#draw-mlp((
  mlp-layer(4, fill: rgb("#466A9F"), values: (0.0, 0.35, 0.7, 1.0),
    show-value-text: true),
  mlp-layer(3, fill: rgb("#73000A"), values: (0.15, 0.6, 0.95)),
  mlp-layer(2, fill: rgb("#466A9F"), values: (0.2, 0.85), show-value-text: true),
), node-size: 0.28)
