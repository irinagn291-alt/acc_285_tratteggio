# Tratteggio

Tap the missing word under a cropped painting to restore a work you already saved.

Tratteggio is for people who know a painting from a detail and want to finish its label on this device. Home is the loupe: Frame crops a saved work that is not Restored, punches one Token from maker or title, and hangs word chips under the shard. The true chip writes a PatchMark and files Restored. A miss writes a SmudgeMark and keeps the hole. There is no Game tab, no shop, and no museum WebView.

## Who it is for

Cataloguers who save National Gallery of Art works into a crate, then patch a pierced Lemma from a magnified crop. Explore stocks Shut works. Saved keeps Restored pieces and reviewable misses. Settings credits the collection and holds contact at https://tratteggio-loupe.pro/contact-us.

## Architecture

Loupe is a closed fold with cases Shut, Framed, and Restored. The loupe is a fold over Works. Frame writes a Shard and a Lemma (artist XOR title with one Token removed) and folds Shut to Framed. Patch writes a PatchMark when the tapped Token fills the hole and folds Framed to Restored. A miss writes a SmudgeMark and keeps the Shard. Patch on Shut is refused. Frame on an empty crate writes Mute. Restored works leave the frame pool.

This pattern fits the product because the job is one crop and one missing word, not a gallery browse and not a full-canvas name hunt. Views call `frameShard`, `patchToken`, `smudgeToken`, and `undoMark` on one observable store. They never keep a second plaque enum. Persistence is one Codable `LoupeDocument` in UserDefaults under `ttg.loupe.v1`.

Navigation is loupe-locked chrome: Quiz never leaves. Explore, Saved, and Settings arrive as sheets. Four destinations, never exactly three tabs. After onboarding, `ProcessInfo` reads `-ReviewScreen today|log|goals` once. today stays on Quiz, log presents Saved, goals presents Settings. Extra key `explore` presents Explore.

## Why pick this app

Frame-then-patch. Home is a cropped Shard plus a pierced Lemma. Token chips hang in the command row, including extras from the crate. A match files Restored. A miss stays reviewable on Saved. That is the reason to pick Tratteggio over a wall-label hunt or a museum browser.

## Design

Soft card daylight. Tokens live in `Assets.xcassets` and `LoupeInk` / `LoupeFace` / `LoupePad` / `LoupeCurve` / `LoupeLift`. Photography-first home: caption under the tile, pill Frame, soft shadow only on the shard. Snap press 0.97. Sheets fade when Reduce Motion is on.

## AI art

Style: 3D glass render, glassmorphism, studio-lit loupe over a cropped shard. Empty imagesets named from section 13 wait for `assets.generate`. Do not invent pixels here.

Base prompt, reused for every asset:

```
3D glass render, glassmorphism, studio-lit loupe over a cropped shard, frosted magnification, tratteggio hatch marks as light, refraction and soft bloom, isolated subjects, quiet uncluttered ground, no text, no letters, no logo, no photoreal stock, no specified colours, one magnified crop not a museum grid
```

Exact prompts per imageset:

**ttg_AppIcon**

```
A single 3D glass loupe over a cropped painting shard, glassmorphism, subject centred filling the canvas edge to edge, no text, no letters, no words, no alpha, no transparency, no rounded corners, no drop shadow outside the canvas
```

**ttg_Splash**

```
A tall vertical 3D glass loupe over one cropped shard, quiet uncluttered centre band for a wordmark, glassmorphism, no readable text
```

**ttg_Onboarding1**

```
Solid oak crate holding one linen painting crop, the product in one glance, isolated cutout, opaque wood and cloth in the center, transparent corners, no glass box, no text
```

**ttg_Onboarding2**

```
A hand tapping a solid brass word chip under a cropped linen shard, isolated cutout, opaque subject in the center, no hollow frame, no text
```

**ttg_Onboarding3**

```
A small stack of restored linen shards bound with a brass clip, meaning accumulated, isolated cutout, opaque subjects, no text
```

**ttg_EmptyHome**

```
A solid empty oak crate with no paintings, waiting, calm and inviting, never sad, isolated cutout, opaque wood in the center, no hollow glass, no text
```

**ttg_EmptyList**

```
A solid empty wood shelf with no shards, calm, isolated cutout, opaque wood, no text
```

**ttg_CardBackdrop**

```
Abstract low-contrast 3D frosted glass loupe bloom, quiet enough for text on top, filling the canvas, no letters
```

**ttg_ControlFace**

```
Isolated solid brass word chip, opaque metal filling the center, no glass, no hollow ring, no text
```

**ttg_TwistHero**

```
Isolated solid oak crop frame with one punched hole in a linen shard, opaque wood and cloth, no glass box, no text
```

**ttg_SuccessMark**

```
Isolated solid brass inlay plug that fills a hole, opaque metal, no glass, no text
```

**ttg_HeaderDecor**

```
A wide solid linen band with tratteggio hatch texture, opaque fabric, no letters
```

**ttg_BrassLoupe**

```
Isolated solid brass handheld loupe, cutout, opaque metal filling the center, transparent corners, no plate, no hollow glass, no text
```

**ttg_LinenShard**

```
Isolated solid folded linen painting crop on a stretcher, cutout, opaque fabric, transparent corners, no plate, no text
```

**ttg_WoodCrate**

```
Isolated solid oak art crate, lid open, empty interior still opaque wood, cutout, transparent corners, no glass, no text
```

## How this differs from the batch

This is not a full-canvas name hunt. Cartellino files artist then title on a hanging. Cimaise, Tetraptych, Didascalia, and Predella hunt a canvas from a written cue. Sciopticon and Elogium tap a complete maker or title under a shown painting. Velatura flashes the whole picture then hides it. Minium spells the whole string from glyphs. Home here is a cropped Shard plus a pierced Lemma. The leftover search remaps to the National Gallery of Art. The leftover scanner is unused.

## Build

```bash
cd apps/Tratteggio
xcodegen generate
xcodebuild build-for-testing -scheme Tratteggio -destination 'generic/platform=iOS Simulator'
xcodebuild -scheme Tratteggio -destination 'generic/platform=iOS' build
```

Simulator seed writes once behind `ttg.demo.v1`, marks onboarding complete, and frames a live Shard so the opening chip can restore. Device never seeds.

Launch keys after onboarding:

- `-ReviewScreen today` Quiz
- `-ReviewScreen log` Saved
- `-ReviewScreen goals` Settings
- `-ReviewScreen explore` Explore
