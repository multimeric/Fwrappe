# Fwrappe - Text Wrapping around Figures in Quarto

Fwrappe (pronounced like the frappe drink, until I can work out how to pronounce *fwr*) is a **F**igure **Wrappe**r for Quarto.

## Motivation

Quarto HTML outputs don't support wrapping text around figures.
However, people often request this feature:

- <https://github.com/quarto-dev/quarto-cli/discussions/11053>
- <https://forum.posit.co/t/picture-and-text-side-by-side-on-quarto/147682>

Enter Fwrappe.

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

The end product will look [like this](https://multimeric.github.io/Fwrappe/example.html)

## Advanced Config

You can also customize the extension using the `fwrappe` metadata key in your documents.
This supports two different options: `auto` and `margin`.

### `margin`

Setting `margin` to CSS length specifier such as `10px` or `2em` will let you determine the size of the margin around a text-wrapped image. For example:
```
---
fwrappe:
  margin: "200px"
---
```

[Here's an example of this obscenely large margin](https://multimeric.github.io/Fwrappe/margin.html)

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
