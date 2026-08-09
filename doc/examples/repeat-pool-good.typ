#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  conv(label: "conv x2", repeat: 2),
  conv(label: "conv + pool", offset: 2),
  pool(),
))
