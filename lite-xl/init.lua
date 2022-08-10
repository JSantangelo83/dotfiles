-- put user settings here
-- this module will be loaded after everything else when the application starts
-- it will be automatically reloaded when saved

local core = require "core"
local keymap = require "core.keymap"
local config = require "core.config"
local style = require "core.style"

------------------------------ Themes ----------------------------------------

-- light theme:
-- core.reload_module("colors.summer")

--------------------------- Key bindings -------------------------------------

-- key binding:

------ Movement char
keymap.add { ["mode+j"] = "doc:move-to-previous-char" }
keymap.add { ["mode+l"] = "doc:move-to-next-char" }
keymap.add { ["mode+k"] = "doc:move-to-next-line" }
keymap.add { ["mode+i"] = "doc:move-to-previous-line" }
------ Movement word
keymap.add { ["ctrl+mode+l"] = "doc:move-to-next-word-end" }
keymap.add { ["ctrl+mode+j"] = "doc:move-to-previous-word-start" }
------ Movement line
keymap.add { ["mode+f"] = "doc:move-to-start-of-line" }
keymap.add { ["mode+h"] = "doc:move-to-end-of-line" }
------ Movement block
keymap.add { ["altgr+mode+k"] = "doc:move-to-next-block-end" }
keymap.add { ["altgr+mode+i"] = "doc:move-to-previous-block-start" }
------ Movement panels
keymap.add { ["ctrl+j"] = "root:switch-to-left" }
keymap.add { ["ctrl+l"] = "root:switch-to-right" }
keymap.add { ["ctrl+k"] = "root:switch-to-down" }
keymap.add { ["ctrl+i"] = "root:switch-to-up" }

------ Selection char
keymap.add { ["shift+mode+j"] = "doc:select-to-previous-char" }
keymap.add { ["shift+mode+l"] = "doc:select-to-next-char" }
keymap.add { ["shift+mode+k"] = "doc:select-to-next-line" }
keymap.add { ["shift+mode+i"] = "doc:select-to-previous-line" }
------ Selection word
keymap.add { ["ctrl+shift+mode+l"] = "doc:select-to-next-word-end" }
keymap.add { ["ctrl+shift+mode+j"] = "doc:select-to-previous-word-start" }
------ Selection line
keymap.add { ["shift+mode+f"] = "doc:select-to-start-of-line" }
keymap.add { ["shift+mode+h"] = "doc:select-to-end-of-line" }
------ Selection block
keymap.add { ["altgr+shift+mode+k"] = "doc:select-to-next-block-end" }
keymap.add { ["altgr+shift+mode+i"] = "doc:select-to-previous-block-start" }

------ Panels create
keymap.add { ["ctrl+mode+="] = "root:split-right" }
keymap.add { ["ctrl+mode+-"] = "root:split-down" }
------ Panels resize
keymap.add { ["ctrl+shift+mode+="] = "root:grow" }
keymap.add { ["ctrl+shift+mode+-"] = "root:shrink" }

------ Special
keymap.add { ["ctrl+n"] = "find-replace:repeat-find" }
keymap.add { ["ctrl+t"] = "treeview:toggle" }
keymap.add { ["ctrl+k"] = "doc:delete-lines" }
keymap.add { ["ctrl+mode+i"] = "doc:move-lines-up" }
keymap.add { ["ctrl+mode+k"] = "doc:move-lines-down" }
keymap.add { ["ctrl+shift+f"] = "project-search:find" }
keymap.add { ["ctrl+shift+n"] = "find-replace:previous-find" }
keymap.add { ["ctrl+shift+mode+k"] = "doc:duplicate-lines" }
keymap.add { ["ctrl+shift+i"] = "formatter:format-doc" }


------------------------------- Fonts ----------------------------------------

-- customize fonts:
-- style.font = renderer.font.load(DATADIR .. "/fonts/FiraSans-Regular.ttf", 14 * SCALE)
-- style.code_font = renderer.font.load(DATADIR .. "/fonts/JetBrainsMono-Regular.ttf", 14 * SCALE)
--
-- font names used by lite:
-- style.font          : user interface
-- style.big_font      : big text in welcome screen
-- style.icon_font     : icons
-- style.icon_big_font : toolbar icons
-- style.code_font     : code
--
-- the function to load the font accept a 3rd optional argument like:
--
-- {antialiasing="grayscale", hinting="full"}
--
-- possible values are:
-- antialiasing: grayscale, subpixel
-- hinting: none, slight, full

------------------------------ Plugins ----------------------------------------

local lintplus = require "plugins.lintplus"
lintplus.setup.lint_on_doc_load()
lintplus.setup.lint_on_doc_save()

-- enable or disable plugin loading setting config entries:

-- enable plugins.trimwhitespace, otherwise it is disable by default:
-- config.plugins.trimwhitespace = true
--
-- disable detectindent, otherwise it is enabled by default
-- config.plugins.detectindent = false

