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
  -- This is the CSS that actually affects the layout
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
          fig.classes:insert("wrap")
          fig.classes:insert("wrap-left")
        elseif wrap == "right" then
          fig.classes:insert("wrap")
          fig.classes:insert("wrap-right")
        end
      end

      return fig
    end
  })

  return doc
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

function handle_tex(doc, config)
  quarto.doc.use_latex_package("wrapfig")
  quarto.doc.use_latex_package("calc")

  return doc:walk({
    Div = function (div)
      -- Find the first div that contains an image and a figure environment
      if contains_element(div, function (el)
        return el.t == "Image"
      end) and contains_element(div, function(el)
        return el.t == "RawBlock" and el.text:match("begin{figure}")
      end) then

      -- The first half of the content is a copy of the entire figure definition into a savebox to measure its width
      pre_content = pandoc.List({
        pandoc.RawBlock("latex", "\\newsavebox{\\imgbox}"),
        pandoc.RawBlock("latex", "\\sbox{\\imgbox}{"),
        div,
        pandoc.RawInline("latex", "}")
      }) 
      -- ..  pandoc.utils.blocks_to_inlines(div.content):walk({
      --     RawInline = function (raw)
      --       -- Remove double newlines
      --       raw.text = raw.text:gsub("%s+", " ")
      --       raw.text = raw.text:gsub("%%", "")
      --       if raw.format == "latex-merge" then
      --         raw.format = "latex"
      --       end
      --       return raw
      --     end,
      --     LineBreak = function (linebreak)
      --       -- Remove line breaks
      --       return pandoc.List({})
      --     end
      --   }) .. pandoc.List({
      --   pandoc.RawInline("latex", "}")
      -- })

      -- The second half of the content is the original figure, modified to be a wrapfigure
      post_content = div:walk({
        RawBlock = function (fig)
          if fig.format:match("latex") then
            -- Convert the figure environment to a wrapfigure
            if fig.text:match("\\begin{figure}") then
              fig.text = "\\begin{wrapfigure}{r}{\\wd\\imgbox}"
            elseif fig.text:match("\\end{figure}") then
              fig.text = "\\end{wrapfigure}"
            end
          end
          return fig
        end
      })

      -- post_content.content:insert(1, pandoc.Plain(pre_content))

      quarto.log.output("content:", post_content)
      -- return post_content
      -- quarto.log.output("Post content:", post_content)

      -- return pandoc.Plain(pre_content .. post_content.content)
      return pre_content .. post_content.content
        
      end
    end
  })
end

--- Returns true if the element contains a child element that 
--- satisfies the given predicate.
--- @param element A pandoc element to test
--- @param predicate A function that takes a child element and returns true or false
function contains_element(element, predicate)
  local result = false
  element:walk({
    Inline = function (inline)
      if predicate(inline) then
        result = true
      end
    end,
    Block = function (block)
      if predicate(block) then
        result = true
      end
    end
  })
  return result
end

--- Return the final config, with defaults applied
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
