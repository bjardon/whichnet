# WhichNet

Menu bar indicator for the network interface that is actually carrying internet on macOS.

macOS keeps Wi-Fi connected when a Thunderbolt dock Ethernet link is plugged in, and the system Wi-Fi icon does not show that wired is the active path. WhichNet is a single status item whose icon follows the default route: Ethernet when the dock is carrying traffic, Wi-Fi when it isn’t.

## Run

macOS 14+ and Xcode/Swift 6 command-line tools.

```sh
make run
```

That builds `dist/WhichNet.app` and opens it. There is no Dock icon; look in the menu bar.

Quit from the panel, or `make kill`.
