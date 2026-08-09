#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 4mm)

#draw-network((
  input(label: "input", height: 3, depth: 3, show-connection: true),
  sum(label: "add", offset: 1.2),
  output(label: "output", height: 3, offset: 1.2),
),
show-legend: true,
)
