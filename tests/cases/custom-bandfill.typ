#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

#draw-network((
  custom(
    widths: (0.3, 0.3), height: 4, depth: 4,
    fill: rgb("#4ECDC4"), opacity: 0.9,
    label: "inherited",
  ),custom(
    widths: (0.3, 0.3), height: 4, depth: 4,
    fill: rgb("#4ECDC4"), opacity: 0.9,
    bandfill: rgb("#FFE66D"),
    label: "bandfill",
    offset: 1.5,
  ),custom(
    widths: (0.3, 0.3), height: 4, depth: 4,
    fill: rgb("#4ECDC4"), opacity: 0.9,
    show-relu: true,
    label: "explicit",
    offset: 1.5,
  ),
),
show-relu: true,
)
