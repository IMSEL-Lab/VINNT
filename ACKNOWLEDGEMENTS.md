# Acknowledgements

VINNT is built on prior work. The following are the works it was built on most directly. 

## PlotNeuralNet — Haris Iqbal and contributors

<https://github.com/HarisIqbal88/PlotNeuralNet>

PlotNeuralNet established the visual language or idea for this style of plotting convolution-style networks. It introduced the
isometric prism standing for a tensor, thickness reading as channel count,
banded blocks for a stage of several convolutions at one resolution, the
left-to-right forward pass with skips arching over it, etc. It became the default look of a method-section
figure across a good part of the literature in academia.

PlotNeuralNet was built on Tikz and LaTeX, with some assistance from Python.

## neural-netz — Edgar Remy

<https://github.com/edgaremy/neural-netz>

neural-netz attempted to bring PlotNeuralNet to Typst, a modern language alternative to LaTeX. VINNT is built directly as a fork of this work.
The bundled AlexNet, LeNet-5, VGG, ResNet, U-Net and FCN-8 examples are lightly edited versions from neural-netz.

If you are looking for the original, it may be worth using directly:

```typ
#import "@preview/neural-netz:0.3.0": draw-network
```

## Also

- [CeTZ](https://typst.app/universe/package/cetz/) does all the actual drawing.
- The default input photograph is [from iNaturalist](https://www.inaturalist.org/observations/205901632),
  with slightly edited colors.