#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 6mm)

// The Srivastava dropout figure. Crossed-out units are dropped for this
// training step and their edges vanish with them; dimmed units are kept but
// drawn at reduced opacity. The sub-captions carry the per-layer rates.
#draw-mlp((
  mlp-layer(5, label: "input", sub: $p = 0.2$, dropped: (4,)),
  mlp-layer(6, label: "hidden 1", sub: $p = 0.5$, dropped: (2, 5), dimmed: (3,)),
  mlp-layer(6, label: "hidden 2", sub: $p = 0.5$, dropped: (1, 6), dimmed: (4,)),
  mlp-layer(2, label: "output"),
), title: [Dropout: a thinned subnetwork])
