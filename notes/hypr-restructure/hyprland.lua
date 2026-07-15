-- Managed/user split — see docs/HYPR_RESTRUCTURE.md in the quickshell
-- repo for what owns what. Short version:
--   generated/  belongs to the shell's ConfigManager. Regenerated
--               whole-file on settings Apply. NEVER hand-edit.
--   user/       belongs to you. The manager NEVER touches these.
-- This root file is also yours; the manager never rewrites it.

require("generated.appearance")
require("generated.monitors")

require("user.look")
require("user.startup")
require("user.rules")
require("user.keybinds")
