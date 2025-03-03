local M = {}

local image = require("image")

--- @param path string
--- @param tag number|string
--- @param page number
--- @return string
function M.GetFigPath(path, page, tag)
  if not page and not path and not tag then
    return ""
  end

  local extracted_path = vim.fn.fnamemodify(path, ":t:r")
  local fig_path =
    string.format(vim.fn.expand("$HOME") .. "/.local/state/nvim/note/fig/%s_page_%d", extracted_path, tag)
  require("plenary.job")
    :new({
      command = "pdftoppm",
      args = {
        "-f",
        tostring(page),
        "-l",
        tostring(page),
        "-png",
        "-rx",
        "200",
        "-ry",
        "200",
        "-singlefile",
        path,
        fig_path,
      },
      on_exit = function(j, return_val)
        if return_val == 0 then
          print("PDF page converted successfully")
        else
          print("Error converting PDF page: " .. table.concat(j:stderr_result(), "\n"))
        end
      end,
    })
    :start()
  -- local abs_fig_path = vim.fn.system(string.format('realpath "%s.png"', fig_path))
  return vim.fn.trim(fig_path)
end

--- @param path string
--- @param tag number|string
function M.TransFigPath(path, tag)
  local extracted_path = vim.fn.fnamemodify(path, ":t:r")
  local fig_path =
    string.format(vim.fn.expand("$HOME") .. "/.local/state/nvim/note/fig/%s_page_%d", extracted_path, tag)
  local abs_fig_path = vim.fn.system(string.format('realpath "%s.png"', fig_path))
  return vim.fn.trim(abs_fig_path)
end

function M.PreviewPDFwithPage(fig_path, windows, ind, size)
  ind = tostring(ind)
  image
    .from_file(fig_path, {
      id = ind, -- optional, defaults to a random string
      -- with_virtual_padding = false, -- optional, pads vertically with extmarks, defaults to false
      window = windows,
      -- optional, binds image to an extmark which it follows. Forced to be true when
      -- `with_virtual_padding` is true. defaults to false.
      -- inline = false,

      -- geometry (optional)
      x = 1,
      y = 1,
      width = size.width,
      height = size.height,
    })
    :render()
end

function M.ClearPDFwithPage(fig_path, windows, ind, size)
  ind = tostring(ind)
  image
    .from_file(fig_path, {
      id = ind, -- optional, defaults to a random string
      with_virtual_padding = false, -- optional, pads vertically with extmarks, defaults to false
      window = windows,

      -- optional, binds image to an extmark which it follows. Forced to be true when
      -- `with_virtual_padding` is true. defaults to false.
      inline = false,

      -- geometry (optional)
      x = 1,
      y = 1,
      width = size.width,
      height = size.height,
    })
    :clear()
end

-- --- test example
--
-- local path = vim.fn.expand(
--   "~/Desktop/大二班团事业/寒假_情系母校/2024-2025“雅望南归”寒假回访计划（V0111).pdf"
-- )
-- local page = 1
-- local fig_path = M.GetFigPath(path, page)
-- local windows = vim.api.nvim_get_current_win()
-- local width = vim.api.nvim_win_get_width(windows) / 10
-- local height = vim.api.nvim_win_get_height(windows) / 10
-- local size = { width = width, height = height }
--
-- -- M.PreviewPDFwithPage(fig_path, windows, 1, size)
--
-- M.ClearPDFwithPage(fig_path, windows, 1, size)

return M
