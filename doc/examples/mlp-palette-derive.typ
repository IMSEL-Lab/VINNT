#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-mlp((4, 6, 6, 3),
  palette: mlp-palettes.warm + (output: rgb("#A49137").lighten(50%)))
