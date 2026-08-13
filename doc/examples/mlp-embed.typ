#import "@preview/cetz:0.5.2": canvas, draw
#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#canvas(length: 1cm, {
  mlp-content((3, 4, 2))
  draw.rect((-0.6, -1.3), (4.6, 1.3),
    stroke: (paint: rgb("#A2A2A2"), dash: "dashed"))
  draw.content((2, 1.6), text(size: 8pt)[my own canvas])
})
