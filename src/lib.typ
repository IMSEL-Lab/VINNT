// vinnt: isometric block diagrams of layered neural network architectures.
//
// The public surface, re-exported from the modules that implement it:
//   keys.typ        option tables per layer type, connection and group
//   validate.typ    unknown-option and dangling-name checking
//   ctor.typ        conv(), pool(), connection(), group() and the rest
//   theme.typ       palettes, strokes, fonts and visual constants
//   geom.typ        projection and layout math
//   primitives.typ  prisms, band faces, arrows and labels
//   layers.typ      one draw function per layer type
//   routing.typ     connection paths and inline blocks along them
//   legend.typ      legend defaults and rendering
//   import.typ      from-shapes / groups-from-shapes for traced dumps
//   draw.typ        draw-network, the walk that puts it all together

#import "keys.typ": *
#import "validate.typ": *
#import "ctor.typ": *
#import "geom.typ": depth-shear, min-clear-offset
#import "import.typ": layer-ctors, from-shapes, groups-from-shapes
#import "draw.typ": draw-network
#import "mlp/lib.typ": draw-mlp, mlp-content, mlp-layer, mlp-gap, mlp-edge, mlp-palettes
