# Privacy Policy

**Short version: Ditto keeps everything on your Mac. Nothing you copy ever leaves
your device. There is no telemetry, no analytics, and no account.**

## What Ditto stores, and where

Ditto saves your clipboard history so you can get items back later. Everything is
stored **locally** on your Mac, under:

```
~/Library/Application Support/Ditto/
  ditto.sqlite        clipboard history (text, links, colors, file references)
  *.png               image clips and their thumbnails
```

Semantic-search embeddings are computed **on-device** (Apple CoreML) and stored in
the same local database. No clipboard content, embedding, or usage data is ever
transmitted anywhere.

## What Ditto does NOT do

- ❌ No network requests. Ditto makes no outbound connections for its core
  functionality and sends your data to no server — ours or anyone else's.
- ❌ No telemetry, analytics, crash reporting, or usage tracking.
- ❌ No account, sign-in, or cloud sync.
- ❌ No advertising or third-party SDKs.

## Sensitive content

Ditto deliberately tries **not** to capture secrets:

- It ignores pasteboards apps mark as transient, concealed, or auto-generated —
  the flags password managers (1Password, Keychain, etc.) use.
- You can add any app to an exclusion denylist (`excludedBundleIDs`) so Ditto
  never records what you copy from it.
- Clip contents are never written to logs.

That said, a clipboard manager inherently stores what you copy. Treat the local
database as sensitive, and use the exclusion list for apps that handle secrets.

## Permissions

- **Accessibility** — used solely to paste the selected clip into the app you were
  using (by synthesizing ⌘V). Ditto does not read other apps' contents.
- **Input monitoring / global hotkey** — to summon the bar with ⌃⌥⌘V.

## Your control

- **Delete a clip:** select it and press ⌘⌫.
- **Clear history:** remove unpinned items from the bar, or quit Ditto and delete
  the folder above.
- **Uninstall:** drag Ditto to the Trash and delete `~/Library/Application Support/Ditto/`.

## Changes

Any future change to this policy will appear in this file in the public repository,
with the change visible in the Git history.

_Last updated: 2026-06-19._
