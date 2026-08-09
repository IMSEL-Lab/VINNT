#import "../../src/lib.typ": *

#set page(width: auto, height: auto, margin: 5mm)

#draw-network((
    input(image: "default"),
    conv(offset: 2),
    conv(offset: 2),
    pool(),
    conv(widths: (1, 1), offset: 3)
))
