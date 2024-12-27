DEFAULT_CONFIG = {
  auto = false,
  margin = {
    top = 30,
    right = 30,
    bottom = 30,
    left = 30
  }
}

STYLES = [[<style>
  .quarto-figure.wrap {
      margin-top: %spt;
      margin-right: %spt;
      margin-bottom: %spt;
      margin-left: %spt;
  }
  .quarto-figure.wrap-left {
      float: left;
  }
  .quarto-figure.wrap-right {
      float: right;
  }
</style>]]

-- Adds the stylesheet to enable text wrapping
function Pandoc(doc)

  local config = parse_config(doc.meta.fwrappe)

  if quarto.doc.is_format("html") then
    return handle_html(doc, config)
  elseif quarto.doc.is_format("pdf") then
    return handle_tex(doc, config)
  else
    -- No-op for other formats
    return doc
  end
end

function handle_html(doc, config)
  -- Add custom CSS to the document
  local style = string.format(STYLES, config.margin.top, config.margin.right, config.margin.bottom, config.margin.left)
  quarto.doc.include_text("in-header", style)

  return doc:walk({
    Div = function (fig)
      if fig.classes:includes("quarto-figure") then
        -- If autowrap is enabled, add the wrap class to the figure
        if config.auto ~= nil and not fig.classes:includes("nowrap") then
          if config.auto == "left" then
            fig.classes:insert("wrap-left")
          elseif config.auto == "right" then
            fig.classes:insert("wrap-right")
          end
        end

        -- If the image has a wrap-* class, either user defined or added by autowrap, add the .wrap class
        if fig.classes:includes("wrap-left") or fig.classes:includes("wrap-right") then
          fig.classes:insert("wrap")
        end
      end

      return fig
    end
  })
end

--- Finds a single Image nested within a given element
function find_image(el)
  local image = nil
  el:walk({
    Image = function (img)
      -- Error if we find more than one image
      if image ~= nil then
        quarto.log.warning("Found more than one image in a figure, only the last will be used")
      end
      image = img
    end
  })
  if image == nil then
    error("No image found in figure")
  end
  return image
end

--- Converts a size string to a point value
function size_to_pt(size)
  if size:match("pt$") then
    return tonumber(size:sub(1, -3))
  elseif size:match("px$") then
    return tonumber(size:sub(1, -3)) * 0.75
  elseif size:match("%d+$") then
    -- Assume pixels
    return tonumber(size) * 0.75
  elseif size:match("em$") then
    return tonumber(size:sub(1, -3)) * 12
  elseif size:match("ex$") then
    return tonumber(size:sub(1, -3)) * 6
  elseif size:match("cm$") then
    return tonumber(size:sub(1, -3)) * 28.35
  elseif size:match("mm$") then
    return tonumber(size:sub(1, -3)) * 2.835
  elseif size:match("in$") then
    return tonumber(size:sub(1, -3)) * 72
  else
    error("Unknown size unit: " .. size)
  end
end

function handle_tex(doc, config)
  quarto.doc.use_latex_package("wrapfig")

  return doc:walk({
    Div = function (div)
      -- Extract the image width from the figure
      local width = nil
      local found_images = 0
      local direction = nil
      div:walk({
        Image = function (img)
          found_images = found_images + 1 
          if img.attributes.width ~= nil then
            width = size_to_pt(img.attributes.width)
            quarto.log.output("Image size", width)
          end
          if img.classes:includes("wrap-left") then
            direction = "l"
          elseif img.classes:includes("wrap-right") then
            direction = "r"
          elseif config.auto == "left" then
            direction = "l"
          elseif config.auto == "right" then
            direction = "r"
          end
        end
      })
      if found_images ~= 1 or width == nil or direction == nil then
        -- Short-circuit if there:
        -- * is no image, because then this is probably a regular div and not a figure
        -- * is no width defined for the image, because then we can't wrap it in LaTeX as wrapfig requires a width
        -- * are multiple images, because either this div contains multiple figures, or because it's a multi-panel figure and this isn't yet supported
        -- * was no direction class on the image
        return div
      end

      -- The second half of the content is the original figure, modified to be a wrapfigure
      return div:walk({
        RawBlock = function (raw)
          quarto.log.output("Found raw block", raw)
          if raw.format:match("latex") then
            if raw.text:match("\\begin{figure}") then
              raw.text = string.format("\\begin{wrapfigure}{%s}{%fpt}", direction, width)
            elseif raw.text:match("\\end{figure}") then
              raw.text = "\\end{wrapfigure}"
            end
          end
          return raw
        end
      })
    end
  })
end

--- Return the final conraw, with defaults applied
--- @param meta A table obtained from pandoc.meta
function parse_config(meta)
  config = merge_tables(simplify_meta(meta), DEFAULT_CONFIG)
  if pandoc.utils.type(config.margin) == "string" then
    -- Margin can be provided as a single value
    config.margin = {
      top = config.margin,
      right = config.margin,
      bottom = config.margin,
      left = config.margin
    }
  end
  return config
end

--- Takes a table from the pandoc metadata and simplifies all Inlines to strings
function simplify_meta(meta)
    local result = {}
    for i, v in pairs(meta or {}) do
        if pandoc.utils.type(v) == "Inlines" then
            -- Simplify Inlines to strings
            result[i] = pandoc.utils.stringify(v)
        elseif pandoc.utils.type(v) == "table" then
          -- Call recursively when encountering another table
            result[i] = simplify_meta(v)
        else
            result[i] = v
        end
    end
    return result
end

--- Merges one table with another, adding default values if they are not present.
function merge_tables(tbl, default)
  if tbl == nil then
    return default
  end
  for k, v in pairs(default) do
    if tbl[k] == nil then
      tbl[k] = v
    end
  end
  return tbl
end
