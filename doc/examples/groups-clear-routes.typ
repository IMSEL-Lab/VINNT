#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
// Brackets sit below routes that run underneath the stack
#draw-network(
  (conv(name: "a"), conv(name: "b"), conv(name: "c")),
  connections: (connection(from: "a", to: "c", mode: "flat"),),
  groups: (group(from: "a", to: "c", label: "backbone"),),
)
