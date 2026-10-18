# Vitrine for macOS

Native reference library and canvas for Apple Silicon, macOS 15 or newer.
Application source code is private. This repository hosts built releases and the Sparkle update feed.

## Install the beta

This beta is signed but **not notarized by Apple**. The installer verifies the release checksum
and application signature, and removes quarantine from Vitrine only. It does not disable Gatekeeper.

Quit Vitrine first, then run:

```sh
curl -fsSL https://alexandroff-h.github.io/vitrine-releases/install.sh | bash
```

You can inspect `install.sh` in this repository before running it. The installer uses
`/Applications`, or `~/Applications` if that folder is not writable. It never needs sudo.
Your existing library stays in `~/Library/Application Support/Vitrine`.

After the first installation, use **Vitrine → Check for Updates…**.
