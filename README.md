# Fwrappe - Text Wrapping around Figures in Quarto

Fwrappe (pronounced like the frappe drink, until I can work out how to pronounce *fwr*) is a **F**igure **Wrappe**r for Quarto.

## Motivation

Quarto HTML outputs don't support wrapping text around figures.
However, people often request this feature:

- <https://github.com/quarto-dev/quarto-cli/discussions/11053>
- <https://forum.posit.co/t/picture-and-text-side-by-side-on-quarto/147682>

It is possible to use a manual solution as described in the above issues.
The reason Fwrappe is a better option is because:

- Fwrappe is portable to both HTML and PDF (LaTeX) formats
- Fwrappe wraps entire figures instead of just images. This means that figure captions look correct
- Fwrappe provides an auto-wrap feature so you don't need to modify each figure
- You don't need to use or learn CSS and/or LaTeX yourself

## Installing

```bash
quarto add multimeric/fwrappe
```

This will install the extension under the `_extensions` subdirectory.
If you're using version control, you will want to check in this directory.

## Basic Usage

First you will need to enable the filter by adding it to the filters list in your YAML metadata, **making sure you put `quarto` in the list preceding it**:
```yaml
filters:
  - quarto
  - fwrappe
```

Then, you can add the `.wrap-left` or `.wrap-right` classes to your images, to make text wrap around them.
```md
![](https://live.staticflickr.com/5042/5362356515_9d782e74f6_b.jpg){width=200 .wrap-left}
```

`.wrap-left` means "the figure will sit on the left of the page, and the text will wrap around it to the right".
This is a little confusing, I realise.

The end product will look [like this](https://multimeric.github.io/Fwrappe/example.html).

## Specifying Width

For the HTML format, you can optionally specify a figure width [the standard way](https://quarto.org/docs/authoring/figures.html#figure-sizing), which will determine how much text can fit around it.

However, for the LaTeX format, it is *mandatory* to provide a width.
This is for various technical reasons:

## Advanced Config

You can also customize the extension using the `fwrappe` metadata key in your documents.
This supports two different options: `auto` and `margin`.

### `margin`

> [!NOTE]
> `margin` is not currently supported for the LaTeX/PDF format. Instead, the figure will have a margin of `\intextsep` at the top, and `\columsep` at the sides


The `margin` parameter can be set the the number of pixels to leave as a space around the text-wrapped image.
For example:
```
---
fwrappe:
  margin: 200
---
```

[Here's an example of this obscenely large margin](https://multimeric.github.io/Fwrappe/margin.html).

You can also customize different parts of the margin by providing a dictionary with four keys:

```
---
fwrappe:
  margin:
    top: 0
    right: 100
    bottom: 100
    left: 0
---
```

[Here's an example where the bottom and right margins are wide, but the top and left margins are zero](https://multimeric.github.io/Fwrappe/complex_margin.html).

### `auto`

Setting `auto` to `left` or `right` will automatically make all figures text wrap in the specified direction:

```
---
fwrappe:
  auto: "left"
---
```
You can disable this selectively by adding a `.nowrap` class to some images.
This is demonstrated [in the following example](https://multimeric.github.io/Fwrappe/example.html).