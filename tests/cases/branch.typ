#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

#let c(lbl) = conv(widths: (0.4,), height: 2.4, depth: 2.4, label: lbl, offset: 1.3)
#let inp = input(height: 3, depth: 3, label: "in", show-connection: true)
#let out = concat(height: 3, depth: 3, label: "concat", offset: 1.3)

#draw-network((inp, branch(spread: 6, branches: ((c("a"),), (c("b"),))), out))

#v(9mm)

#draw-network((
  inp,
  branch(spread: 6, branches: (
    (c("a1"), c("a2"), c("a3")),
    (c("b1"),),
  )),
  out,
))

#v(9mm)

#draw-network((
  inp,
  branch(spread: 9, branches: ((c("a"),), (c("b"),), (c("c"),))),
  out,
))

#v(9mm)

#draw-network((
  inp,
  branch(spread: 10, branches: (
    (
      c("a1"),
      branch(spread: 4, branches: ((c("a2"),), (c("a3"),))),
    ),
    (c("b1"),),
  )),
  out,
))
