#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

#let blk(lbl, h: 2.4, d: 1.4) = conv(widths: (0.4,), height: h, depth: d, label: lbl, offset: 1.3,
)
#let inp = input(height: 3, depth: 3, label: "in", show-connection: true)
#let out = concat(height: 3, depth: 3, label: "out", offset: 1.6)

#draw-network((
  inp,
  branch(spread: 6, branches: ((blk("a"),), (blk("b"),))),
  out,
))

#v(8mm)

#draw-network((
  inp,
  branch(spread: 9, branches: ((blk("a"),), (blk("b"),), (blk("c"),))),
  out,
))

#v(8mm)

#draw-network((
  inp,
  branch(spread: 5, spread-mode: "depth", branches: ((blk("a"),), (blk("b"),))),
  out,
))

#v(8mm)

#draw-network((
  inp,
  branch(spread: 7, spread-mode: "depth", branches: ((blk("a"),), (blk("b"),), (blk("c"),))),
  out,
))

#v(8mm)

#draw-network((
  inp,
  branch(spread: 10, spread-mode: "depth",
    branches: ((blk("a"),), (blk("b"),), (blk("c"),), (blk("d"),))),
  out,
))

#v(8mm)

#draw-network((
  inp,
  branch(spread: 8, spread-mode: "depth", branches: (
    (blk("tall", h: 4.2, d: 1.0),),
    (blk("wide", h: 1.6, d: 3.2),),
    (blk("small", h: 1.2, d: 0.8),),
  )),
  out,
))

#v(8mm)

#draw-network((
  inp,
  branch(spread: 5, spread-mode: "depth", branches: (
    (blk("a1"), blk("a2"), blk("a3")),
    (blk("b1"),),
  )),
  out,
))

#v(8mm)

#draw-network((
  inp,
  blk("shared"),
  branch(spread: 6, open: "end", branches: (
    (blk("task a"), output(label: "out a", height: 2, depth: 0.3, offset: 1.2)),
    (blk("task b"), output(label: "out b", height: 2, depth: 0.3, offset: 1.2)),
  )),
))

#v(8mm)

#draw-network((
  branch(spread: 6, branches: (
    (input(height: 2.6, depth: 2.6, label: "sensor a", show-connection: true),),
    (input(height: 2.6, depth: 2.6, label: "sensor b", show-connection: true),),
  )),
  concat(height: 2.8, depth: 2.8, label: "fuse", offset: 1.6),
  blk("shared"),
  branch(spread: 6, open: "end", branches: (
    (blk("boxes"),),
    (blk("classes"),),
  )),
))
