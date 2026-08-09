#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

#let data = json("vit_b_16.json")

#let attn-color = rgb("#1F414D")

#draw-network(
  from-shapes(
    data,
    label: none,
    defaults: (label-orient: "diagonal"),
    by-op: (
      MultiheadAttention: (fill: attn-color, opacity: 0.9, legend: "Self-attention"),
      Conv2d: (legend: "Patch embedding (16×16, stride 16)"),
      Linear: (legend: "MLP projection"),
    ),
  ),
  groups: groups-from-shapes(data).map(g => group(
    from: g.from, to: g.to, label: g.label.split("_").last(),
  )),
  show-legend: true,
  legend-title: "ViT-B/16 (imported)",
  main-legend: "forward pass",
  show-relu: true,
)
