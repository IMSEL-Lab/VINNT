#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

#draw-network((
  conv(widths: (0.4,), height: 3, depth: 3, label: "conv"),
  convres(widths: (0.4, 0.4, 0.4), height: 3, depth: 3, label: "bottleneck", offset: 1.4),
  conv(widths: (0.4,), height: 3, depth: 3, label: "conv", offset: 1.4),
))

#v(9mm)

#draw-network((
  conv(widths: (0.4,), height: 3, depth: 3, label: "conv"),
  convres(widths: (0.4,), height: 3, depth: 3, label: "bottleneck", repeat: 3, offset: 1.4),
  conv(widths: (0.4,), height: 3, depth: 3, label: "conv", offset: 1.4),
))

#v(9mm)

#draw-network((
  conv(widths: (0.4,), height: 3, depth: 3, label: "x2", repeat: 2),
  convres(widths: (0.4,), height: 3, depth: 3, label: "x6", repeat: 6, offset: 2.2),
  fc(channels: (10,), height: 3, depth: 0.3, label: "fc x4", repeat: 4, offset: 2.4),
))

#v(9mm)

#draw-network((
  conv(widths: (0.4,), height: 3, depth: 3, label: "conv x2", repeat: 2),
  conv(widths: (0.4,), height: 3, depth: 3, label: "conv + pool", offset: 2.0),
  pool(height: 2.4, depth: 2.4),
  conv(widths: (0.4,), height: 2.4, depth: 2.4, label: "conv", offset: 2.2),
))
