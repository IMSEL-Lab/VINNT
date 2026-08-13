// EXPECT: `weights` matrix 1 (layers 1 -> 2) must be 3 x 2
#import "../../src/lib.typ": *

#draw-mlp((2, 3), weights: (((0.5, 0.5), (0.5, 0.5)),))
