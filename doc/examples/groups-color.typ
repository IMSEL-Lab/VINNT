#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network(
  (conv(name: "a"), conv(name: "b"), conv(name: "c"), conv(name: "d")),
  groups: (
    group(from: "a", to: "b", label: "backbone", color: rgb("#73000A")),
    group(from: "c", to: "d", label: "head", color: rgb("#466A9F")),
  ),
)
