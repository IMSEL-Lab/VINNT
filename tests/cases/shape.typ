#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

// shape: geometry derived from (channels, height, width), both axes
// logarithmic:
//   height, depth = 1.2 * log2(spatial) - 3.2
//   width         = 0.075 * log2(channels)

// Derived and hand-written, side by side; the second spells out the mapping
// exactly, so the two are pixel-identical.
#let hd = 1.2 * calc.log(40, base: 2) - 3.2
#let wd = 0.075 * calc.log(256, base: 2)
#draw-network((
  conv(shape: (256, 40, 40), label: "shape"),
  conv(height: hd, depth: hd, widths: (wd,), label: "by hand", offset: 1.6),
))

#v(9mm)

// A pyramid spanning 640 down to 20, an order of magnitude and a half, with no
// sizes given anywhere.
#draw-network((
  conv(shape: (3, 640, 640), label: "640"),
  conv(shape: (16, 320, 320), label: "320", offset: 1.4),
  conv(shape: (64, 160, 160), label: "160", offset: 1.4),
  convres(shape: (128, 80, 80), label: "80", offset: 1.4),
  convres(shape: (256, 40, 40), label: "40", offset: 1.4),
  convres(shape: (512, 20, 20), label: "20", offset: 1.4),
))

#v(9mm)

// Shape supplies defaults, not values, so manual control survives field by
// field. All three below share one shape and differ only in what they override.
#draw-network((
  conv(shape: (256, 40, 40), label: "all derived"),
  conv(shape: (256, 40, 40), height: 5, label: "height forced", offset: 1.8),
  conv(shape: (256, 40, 40), widths: (1.2,), label: "width forced", offset: 1.8),
))

#v(9mm)

// Non-square feature maps: height and depth come from the two spatial extents
// independently.
#draw-network((
  conv(shape: (64, 320, 80), label: "320 x 80"),
  conv(shape: (64, 80, 320), label: "80 x 320", offset: 2.0),
))
