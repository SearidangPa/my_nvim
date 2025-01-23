require 'config.util_find_func'
local ls = require 'luasnip'
local c = ls.choice_node
local s = ls.snippet
local sn = ls.snippet_node
local i = ls.insert_node
local f = ls.function_node
local d = ls.dynamic_node
local t = ls.text_node
local ts_locals = require 'nvim-treesitter.locals'
local ts_utils = require 'nvim-treesitter.ts_utils'
local fmta = require('luasnip.extras.fmt').fmta
local get_node_text = vim.treesitter.get_node_text

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

local transform = function(text, info)
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
              eris.Wrapf(err, "failed to <funcName>, <moreInfo>")
            ]],
            {
              funcName = f(function()
                return GetLastFuncName { { info.func_name } }
              end, {}),
              moreInfo = i(1, 'additional_info'), -- Insert node for user input
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
      table.insert(result, transform(get_node_text(node:named_child(idx), 0), info))
      if idx ~= count - 1 then
        table.insert(result, t { ', ' })
      end
    end
    return result
  end,

  ['type_identifier'] = function(node, info)
    local text = get_node_text(node, 0)
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

local function debug_node(node, label)
  print(string.format('%s: Type: %s, Static Text: %s', label or 'Node', node.type, vim.inspect(node.static_text or 'N/A')))
end

local go_ret_vals = function(args)
  local info = {
    index = 0,
    func_name = args[1][1] or 'unknown',
  }
  local result = go_result_type(info)
  for _, node in ipairs(result) do
    debug_node(node, 'Result Node')
  end
  return sn(nil, result)
end

ls.add_snippets('go', {
  s(
    'val', -- error return
    fmta(
      [[
        <choiceNode> <funcName>(<args>)
        if err != nil {
            return <dynamicRet>
        }
      ]],
      {
        choiceNode = c(2, {
          fmta([[<res>, err := ]], { res = i(1, 'res') }),
          t 'err = ',
          t 'err := ',
        }),
        funcName = i(1, 'funcName'),
        args = i(3, ''),
        dynamicRet = d(4, go_ret_vals, { 1 }),
      }
    )
  ),
})

local function go_ret_vals_nearest_func_decl()
  local func_name = Find_nearest_function_decl()
  return go_ret_vals { func_name }
end

ls.add_snippets('go', {
  s(
    'ifer',
    fmta(
      [[
        if err != nil {
            return <dynamicRet>
        }
      ]],
      {
        dynamicRet = d(1, go_ret_vals_nearest_func_decl, {}),
      }
    )
  ),
})

require 'config.util_go_snip'
