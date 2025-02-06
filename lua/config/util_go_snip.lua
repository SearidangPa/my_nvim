local ls = require 'luasnip'
local c = ls.choice_node
local d = ls.dynamic_node
local f = ls.function_node
local i = ls.insert_node
local s = ls.snippet
local t = ls.text_node
local sn = ls.snippet_node
local extras = require 'luasnip.extras'
local ts_locals = require 'nvim-treesitter.locals'
local ts_utils = require 'nvim-treesitter.ts_utils'
local fmta = require('luasnip.extras.fmt').fmta
require 'config.navigate_func_call'

FirstLetter = function(args)
  local input = args[1][1] or ''
  local lower = input:sub(1, 1):lower()
  return lower
end

LowerFirst = function(args)
  local input = args[1][1] or ''
  local lower = input:sub(1, 1):lower() .. input:sub(2)
  return lower
end

GetLastFuncName = function(args)
  local input = args[1][1] or ''
  ---@diagnostic disable-next-line: param-type-mismatch
  local parts = vim.split(input, '.', true)
  local res = parts[#parts] or ''
  if res == '' then
    return ''
  end

  return LowerFirst { { res } }
end

function KebabToCamelCase(args)
  local input = args[1][1] or ''
  local lower = input:sub(1, 1):lower()
  return lower
end

function KebabToCamelCase(args)
  local input = args[1][1]
  print('input' .. input)
  local parts = vim.split(input, '-', { plain = true })
  for index = 2, #parts do
    parts[index] = parts[index]:sub(1, 1):upper() .. parts[index]:sub(2)
  end
  return table.concat(parts, '')
end

function ReplaceDashWithSpace(args)
  local input = args[1][1]
  local parts = vim.split(input, '-', { plain = true })
  return table.concat(parts, ' ')
end

function Go_ret_vals_nearest_func_decl()
  local previous_func_call = Get_previous_func_call()
  return Go_ret_vals { { previous_func_call } }
end

-- Adapted from https://github.com/tjdevries/config_manager/blob/1a93f03dfe254b5332b176ae8ec926e69a5d9805/xdg_config/nvim/lua/tj/snips/ft/go.lua
vim.treesitter.query.set(
  'go',
  'LuaSnip_Result',
  [[ [
    (method_declaration result: (_) @id)
    (function_declaration result: (_) @id)
    (func_literal result: (_) @id)
  ] ]]
)

local function transform(text, info)
  if text == 'int' then
    return t '0'
  elseif text == 'error' then
    if info then
      info.index = info.index + 1
      return c(info.index, {
        t(string.format('eris.Wrap(err, "failed to %s")', GetLastFuncName { { info.func_name } })),
        sn(
          nil,
          fmta(
            [[
              eris.Wrapf(err, "failed to <funcName>, <moreInfo>
            ]],
            {
              funcName = f(function()
                return GetLastFuncName { { info.func_name } }
              end, {}),
              moreInfo = i(1, ''), -- Insert node for user input
            }
          )
        ),
      })
    end
  elseif text == 'bool' then
    return t 'false'
  elseif text == 'string' then
    return t '""'
  elseif text == 'uintptr' then
    return t 'cldapi.Failed'
  elseif string.find(text, '*', 1, true) then
    return t 'nil'
  else
    return t(string.format('%s{}', text))
  end

  return t(text)
end

local handlers = {
  ['parameter_list'] = function(node, info)
    local result = {}
    local count = node:named_child_count()
    for idx = 0, count - 1 do
      table.insert(result, transform(vim.treesitter.get_node_text(node:named_child(idx), 0), info))
      if idx ~= count - 1 then
        table.insert(result, t { ', ' })
      end
    end
    return result
  end,

  ['type_identifier'] = function(node, info)
    local text = vim.treesitter.get_node_text(node, 0)
    return { transform(text, info) }
  end,
}

local function go_result_type(info)
  local cursor_node = ts_utils.get_node_at_cursor()
  if not cursor_node then
    return { t 'nil' }
  end

  local scope = ts_locals.get_scope_tree(cursor_node, 0)
  local function_node
  for _, v in ipairs(scope) do
    if v:type() == 'function_declaration' or v:type() == 'method_declaration' or v:type() == 'func_literal' then
      function_node = v
      break
    end
  end

  local query = vim.treesitter.query.get('go', 'LuaSnip_Result')

  if not query then
    return { t 'nil' }
  end

  for _, node in query:iter_captures(function_node, 0) do
    if not node then
      return { t 'nil' }
    end

    local handlerFunc = handlers[node:type()]
    if handlerFunc then
      return handlerFunc(node, info)
    end
  end

  return { t '' }
end

function Go_ret_vals(args)
  local info = {
    index = 0,
    func_name = args[1][1] or 'unknown',
  }
  local result = go_result_type(info)
  return sn(nil, result)
end
