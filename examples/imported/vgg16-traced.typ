#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

// VGG-16, imported from the pretrained torchvision checkpoint.
//
//   uv run tools/import_model.py --torchvision vgg16 --weights DEFAULT \
//       --collapse -o vgg16.json
//
// `--collapse` folds runs of identical adjacent layers into one block with a
// repeat count. Labels are the model's own Sequential indices, run diagonally
// via `defaults`.

#let data = json("vgg16.json")

#draw-network(
  from-shapes(data, label: "leaf", defaults: (label-orient: "diagonal")),
  groups: groups-from-shapes(data),
  show-legend: true,
  legend-title: "VGG-16 (imported)",
  main-legend: "forward pass",
  show-relu: true,
)
