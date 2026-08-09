#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

// repeat: N draws N identical copies of one block in series. It describes one
// layer entry, not a run of them. Both rows below are the same architecture:
// the first widens one block via `widths`, the second declares the repeat.

// Faked: three entries in widths. Reads as one wide block.
#draw-network((
  conv(widths: (0.4,), height: 3, depth: 3, label: "conv"),
  convres(widths: (0.4, 0.4, 0.4), height: 3, depth: 3, label: "bottleneck", offset: 1.4),
  conv(widths: (0.4,), height: 3, depth: 3, label: "conv", offset: 1.4),
))

#v(9mm)

// Declared: one block, repeated three times.
#draw-network((
  conv(widths: (0.4,), height: 3, depth: 3, label: "conv"),
  convres(widths: (0.4,), height: 3, depth: 3, label: "bottleneck", repeat: 3, offset: 1.4),
  conv(widths: (0.4,), height: 3, depth: 3, label: "conv", offset: 1.4),
))

#v(9mm)

// Counts and layer types, to check the marker and the stack stay legible.
//   repeat: 2 is the smallest that draws anything
//   repeat: 6 is deep enough to test that the ghosts do not swamp the block
//   repeat works on any block type, not only the ones taking `widths`
#draw-network((
  conv(widths: (0.4,), height: 3, depth: 3, label: "x2", repeat: 2),
  convres(widths: (0.4,), height: 3, depth: 3, label: "x6", repeat: 6, offset: 2.2),
  fc(channels: (10,), height: 3, depth: 0.3, label: "fc x4", repeat: 4, offset: 2.4),
))

#v(9mm)

// pool and unpool attach to the block before them, so repeat is ignored on
// them. For a repeated conv followed by a pool, two plain convs carry the
// repeat and the third is drawn on its own with the pool attached.
#draw-network((
  conv(widths: (0.4,), height: 3, depth: 3, label: "conv x2", repeat: 2),
  conv(widths: (0.4,), height: 3, depth: 3, label: "conv + pool", offset: 2.0),
  pool(height: 2.4, depth: 2.4),
  conv(widths: (0.4,), height: 2.4, depth: 2.4, label: "conv", offset: 2.2),
))
