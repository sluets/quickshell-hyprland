# SDDM theme — backup, Git storage, and transfer

This project keeps the editable SDDM source inside the Quickshell Git repository while preserving the path expected by the existing scripts.

## Source of truth

The Git-backed source should live here:

```text
~/.config/quickshell/sddm-project/
```

The compatibility path used by the SDDM scripts remains:

```text
~/.config/sddm-project
```

That path is a symbolic link pointing into the Quickshell repository:

```text
~/.config/sddm-project -> ~/.config/quickshell/sddm-project
```

The root-owned files below are deployment outputs, not the source of truth:

```text
/usr/local/libexec/quickshell-sddm-installer
/usr/share/sddm/themes/quickshell-custom/
/etc/sddm.conf.d/quickshell-theme.conf
```

Do not manually copy those files into Git. The scripts recreate them from `sddm-project/`.

## Move the existing SDDM project into the repository

Run once on the current machine:

```bash
cd ~/.config
mv sddm-project quickshell/sddm-project
ln -s ~/.config/quickshell/sddm-project ~/.config/sddm-project
```

Verify the link:

```bash
ls -ld ~/.config/sddm-project
```

Expected result:

```text
/home/hypr/.config/sddm-project -> /home/hypr/.config/quickshell/sddm-project
```

Test the source theme before committing:

```bash
sddm-greeter-qt6 --test-mode --theme ~/.config/sddm-project
```

Then commit it:

```bash
cd ~/.config/quickshell
git add sddm-project docs
git commit -m "back up sddm project and deployment docs"
git push
```

Git preserves executable bits, unlike many ZIP extraction workflows.

## Install on another Arch/Hyprland machine

Clone or pull the Quickshell repository into the normal location:

```bash
git clone <repository-url> ~/.config/quickshell
```

Create the compatibility symlink:

```bash
ln -s ~/.config/quickshell/sddm-project ~/.config/sddm-project
```

If the link already exists, inspect it before replacing anything:

```bash
ls -ld ~/.config/sddm-project
```

Install the privileged helper:

```bash
cd ~/.config/sddm-project
./scripts/install-system-helper.sh
```

Install the generated theme into the inactive root-owned theme directory:

```bash
./scripts/apply-sddm-theme.sh
```

Test the exact installed copy:

```bash
sddm-greeter-qt6 --test-mode \
  --theme /usr/share/sddm/themes/quickshell-custom
```

Activate it only after that test succeeds:

```bash
./scripts/activate-sddm-theme.sh
```

The activation script writes only:

```text
/etc/sddm.conf.d/quickshell-theme.conf
```

It does not restart SDDM or reboot the machine.

## Emergency rollback

From a terminal or TTY:

```bash
sudo rm -f /etc/sddm.conf.d/quickshell-theme.conf
sudo systemctl restart sddm
```

`Ctrl+Alt+F3` normally opens a TTY if the graphical greeter is unusable.
Restarting SDDM terminates the active graphical session, so use this only when appropriate.

## Normal updates after the first install

Pull the newest Git revision:

```bash
cd ~/.config/quickshell
git pull
```

When the SDDM helper itself changed, reinstall it:

```bash
~/.config/sddm-project/scripts/install-system-helper.sh
```

To push the current Quickshell theme and wallpaper to SDDM, use:

```text
Settings -> SDDM -> Apply to SDDM
```

The Apply action is manual by design. Changing desktop themes or cycling wallpapers does not write root-owned files. The installer compares digests and skips all writes when the installed snapshot is already identical.

## What Git protects and what it does not

Git protects:

- SDDM QML source and metadata
- default and generated-config templates
- snapshot generator and installer scripts
- bundled assets
- documentation and recovery instructions

Git does not capture:

- the currently deployed root-owned theme copy
- the active `/etc/sddm.conf.d/` override
- uncommitted changes
- unrelated files elsewhere in the home directory

Commit and push after meaningful SDDM changes. The root deployment can always be recreated from the committed source.
