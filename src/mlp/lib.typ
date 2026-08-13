// The public surface of the MLP renderer.
//   keys.typ      option tables, figure defaults, glyph catalog names
//   validate.typ  unknown-option, index-range and endpoint checking
//   ctor.typ      mlp-layer(), mlp-gap(), mlp-edge()
//   theme.typ     mlp-palettes and visual constants
//   geom.typ      slot math, collapse mapping, baseline rows
//   glyphs.typ    the activation curve catalog
//   edges.typ     edge enumeration, weight encoding, extra-edge routing
//   draw.typ      mlp-content and draw-mlp

#import "draw.typ": draw-mlp, mlp-content
#import "ctor.typ": mlp-layer, mlp-gap, mlp-edge
#import "theme.typ": mlp-palettes
