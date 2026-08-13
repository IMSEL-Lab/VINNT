// Slot math, column layout, collapse mapping and the figure-wide baseline
// rows. Pure functions; no drawing here.

// Slot layout for one column. `count` is the true layer width; when it
// exceeds `cutoff` the column collapses to `collapse-to` slots whose middle
// slot holds the vertical ellipsis. The flow axis is y = 0 and the slots
// center on it.
//
// Returns (collapsed, slots, ys, top, mid, drawn) where `drawn` is an array
// of (slot, neuron, y) with the ellipsis slot removed and `neuron` the true
// 1-based index: for collapse-to 5, slots map to 1, 2, count-1, count.
#let layer-slots(count, cutoff, collapse-to, pitch) = {
  let collapsed = cutoff != none and count > cutoff
  let slots = if collapsed { collapse-to } else { count }
  let top = (slots - 1) * pitch / 2
  let ys = range(slots).map(i => top - i * pitch)
  let mid = int((collapse-to - 1) / 2)
  let drawn = ()
  for i in range(slots) {
    if collapsed and i == mid { continue }
    let neuron = if not collapsed or i < mid { i + 1 } else { count - (slots - 1 - i) }
    drawn.push((slot: i, neuron: neuron, y: ys.at(i)))
  }
  (collapsed: collapsed, slots: slots, ys: ys, top: top, mid: mid, drawn: drawn)
}

// Column x-positions. Each column occupies a width (layer-pitch for layers,
// the gap's own pitch for gaps); centers accumulate half-widths, so two
// plain layers sit one layer-pitch apart.
#let column-xs(widths) = {
  let xs = (0,)
  let x = 0
  for i in range(1, widths.len()) {
    x += widths.at(i - 1) / 2 + widths.at(i) / 2
    xs.push(x)
  }
  xs
}

// The shared caption rows (FINDINGS item 4). Offsets are positive distances
// measured outward from the figure-wide column extent; rows that are empty
// for the whole figure take no space. `act-block` widens the activation row
// for the transfer-function block icons, which are taller than a text line.
#let row-offsets(has-label, has-sub, has-act, has-badge, act-block: false, act-block-half: 0.17) = {
  let rows = (label: none, sub: none, act: none, badge: none)
  let cur = 0.55
  if has-label {
    rows.label = cur
    if has-sub {
      rows.sub = cur + 0.28
      cur += 0.28
    }
    cur += 0.34
  }
  if has-act {
    if act-block { cur += act-block-half }
    rows.act = cur
    cur += 0.34
    if act-block { cur += act-block-half }
  }
  if has-badge { rows.badge = cur }
  rows
}

// `direction: "up"` is a final coordinate swap: layers run bottom to top and
// neuron 1 sits leftmost.
#let map-point(dir, p) = {
  if dir == "up" { (-p.at(1), p.at(0)) } else { (p.at(0), p.at(1)) }
}

// Linear interpolation between two lengths.
#let lerp-length(a, b, t) = a + (b - a) * t
