-- USER FILE — yours. Autostart + environment.

hl.on("hyprland.start", function()
hl.exec_cmd("awww-daemon")
hl.exec_cmd("/usr/lib/hyprpolkitagent/hyprpolkitagent")
hl.exec_cmd("kbuildsycoca6 --noincremental")
end)

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")