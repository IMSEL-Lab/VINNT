// EXPECT: `dropped` index 7 on layer 2 ("l2") is out of range; the layer has neurons 1..4.
#import "../../src/lib.typ": *

#draw-mlp((3, mlp-layer(4, dropped: (7,)), 2))
