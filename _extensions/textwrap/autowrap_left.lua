-- Enables text wrapping for all figures that don't have .nowrap class
function Figure(el)
  if not el.classes:includes("nowrap") then
    el.classes:insert("wrap-left")
  end
  return el
end