#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

// the Goodfellow orientation: captions move left, title stays on top
#draw-mlp((3, 4, 2), direction: "up", layer-labels: auto, activation: "relu",
  title: [upward])

#v(8mm)

// collapsed column in up mode: badge sits right of the rows
#draw-mlp((4, 12, 3), direction: "up", cutoff: 8)
