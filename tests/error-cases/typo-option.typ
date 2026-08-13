// EXPECT: unknown mlp-layer option "shpae" on layer 2. Did you mean "shape"?
#import "../../src/lib.typ": *

#draw-mlp((3, mlp-layer(4, shpae: "square"), 2))
