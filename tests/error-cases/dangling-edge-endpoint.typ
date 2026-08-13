// EXPECT: refers to "hiddn", which is not the name of any layer. Did you mean "hidden"?
#import "../../src/lib.typ": *

#draw-mlp((3, mlp-layer(4, name: "hidden"), 2), edges: (
  mlp-edge(from: "l1", to: "hiddn"),
))
