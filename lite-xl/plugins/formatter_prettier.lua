-- mod-version:2 lite-xl 2.00
-- for JS Beautify fortmatter
local config = require "core.config"
local formatter = require "plugins.formatter"

config.prettier_args = {"-w", "--print-width 300"} -- make sure to keep -w arg if you change this
config.reload = true
formatter.add_formatter {
	name = "Prettier",
	file_patterns = {"%.ts$","%.js$","%.jsx$","%.json$","%.html$","%.scss$"},
	command = "prettier $ARGS $FILENAME",
	args = config.prettier_args,
}
