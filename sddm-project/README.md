# SDDM Phase 3 — Rev 2: Activation and Recovery

This revision adds explicit activation/deactivation and fixes helper installation
on systems where `/usr/local/libexec` does not yet exist.

It does **not** restart SDDM or reboot the machine automatically.

## 1. Update the installed helper

After extracting this ZIP over `~/.config/sddm-project/`:

```bash
cd ~/.config/sddm-project
./scripts/install-system-helper.sh
```

The script now creates `/usr/local/libexec` when needed.

## 2. Activate the tested theme

```bash
./scripts/activate-sddm-theme.sh
```

The helper first verifies that the installed theme under
`/usr/share/sddm/themes/quickshell-custom/` still matches its manifest. It then
writes only:

```text
/etc/sddm.conf.d/quickshell-theme.conf
```

with:

```ini
[Theme]
Current=quickshell-custom
```

No service restart is performed. The theme takes effect the next time SDDM
starts, normally after logout or reboot.

## 3. Normal deactivation

```bash
./scripts/deactivate-sddm-theme.sh
```

This removes our override, or restores a prior file if one existed at the same
path. It also does not restart SDDM.

## Emergency recovery from a broken graphical login

Open a TTY with `Ctrl+Alt+F3`, log in, then run:

```bash
sudo rm -f /etc/sddm.conf.d/quickshell-theme.conf
sudo systemctl restart sddm
```

That exact fallback does not depend on the project scripts or helper.

## Safety behavior

- Activation is manual only.
- The installed theme is validated before the config is written.
- Re-running activation when already active performs no write.
- The active config has a fixed path and fixed contents.
- Existing content at that exact path is backed up before replacement.
- Neither activation nor deactivation restarts SDDM.
