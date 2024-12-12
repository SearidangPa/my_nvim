local ls = require 'luasnip'
local s = ls.snippet
local t = ls.text_node
local c = ls.choice_node
local i = ls.insert_node
local f = ls.function_node
local d = ls.dynamic_node
local snippet_from_nodes = ls.sn
local ts_locals = require 'nvim-treesitter.locals'
local ts_utils = require 'nvim-treesitter.ts_utils'
local get_node_text = vim.treesitter.get_node_text
local rep = require('luasnip.extras').rep
local fmta = require('luasnip.extras.fmt').fmta

local lowerFirst = function(args)
  local input = args[1][1] or ''
  local lower = input:sub(1, 1):lower() .. input:sub(2)
  return lower
end

local getLastFuncName = function(args)
  print('args', args)
  ---@diagnostic disable-next-line: param-type-mismatch
  local parts = vim.split(args, '.', true)
  print('num parts', #parts)
  return parts[#parts] or ''
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

local transform = function(text, info)
  if text == 'int' then
    return t '0'
  elseif text == 'error' then
    if info then
      info.index = info.index + 1
      return t(string.format('fmt.Errorf("failed to %s, err: %%v", err) ', getLastFuncName(info.func_name)))
    end
  elseif text == 'bool' then
    return t 'false'
  elseif text == 'string' then
    return t '""'
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
    if handlers[node:type()] then
      return handlers[node:type()](node, info)
    end
  end

  return { t '' }
end

local go_ret_vals = function(args)
  return snippet_from_nodes(
    nil,
    go_result_type {
      index = 0,
      func_name = args[1][1],
    }
  )
end

ls.add_snippets('go', {
  s(
    'erp', -- error return
    fmta(
      [[
        <choiceNode> <funcName>(<args>)
        if err != nil {
            return <dynamicRet>
        }
        <finish>
      ]],
      {
        choiceNode = c(1, {
          fmta([[<resultName>, err := ]], { resultName = i(1, 'resultName') }),
          fmta([[err := ]], {}),
          fmta([[err = ]], {}),
        }),
        funcName = i(2, 'funcName'),
        args = i(3, ''),
        dynamicRet = d(4, go_ret_vals, { 2, 3 }),
        finish = i(0),
      }
    )
  ),
})

ls.add_snippets('go', {
  s(
    'winb',
    fmta(
      [[
            //go:build windows

            package <finish>
        ]],
      {
        finish = i(0),
      }
    )
  ),
})

ls.add_snippets('go', {
  s(
    'fn',
    fmta(
      [[
        func <funcName>(<args>) <returnType> {
            <body>
        }
      ]],
      {
        funcName = i(1, 'funcName'),
        args = i(2, 'args'),
        returnType = i(3, 'returnType'),
        body = i(0),
      }
    )
  ),
})

ls.add_snippets('go', {
  s(
    'ne', -- no error
    fmta(
      [[
          <choiceNode>
          require.NoError(t, err)
          <finish>
      ]],
      {
        choiceNode = c(1, {
          fmta([[<val>, err := <funcName>(<args>)]], { val = i(1, 'val'), funcName = i(2, 'funcName'), args = i(3, 'args') }),
          fmta([[err := <funcName>(<args>)]], { funcName = i(1, 'funcName'), args = i(2, 'args') }),
          fmta([[err = <funcName>(<args>)]], { funcName = i(1, 'funcName'), args = i(2, 'args') }),
        }),
        finish = i(0),
      }
    )
  ),
})

ls.add_snippets('go', {
  s(
    'ef', -- error fatal
    fmta(
      [[
        <choiceNode> <funcName>(<args>)
        if err != nil {
            log.Fatal("failed to <processedFuncName>, err: %v", err)
        }
        <finish>
      ]],
      {
        choiceNode = c(1, {
          fmta([[<resultName>, err := ]], { resultName = i(1, 'resultName') }),
          fmta([[err := ]], {}),
          fmta([[err = ]], {}),
        }),
        funcName = i(2, 'funcName'),
        args = i(3, 'args'),
        processedFuncName = rep(2),
        finish = i(0),
      }
    )
  ),
})

ls.add_snippets('go', {
  s(
    'test',
    fmta(
      [[
          func Test_<Name>(t *testing.T) {
                  <body>
          }
    ]],
      {
        Name = i(1, 'Name'),
        body = i(0),
      }
    )
  ),
})

ls.add_snippets('go', {
  s(
    'strf',
    fmta(
      [[
          func (<inst> *<Type>) String() string {
                  <body>
          }
      ]],
      {
        Type = i(1, 'Type'),
        inst = f(lowerFirst, { 1 }),
        body = i(0),
      }
    )
  ),
})
