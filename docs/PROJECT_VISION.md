# Project Vision - Hyprland Desktop Experience

## Core Goal

Create a complete, polished, and approachable Hyprland desktop environment that feels as complete and user-friendly as GNOME or KDE, while fully embracing Hyprland’s superior window management, dynamic tiling, and workspaces.

Hyprland is fundamentally better at handling windows and workspaces than anything else available. The goal is to remove the friction that stops normal users from adopting it — especially people coming from Windows or traditional desktop environments.

## Philosophy

- Prioritize keyboard-driven workflows and tiling power, but make them discoverable and approachable.
- The desktop should be powerful by default, safe to experiment with, and easy to recover from mistakes.
- One source of truth for configuration. Never two files that can drift.
- Every user-facing change should be previewable, reversible, and safe.
- The entire system (code + documentation) must be understandable and maintainable by AI models (Claude, Grok, etc.) without constant human oversight.
- We are building a real daily-driver desktop environment, not another minimal rice.

## Target Users

- Users who want Hyprland’s power but don’t want to spend weeks hand-editing configs.
- People transitioning from Windows/KDE/GNOME who like the idea of tiling but need a smoother onboarding.
- Power users who want a strong base they can further customize.

## Key Pillars

1. **Excellent Settings Application**  
   Comprehensive, attractive UI covering major settings with safety (snapshots, staged changes, rollback).

2. **Strong Out-of-Box Experience**  
   Polished defaults, helpful onboarding, easy theming, and discoverable features.

3. **Reliability & Recoverability**  
   Robust backup/snapshot system so users (and AIs) can confidently experiment.

4. **AI Maintainability**  
   Extremely detailed documentation written specifically for AI collaborators. Clean, consistent, modular code.

5. **Hyprland-First Design**  
   Lean into tiling, dynamic workspaces, and keyboard workflows rather than trying to emulate traditional desktops.

## Non-Goals

- Becoming a full distro
- Competing purely on aesthetics with minimal rices
- Adding unnecessary bloat

## Long-term Vision

A GitHub project where someone can:
1. Install it on a fresh Arch + Hyprland system
2. Immediately get a beautiful, highly functional desktop
3. Use the Settings app to customize almost everything safely
4. Ask Claude (or any capable AI) to add features, fix breaks from updates, or customize further

The end result should feel like “KDE but with vastly superior window management” — not “yet another minimal Hyprland config”.

---

*Banked into the repo 2026-07-09 (Fable 5) from the maintainer's
project-vision.md so it survives KB re-syncs. The companion
AI-MAINTENANCE-GUIDE.md draft embedded in the original was written
out properly (corrected against current reality) as
docs/AI-MAINTENANCE-GUIDE.md.*
