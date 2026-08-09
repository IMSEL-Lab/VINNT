#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network(
  (
    conv(name: "in", label: "in"),
    branch(spread: 5, branches: (
      (conv(name: "a", label: "a"),),
      (conv(name: "b", label: "b"),),
    )),
    concat(name: "cat", label: "concat"),
  ),
  connections: (
    connection(from: "in", to: "cat", mode: "flat",
     color: rgb("#73000A"), legend: "bypass"),
  ),
  groups: (group(from: "a", to: "b", label: "parallel paths"),),
  show-legend: true,
)
