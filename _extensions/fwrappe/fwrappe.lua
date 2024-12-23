DEFAULT_CONFIG = {
  auto = false,
  margin = "30px"
}

STYLES = [[<style>
  .quarto-figure.wrap-left {
      float: left;
      margin: %s;
  }
  .quarto-figure.wrap-right {
      float: right;
      margin: %s;
  }
</style>]]

-- Adds the stylesheet to enable text wrapping
function Pandoc(doc)
  local config = merge_tables(simplify_meta(doc.meta.fwrappe), DEFAULT_CONFIG)

  local style_path = quarto.utils.resolve_path("styles.css")
  -- Customize the margin
  local style = string.format(STYLES, config.margin, config.margin)
  -- Add the styles to the document
  quarto.doc.include_text("in-header", style)

  -- Add the wrap class to images according to the auto parameter.
  -- This seems redundant since we need to copy the wrap class to the figure element later.
  -- However this simplifies the code paths
  doc = doc:walk({
    Image = function (img)
      -- If nowrap is enabled and the image does not have the nowrap class, add the wrap class
      if config.auto ~= nil and not img.classes:includes("nowrap") then
        if config.auto == "left" then
          img.classes:insert("wrap-left")
        elseif config.auto == "right" then
          img.classes:insert("wrap-right")
        end
      end
      return img
    end
  })

  -- Copy the wrap class from the image to the figure
  doc = doc:walk({
    Div = function (fig)
      if fig.classes:includes("quarto-figure") then
        local wrap = false
        pandoc.walk_block(fig, {
          Image = function(img)
            if img.classes:includes("wrap-left") then
              wrap = "left"
            elseif img.classes:includes("wrap-right") then
              wrap = "right"
            end
          end
        })

        if wrap == "left" then
          fig.classes:insert("wrap-left")
        elseif wrap == "right" then
          fig.classes:insert("wrap-right")
        end
      end

      return fig
    end
  })

  return doc
end

--- Takes a table from the pandoc metadata and simplifies it to a table of strings.
--- By default, each key in pandoc metadata is a table of pandoc elements.
function simplify_meta(meta)
    local result = {}
    for i, v in pairs(meta or {}) do
        result[i] = v[1].text
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
