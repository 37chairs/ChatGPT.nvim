local M = {}

-- Helper function to find the project root by searching for llm/prd.md
function M.find_project_root(start_dir)
  local current_dir = start_dir
  while current_dir ~= "/" do
    local prd_path = current_dir .. "/llm/prd.md"
    if vim.fn.filereadable(prd_path) == 1 then
      return current_dir
    end
    current_dir = vim.fn.fnamemodify(current_dir, ":h")
  end
  return nil
end

-- Helper function to read a file’s content
local function read_file(path)
  if vim.fn.filereadable(path) == 1 then
    local file = io.open(path, "r")
    if file then
      local content = file:read("*all")
      file:close()
      return content
    end
  end
  return nil
end

-- Main function to get context
function M.get_context()
  -- Get the current file’s full path and directory
  local current_file = vim.fn.expand("%:p")
  local current_dir = vim.fn.expand("%:p:h")

  -- Find project root (based on llm/prd.md presence or fallback to current dir)
  local project_root = M.find_project_root(current_dir) or current_dir

  -- Load llm/prd.md
  local prd_path = project_root .. "/llm/prd.md"
  local prd_content = read_file(prd_path) or "No PRD found at " .. prd_path

  -- Load llm/auto_context.json
  local context_json_path = project_root .. "/llm/auto_context.json"
  local context_files = {}
  if vim.fn.filereadable(context_json_path) == 1 then
    local file = io.open(context_json_path, "r")
    if file then
      local json_content = file:read("*all")
      file:close()
      local context_data = vim.fn.json_decode(json_content)

      -- Get the current file’s relative path from the project root
      local relative_file = current_file:sub(#project_root + 2)       -- +2 to skip the leading "/"

      -- Look up context files for the current file
      local context_paths = context_data[relative_file]
      if context_paths then
        for _, rel_path in ipairs(context_paths) do
          local full_path = project_root .. "/" .. rel_path
          local content = read_file(full_path)
          if content then
            table.insert(context_files, { path = rel_path, content = content })
          else
            table.insert(context_files, { path = rel_path, content = "File not found: " .. full_path })
          end
        end
      end
    end
  end

  return {
    prd = prd_content,
    context_files = context_files     -- Array of { path, content } for debug printing
  }
end

return M

