local ls = require 'luasnip'
local s = ls.snippet
local i = ls.insert_node
local fmta = require('luasnip.extras.fmt').fmta

ls.add_snippets('go', {
  s(
    'cli',
    fmta(
      [[
//go:build windows

package cli

func init() {
	var <flag_var>
	updatePlaceholderInvokeStr := "update-placeholder-info"
	updatePlaceholderCmd := &cobra.Command{
		Use:   updatePlaceholderInvokeStr,
		Short: "Update placeholder info",
	}
	rootCmd.AddCommand(updatePlaceholderCmd)
	logging.IniLog()

	updatePlaceholderCmd.Flags().StringVarP(&fp, "path", "p", "", "path of the placeholder to query info")
	updatePlaceholderCmd.Flags().StringVarP(&newParentUUIDstr, "new-parent-uuid", "d", "", "new parent uuid")

	markFlagsRequired(updatePlaceholderCmd, "path")
	updatePlaceholderCmd.Run = func(cmd *cobra.Command, args []string) {
		err := updatePlaceholderCLI(fp, newParentUUIDstr)
		logRes(fp, err)
	}
}

func updatePlaceholderCLI(fp, newParentUUIDstr string) error {
      <finish>
}
      ]],
      {
        flag_var = i(1),
        finish = i(0),
      }
    )
  ),
})
