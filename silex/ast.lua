--- SILE AST utilities
--
-- @copyright License: MIT (c) 2023 Omikhleia
--
local ast = {}

--- Find a command node in a SILE AST tree,
--- looking only at the first level.
---@param tree      table       AST tree
---@param command   string      command name
---@return          table|nil   AST command node
function ast.findInTree (tree, command)
  for i=1, #tree do
    if type(tree[i]) == "table" and tree[i].command == command then
      return tree[i]
    end
  end
end

--- Find and extract (remove) a command node in a SILE AST tree,
--- looking only at the first level.
---@param tree      table       AST tree
---@param command   string      command name
---@return          table|nil   AST command node
function ast.extractFromTree (tree, command)
  for i=1, #tree do
    if type(tree[i]) == "table" and tree[i].command == command then
      return table.remove(tree, i)
    end
  end
end

--- Create a command from a simple content tree.
--- It encapsulates the content in a command node.
---@param command   string      command name
---@param options   table       command options
---@param content   table       child AST tree
---@param position  table       position in source (or parent AST command node)
---@return          table       AST command node
function ast.createCommand (command, options, content, position)
  local result = { content }
  result.options = options or {}
  result.command = command
  result.id = "command"
  if position then
    result.col = position.col or 0
    result.lno = position.lno or 0
    result.pos = position.pos or 0
  else
    result.col = 0
    result.lno = 0
    result.pos = 0
  end
  return result
end

--- Create a command from a structured content tree.
--- The content is normally a table of an already prepared content list.
---@param command   string    command name
---@param options   table     command options
---@param content   table     child AST tree
---@param position  table     position in source (or parent AST command node)
---@return          table     AST command node
function ast.createStructuredCommand (command, options, content, position)
  local result = type(content) == "table" and content or { content }
  result.options = options or {}
  result.command = command
  result.id = "command"
  if position then
    result.col = position.col or 0
    result.lno = position.lno or 0
    result.pos = position.pos or 0
  else
    result.col = 0
    result.lno = 0
    result.pos = 0
  end
  return result
end

--- Extract the sub-content tree from a command node,
--- that is the child nodes of the command node.
---@param content   table   AST tree
---@return          table   AST tree
function ast.subContent (content)
  local out = {}
  for _, val in ipairs(content) do
    out[#out+1] = val
  end
  return out
end

return ast
