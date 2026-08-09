#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

// ViT-B/16, imported from the pretrained torchvision checkpoint.
//
//   uv run tools/import_model.py --torchvision vit_b_16 --weights DEFAULT \
//       --group-depth 3 -o vit_b_16.json
//
// `by-op` separates attention from the MLP projections by the module class
// they came from.

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
    // The importer names each block by its module path; the bracket only needs
    // the index at the end of it.
    from: g.from, to: g.to, label: g.label.split("_").last(),
  )),
  show-legend: true,
  legend-title: "ViT-B/16 (imported)",
  main-legend: "forward pass",
  show-relu: true,
)
