<p align="center">
  <img src="./assets/vkrm-icon.png" alt="VKRM Browser" width="160" />
</p>

# vkrm-browser

Meta repository for **VKRM Browser**, an independent Chromium/Brave-based browser project.

## Purpose

This repo is the top-level project repo for VKRM Browser.
It tracks the meta/build layer and points to the source overlay repo used for the actual browser changes.

## Related repo

- [`vkrm-core`](https://github.com/sirvkrm/vkrm-core): overlay repo containing the modified source files for this fork

## What lives here

- top-level metadata inherited from the upstream `brave-browser` style repo where relevant
- package/build orchestration files
- `scripts/export_vkrm_core.sh` for exporting the current modified worktree into `vkrm-core`

## What does not live here

- full Chromium source checkout
- VPS/emulator runtime state
- Android SDK / AVD images / secrets

## Upstream basis

This project is based on the Brave/Chromium build layout, but is being reworked as **VKRM Browser**.
Use the `vkrm-core` repo for the actual browser source overlay.
