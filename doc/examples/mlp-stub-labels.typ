#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-mlp((2, 4, 2), io-stubs: true,
  stub-labels: (side, i) => if side == "in" { $s_#i$ } else { $p_#i$ })
