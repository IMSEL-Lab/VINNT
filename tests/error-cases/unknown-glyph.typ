// EXPECT: activation "rleu" on layer 2 ("l2") has no glyph, and activation-style "glyph" needs one. Did you mean "relu"?
#import "../../src/lib.typ": *

#draw-mlp((2, 3, 2), activation: "rleu", activation-style: "glyph")
