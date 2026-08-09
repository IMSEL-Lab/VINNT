#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

#draw-network((
  input(image: "default", channels: ("1", "128"), width: 0.2, height: 8, depth: 8, name: "input"),
  
  conv(channels: ("16", "128"), widths: (0.4,), height: 8, depth: 8, name: "down1", offset: 1.9),
  pool(height: 6.5, depth: 6.5, name: "pool1"),
  
  conv(channels: ("32", "64"), widths: (0.5,), height: 6.5, depth: 6.5, name: "down2"),
  pool(height: 5, depth: 5, name: "pool2"),
  
  conv(channels: ("64", "32"), widths: (0.8,), height: 5, depth: 5, name: "down3"),
  pool(height: 3.5, depth: 3.5, name: "pool3"),
  
  conv(channels: ("128", "16"), widths: (1.6,), height: 3.5, depth: 3.5, name: "down4"),
  pool(height: 2.5, depth: 2.5, name: "pool4"),
  
  conv(channels: ("256", "8"), widths: (3.2,), height: 2.5, depth: 2.5, name: "middle"),
  
  conv(channels: ("128", "64"), widths: (1.6,), height: 3.5, depth: 3.5, name: "up1", offset: 1.5),
  
  conv(channels: ("64", "32"), widths: (0.8,), height: 5, depth: 5, name: "up2", offset: 1.5),
  
  conv(channels: ("32", "64"), widths: (0.5,), height: 6.5, depth: 6.5, name: "up3", offset: 1.5),
  
  conv(channels: ("16", "128"), widths: (0.4,), height: 8, depth: 8, name: "up4", offset: 1.5),
  
  conv(channels: ("3", "128"), widths: (0.2,), height: 8, depth: 8, name: "output"),
), connections: (
  connection(from: "down4", to: "up1", type: "skip", mode: "air", pos: 2.5, touch-layer: true),
  connection(from: "down3", to: "up2", type: "skip", mode: "air", pos: 3.4, touch-layer: true),
  connection(from: "down2", to: "up3", type: "skip", mode: "air", pos: 4.1, touch-layer: true),
  connection(from: "down1", to: "up4", type: "skip", mode: "air", pos: 4.8, touch-layer: true),
))
