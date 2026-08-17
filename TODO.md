# TODO

- [x] Menu bar icon follows the interface that is carrying internet (Wi-Fi vs Ethernet vs other vs offline)
- [x] Menu bar and panel share chosen SF Symbols for each interface type (`wifi`, `app.connected.to.app.below.fill`, `antenna.radiowaves.left.and.right`, `network.badge.shield.half.filled`, `network`, `xmark.circle`)
- [x] Panel lists every hardware interface (display name, BSD name, address), including inactive links
- [x] Panel follows the respawken popover (header, rows, badges, footer + Quit; no refresh or gear until needed)
- [x] Launch at login — first launch registers via `SMAppService`; panel toggle can undo it; later launches don't re-register if it was turned off
- [x] Wi-Fi row shows network name (SSID; needs Location) and channel
- [x] Dock Ethernet vs Wi-Fi switch confirmed on this machine
