#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  conv(channels: ("", "1/8")),
  conv(channels: ("K", "1/16")),
))
