#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-mlp((
  3,
  mlp-layer(5, bias: false),
  5,
  2,
), bias: true)
