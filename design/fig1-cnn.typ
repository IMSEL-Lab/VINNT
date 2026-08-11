// FIGURE 1 — a plain CNN.
//
// The constraint. This already works today, and whatever the API becomes, this
// source must keep compiling or every existing user is broken.

#import "../src/lib.typ": *

#set page(width: auto, height: auto, margin: 6mm)

// NOTE. Every pool carries the shape it PRODUCES, which is the shape the block
// after it consumes. A pool that downsamples 128 -> 64 is drawn at 64, flush
// with the conv it feeds. Omitting `shape:` here falls back to a fixed default
// size and draws a pool that is visibly the wrong height, which is wrong in
// every figure. See FINDINGS.md item 10 — the library should infer this from
// the following block rather than making the user restate it.

#draw-network((
  input(image: "default", height: 5, depth: 5, label: "Input", name: "img"),
  conv(shape: (64, 128, 128), channels: (64, 128), label: "conv1", name: "c1", offset: 1.4),
  pool(shape: (64, 64, 64), name: "p1"),
  conv(shape: (128, 64, 64), channels: (128, 64), label: "conv2", name: "c2"),
  pool(shape: (128, 32, 32), name: "p2"),
  conv(shape: (256, 32, 32), channels: (256, 32), label: "conv3", name: "c3"),
  pool(shape: (256, 16, 16), name: "p3"),
  conv(shape: (512, 16, 16), channels: (512, 16), label: "conv4", name: "c4"),
  gap(name: "gap"),
  fc(channels: ("1000",), label: "fc", name: "fc1"),
  softmax(label: "softmax", name: "sm"),
), show-relu: true)
