#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

// dropped (X, edges omitted), dimmed, highlighted (accent ring), excluded
#draw-mlp((
  mlp-layer(4, dropped: (2,)),
  mlp-layer(6, dropped: (1,), dimmed: (3,), highlighted: (5,), exclude: (6,)),
  mlp-layer(3, highlighted: (1,)),
))
