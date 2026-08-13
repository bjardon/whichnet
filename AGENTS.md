# WhichNet

Personal Experiment. Built outcome-first with disposable code and minimal process.

- Purpose and run instructions: `README.md`
- Build status: `TODO.md`
- Durable decisions, learnings, dead ends: [WhichNet devlog](https://app.notion.com/p/WhichNet-Network-Status-Menubar-Indicator-30ed5cfe81be807fb442e0e7e39b7f98)

## First outcome

A macOS menu bar icon that shows which interface is actually carrying internet (Wi-Fi vs Ethernet vs other), including when Wi-Fi stays connected while a dock Ethernet link is the default route.

## Build, run, verify

```sh
make run
```

That builds a `dist/WhichNet.app` agent (no Dock icon) and opens it. Click the menu bar icon:

- The symbol should match the default route (`wifi` vs `cable.connector`).
- The panel (respawken-style window, not a native menu) should badge the default-route interface as **Active**.
- Other up links (Wi-Fi while docked, etc.) should appear with a **Standby** badge.

User-visible check: with Wi-Fi on, plug in the Thunderbolt dock. The icon should switch to Ethernet and the dock NIC should be listed as carrying internet. Unplug: it should return to Wi-Fi.

Rebuild after code changes with `make kill && make run`.

Requires macOS 14+ and Swift 6.

## Guardrails

- Local-only; do not send interface or IP data off-machine.
- Do not notarize, ship to the App Store, or attach paid services without asking.
- Do not force-push or replace the GitHub history unless the user explicitly asks.

## Wrap-up

- Implement and verify freely, but ship only after the user explicitly signals acceptance or asks to wrap up.
- Before shipping, verify the accepted user-visible behavior in proportion to the experiment.
- Refresh `TODO.md` so completed, partial, and unfinished outcomes remain accurate in the accepted work.
- Integrate the accepted work into `main` and push it. If the environment isolated the work, complete whatever integration is necessary; opening a pull request is not a completed wrap-up. This repo is intended to replace the existing GitHub history with a force push when wrapping up.
- Do not introduce required review, branch protection, or professional quality gates unless the user asks for them.
- Consider the devlog during every wrap-up, but append only durable decisions, learnings, or dead ends. Do not duplicate routine implementation activity already represented by Git history or `TODO.md`.
- If integration is blocked, report wrap-up as incomplete and name the blocker. Do not record the work as shipped.
