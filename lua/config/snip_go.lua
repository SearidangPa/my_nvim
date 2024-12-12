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

local extras = require 'luasnip.extras'
local rep = extras.rep
local fmt = require('luasnip.extras.fmt').fmt
local fmta = require('luasnip.extras.fmt').fmta

local function strip_parentheses_and_content(args)
  local func_name = args[1][1] -- Get the text from the first input node
  return func_name:gsub('%b()', '') -- Remove everything inside balanced parentheses and the parentheses themselves
end

local function same(index)
  return f(function(args)
    return args[1]
  end, { index })
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
      return c(info.index, {
        t(string.format('fmt.Errorf("%s: %%v", %s)', info.func_name, info.err_name)),
        t(info.err_name),
        t(string.format('fmt.Errorf("%s: %%w", %s)', info.func_name, info.err_name)),
        t(string.format('errors.Wrap(%s, "%s")', info.err_name, info.func_name)),
      })
    else
      return t 'err'
    end
  elseif text == 'bool' then
    return t 'false'
  elseif text == 'string' then
    return t '""'
  elseif string.find(text, '*', 1, true) then
    return t 'nil'
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
      err_name = args[1][1],
      func_name = args[2][1],
    }
  )
end

ls.add_snippets('go', {
  s('er', {
    i(1, { 'val' }),
    t ', ',
    i(2, { 'err' }),
    t ' := ',
    i(3, { 'f' }),
    t '(',
    i(4),
    t ')',
    t { '', 'if ' },
    same(2),
    t { ' != nil {', '\treturn ' },
    d(5, go_ret_vals, { 2, 3 }),
    t { '', '}' },
    i(0),
  }),
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
    'ef',
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
  s('strf', {
    t 'func (',
    f(function(args)
      -- Get the input and lowercase the first character
      local input = args[1][1] or ''
      local lower = input:sub(1, 1):lower() .. input:sub(2)
      return lower
    end, { 1 }),
    t ' ',
    i(1, 'Type'), -- Input node for the type
    t ') String() string {',
    t { '', '\t' }, -- Indentation for the method body
    i(0), -- Placeholder to start writing the method body
    t { '', '}' },
  }),
})
