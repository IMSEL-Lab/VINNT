#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

#draw-network((
    input(image: "default"),
    conv(offset: 2), // Next layers are automatically connected with arrows
    conv(offset: 2),
    pool(), // Pool layers are sticked to previous convolution block (by default))
    conv(widths: (1, 1), offset: 3) // you can offset layers
))