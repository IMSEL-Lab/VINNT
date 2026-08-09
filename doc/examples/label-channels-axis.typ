#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  conv(channels: (64, 128)),
  conv(channels: (128, 64)),
  conv(channels: (256, 32)),
))
