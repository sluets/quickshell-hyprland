# Quickshell custom SDDM theme

<!-- GPT: updated 2026-07-18 after the major SDDM customization block -->

This directory is the editable, Git-backed source for the custom Qt 6 SDDM login theme.

It does **not** restart SDDM or reboot the machine automatically.

## Normal use from Quickshell

Open:

```text
Settings -> SDDM
```

The page supports:

- current or separately selected Quickshell theme
- theme font or separately selected installed Nerd Font
- current wallpaper or a selected wallpaper from the shared library
- `.thumbs`-backed wallpaper grid plus custom image path
- time/date visibility, scale, spacing, colors, and shadow controls
- clock and login-panel X/Y offsets
- login-panel width, scale, spacing, and custom greeting
- temporary **Test SDDM Theme** preview
- manual **Apply to SDDM** deployment

The Test button uses a temporary copy under `/tmp` and writes no root-owned files. Apply performs the real hash-aware installation.

## First installation

Create the compatibility link if needed:

```bash
ln -s ~/.config/quickshell/sddm-project ~/.config/sddm-project
```

Install or refresh the privileged helper:

```bash
cd ~/.config/sddm-project
./scripts/install-system-helper.sh
```

Install the current snapshot:

```bash
./scripts/apply-sddm-theme.sh
```

Activate the theme:

```bash
./scripts/activate-sddm-theme.sh
```

Activation writes only:

```text
/etc/sddm.conf.d/quickshell-theme.conf
```

It does not restart SDDM. The change appears at the next logout or reboot.

## Command-line testing

Test the source tree directly:

```bash
sddm-greeter-qt6 --test-mode --theme ~/.config/sddm-project
```

Test the exact root-installed copy:

```bash
sddm-greeter-qt6 --test-mode \
  --theme /usr/share/sddm/themes/quickshell-custom
```

Use the Quickshell Test button when previewing unsaved controls because it first builds a temporary snapshot containing those values.

## Shared wallpaper library

The SDDM wallpaper selector and the main Quickshell wallpaper picker share:

```text
UserPrefs.wallpapersPath
```

Default:

```text
~/Pictures/Wallpapers
```

Thumbnail cache:

```text
<wallpaper-library>/.thumbs
```

SDDM stores the original wallpaper path, never the thumbnail path. The generated theme copies the chosen image into its own assets so the greeter does not need access to the user's wallpaper directory.

## Safety behavior

- Preview never invokes `pkexec` and never writes under `/usr/share`.
- Apply is manual only.
- Generated inputs are validated before installation.
- Installed and staged snapshots are compared by digest.
- Identical snapshots cause no root-owned rewrite.
- Existing installed content is backed up before replacement.
- Activation and deactivation do not restart SDDM.

## Deactivation and emergency recovery

Normal deactivation:

```bash
./scripts/deactivate-sddm-theme.sh
```

Emergency recovery from a TTY:

```bash
sudo rm -f /etc/sddm.conf.d/quickshell-theme.conf
sudo systemctl restart sddm
```

`Ctrl+Alt+F3` normally opens a TTY. Restarting SDDM terminates the active graphical session.

## Monitor layout

The test greeter runs inside the current desktop session and follows Hyprland's monitor arrangement. The real greeter uses a separate X11 layout configured in:

```text
/usr/share/sddm/scripts/Xsetup
```

Connector names can differ between Hyprland and SDDM/Xorg. See `docs/SDDM_BACKUP_AND_TRANSFER.md` before copying monitor settings to another machine.
