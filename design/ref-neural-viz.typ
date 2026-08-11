// REFERENCE — neural-viz's own style, rendered so it can be judged directly
// against design/fig2-overview.png. Not a proposal. Kept only for comparison.

#import "@preview/neural-viz:0.1.0": *

#set page(width: auto, height: auto, margin: 6mm)

#graph-canvas({
  let ds = make-image-dataset("RGB\nframe", pos: (0.0, 0.0))
  let enc = make-trapezoid("Backbone", after: ds, gap: 1.2)
  let lat = make-latent-space("Neck", after: enc, gap: 1.2)
  let head = make-box("Head", after: lat, gap: 1.2)
  let out = make-dataset("Detections", after: head, gap: 1.2)

  draw-node(ds)
  draw-node(enc)
  draw-node(lat)
  draw-node(head)
  draw-node(out)

  draw-arrows((
    make-arrow(ds, enc, label: [input]),
    make-arrow(enc, lat, label: [P3-P5]),
    make-arrow(lat, head),
    make-arrow(head, out),
  ))
})
