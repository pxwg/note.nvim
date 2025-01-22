-- a note script for editing notes when using chrome
-- keymappings
local map = vim.keymap.set

---@return table {row: number, col: number}
local function GetCursorPosition()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  return { row = row, col = col }
end

---@return string
local function get_file_path()
  local buf = vim.api.nvim_get_current_buf()
  local file_path = vim.api.nvim_buf_get_name(buf)
  file_path = file_path:gsub("^%s+", ""):gsub("%s+$", "")
  return vim.fn.expand("$HOME") .. "/.local/state/nvim/note/" .. file_path:gsub("/", "_") .. ".txt"
end

---@param file_path string
---@return table
local function read_file(file_path)
  local file = io.open(file_path, "r")
  local lines = {}
  if file then
    for line in file:lines() do
      table.insert(lines, line)
    end
    file:close()
  end
  return lines
end

---@param file_path string
---@param lines table
local function write_file(file_path, lines)
  local file = io.open(file_path, "w")
  if file then
    for _, line in ipairs(lines) do
      file:write(line)
      if not line:match("\n$") then
        file:write("\n")
      end
    end
    file:close()
  else
    print("Error: Unable to create file " .. file_path)
  end
end

---@param lines table
---@param lines_to_insert table
---@param pos table {row: number, col: number}
---@return table
local function update_lines(lines, lines_to_insert, pos)
  local updated = false
  local new_lines = {}

  for _, line in ipairs(lines) do
    local row, col = line:match("{(%d+), (%d+),")
    if row and col and tonumber(row) == pos.row and tonumber(col) == pos.col then
      -- Remove the matching line and insert new lines
      updated = true
    else
      table.insert(new_lines, line)
    end
  end

  if updated then
    -- Insert new lines at the position of the removed line
    for _, new_line in ipairs(lines_to_insert) do
      table.insert(new_lines, string.format("{%d, %d, %s}\n", pos.row, pos.col, new_line))
    end
  else
    -- Append new lines at the end if no existing line was updated
    for _, new_line in ipairs(lines_to_insert) do
      table.insert(new_lines, string.format("{%d, %d, %s}\n", pos.row, pos.col, new_line))
    end
  end

  return new_lines
end

---@param lines_to_insert table
---@param pos table {row: number, col: number}
local function InsertLinesAtTop(lines_to_insert, pos)
  local file_path = get_file_path()
  vim.fn.mkdir(vim.fn.fnamemodify(file_path, ":h"), "p")

  local lines = read_file(file_path)
  local updated_lines = update_lines(lines, lines_to_insert, pos)
  write_file(file_path, updated_lines)
end

function InsertPDFurl()
  local pos = GetCursorPosition()
  local url = ReturnChormeReadingState()
  local pdf = ReturnSkimReadingState()
  InsertLinesAtTop({ pdf, url }, pos)
end

---@return table|nil {path: string, page: number, scrollY: number, url: string} or nil
local function ExtractAndPrintFileInfo()
  local buf = vim.api.nvim_get_current_buf()
  local file_path = vim.api.nvim_buf_get_name(buf)

  local new_file_path = vim.fn.expand("$HOME") .. "/.local/state/nvim/note/" .. file_path:gsub("/", "_") .. ".txt"

  if vim.fn.filereadable(new_file_path) == 0 then
    print("Error: File does not exist " .. new_file_path)
    return
  end

  local file = io.open(new_file_path, "r")
  if not file then
    print("Error: Unable to open file " .. new_file_path)
    return
  end

  local content = file:read("*all")
  file:close()

  -- Extract information
  local path = content:match("path: ([^\n,]+)"):gsub("^%s+", ""):gsub("%s+$", "")
  local page = content:match("page: (%d+)")
  local scrollY = content:match("scrollY:(%d+)")
  local url = content:match("url:([^\n,]+)")

  -- Output table
  if path and page and scrollY and url then
    print("path: " .. path)
    print("page: " .. page)
    return { path, page, scrollY, url }
  else
    print("Error: Unable to extract required information from the file")
    return nil
  end
end

local function OpenPDFAndURL()
  local info = ExtractAndPrintFileInfo()
  if info then
    OpenSkimToReadingState(info[2], info[1])
    OpenUntilReady(info[4], info[3])
  end
end

--- Parses the file content and returns all paths from lines
--- Only keeps the content matching 'xxx.pdf'
---@param file_path string
---@return table
local function get_all_pdfs(file_path)
  local file = io.open(file_path, "r")
  if not file then
    print("Error: Unable to open file " .. file_path)
    return {}
  end

  local paths = {}
  for line in file:lines() do
    if line:match("page:") then
      local path = line:match("path: ([^,]+)")
      if path then
        -- Extract the part matching 'xxx.pdf'
        local extracted_path = path:match(".+/([^/]+%.pdf)}")
        if extracted_path then
          table.insert(paths, extracted_path)
        end
      end
    end
  end

  file:close()
  return paths
end

--- Parses the file content and returns all titles from lines containing 'title'
---@param file_path string
---@return table
local function get_all_titles(file_path)
  local file = io.open(file_path, "r")
  if not file then
    print("Error: Unable to open file " .. file_path)
    return {}
  end

  local titles = {}
  for line in file:lines() do
    local title = line:match("title:([^,]+)")
    if title then
      table.insert(titles, title)
    end
  end

  file:close()
  return titles
end

map("n", "<leader>nn", function()
  InsertPDFurl()
end, { noremap = true, silent = true, desc = "New note" })

map("n", "<leader>nf", function()
  OpenPDFAndURL()
end, { noremap = true, silent = true, desc = "Extract and print file info" })

map("n", "<leader>np", function()
  local file_path = get_file_path()
  local pdfs = get_all_pdfs(file_path)
  for _, pdf in ipairs(pdfs) do
    print(pdf)
  end
end, { noremap = true, silent = true, desc = "Extract and print pdfs" })

map("n", "<leader>nu", function()
  local file_path = get_file_path()
  local urls = get_all_titles(file_path)
  for _, url in ipairs(urls) do
    print(url)
  end
end, { noremap = true, silent = true, desc = "Extract and print urls" })
