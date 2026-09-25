<!-- gf-brief source=b12326b3c311630df1838d5c867ab1d94fa7ed1f8fedfd9e96a179c23ed69c87 written=2026-09-25T15:17:04+03:00 -->
# Tratteggio

## What it is
Tratteggio is a quiet art quiz for people who want to learn public-domain paintings from a crop. You save works from the National Gallery of Art, frame a magnified shard, then patch the missing maker or title word from hanging chips. Restored pieces and misses stay on this device.

## Launch and onboarding
1. Cold launch shows a full-screen splash image, then either onboarding or the main quiz.
2. If onboarding has not been finished, a three-page cover appears (light appearance). Page dots report “Page 1 of 3”, “Page 2 of 3”, “Page 3 of 3”.
3. Page 1: “Know it from a crop.” / “Finish the label from works you already saved, on this device.” Top-right “Skip” (pages 1–2 only). Bottom “Continue”.
4. Page 2: “Frame, then patch.” / “Frame crops a saved work. One word is missing. Tap the chip that fills it.” “Skip” and “Continue”.
5. Page 3: “Restored stays here.” / “A miss stays reviewable. Saved keeps Restored pieces and misses.” Only “Continue” (finish).
6. “Skip” or finishing page 3 both enter the main quiz. Onboarding can be re-opened later from Settings via “Re-run onboarding”.
7. At launch the system may also ask for notification permission (standard system alert).

## Screens

### Quiz (home)
- Job title: “Patch the shard.” Subline depends on state: “Save a work, then patch.” / “Frame a crop.” / “Tap the missing word.” / “Frame another crop.” Date stamp under that (year.month.day).
- Controls: “Explore”, “Saved”, “Settings” (open sheets). Undo glyph (accessibility “Undo”; disabled when there is nothing to undo).
- Empty crate (`MUTE`): “Crate empty.” / “Save a work, then patch.” CTA “Explore”. If the crate could not be read: headline “The crate could not be read.” with the same line and “Explore”.
- Populated: status stamp `MUTE` / `SHUT` / `FRAMED` / `RESTORED` / `SMUDGE` with sentence “The crate is empty.” / “A work is shut.” / “A shard is framed.” / “A work is restored.” / “A chip is smudged.” Magnified crop with loupe glass. Caption prompt “Maker” or “Title” with a missing-word gap until patched. “Tap a word.” and word chips; wrong picks stay struck with “SMUDGE”. Full-width “Frame” (disabled until a shut work can be framed). “Crate” rail lists recent title words or “Save a painting.” Side tally “Restored” or “Misses” with a count.
- Recover banner (if needed): “Crate restored from a spare copy.” with “Hide”.
- Fault line examples: “Frame a crop first.”, “Wrong word. The hole stays.”, “Already smudged.”, “This work is already restored.”, “Nothing to undo.”, “Write failed. Frame or Patch again.”, and similar.

### Explore (sheet)
- Title “Explore”. Close (×). Label “National Gallery of Art”. Field placeholder “Search a work”. Keyboard toolbar “Done”.
- Empty search or shelf: list of local-shelf paintings (maker + title) with “Save” on each row. Tapping a row saves it as Shut; note “Saved.” or “Already in the crate.” Rows disable while a save is in progress.
- Empty list: “Shelf quiet.” / “Search the National Gallery of Art, or save from the local shelf.” CTA “Show shelf”.
- Search failure (empty): “Search failed.” plus fault line such as “Search failed. The crate shelf is waiting.” CTA “Retry”.
- Partial fault over results: fault text plus “Retry”.
- Closing Explore returns to Quiz.

### Saved (sheet)
- Title “Saved”. Close (× on phone; “Close” on larger width).
- Empty: “Nothing restored.” / “Patch a framed crop.” CTA “Patch” (dismisses to Quiz).
- Load failure: “Saved could not load.” with fault and “Close”.
- Populated: tallies “Restored” and “Misses”; sections “Restored” (title, maker, date) and “Misses” (struck spoken word, “SMUDGE”, painting title or “Unknown painting”, date). Optional “Return to the crop”.

### Settings (sheet)
- Title “Settings”. Close as above.
- Empty crate block: “Crate empty.” / “Save a work, then patch.” / “Explore”.
- Otherwise “Crate” with “Restored” and “Misses” counts.
- Optional “Write” fault with “Return to the crop”.
- “Collection”: “National Gallery of Art” / “nga.gov”; “Open access images” / “nga.gov/open-access-images”; footer “Public-domain paintings come from the National Gallery of Art.”
- “Support”: “Contact” / “tratteggio-loupe.pro/contact-us” (opens support page); “Reset the crate”.
- “Guide”: “Frame then patch” / “Frame punches one word. Patch files Restored.”
- “Undo” (disabled when empty); “Re-run onboarding”. Footer: “Undo drops the newest patch or miss. Reset removes the crate on this device.”
- Alert “Reset the crate?” / “This removes works, patches, and misses on this device. It cannot be undone.” Buttons “Keep” and “Reset the crate”. Reset also returns to onboarding.

### Frame then patch (guide sheet)
- Title “Frame then patch”. Headline “Frame, then patch.” Body: “Frame samples a saved painting that is not restored. One chip is punched from maker or title. Chips hang under the crop. A match files Restored. A miss keeps the hole.” Restored/Misses counts and current status stamp with next-tap line. CTA “Patch”, “Frame”, or “Explore” by state (Frame disabled if no shut work). Close returns to the prior sheet or Quiz.

## Features
- Save National Gallery of Art paintings into a personal crate (Shut works).
- Fall back to a built-in local shelf when search is empty or fails.
- Frame a magnified crop and punch one missing Maker or Title word.
- Patch by tapping the matching chip; file Restored.
- Miss by tapping a wrong chip; chip shows SMUDGE; hole stays reviewable.
- Undo the newest patch or miss.
- Browse Restored and Misses in Saved.
- Onboarding that explains crop → frame → patch → Saved.
- Settings credits, Contact, reset crate, re-run onboarding, and the Frame then patch guide.
- Light-only UI; portrait Quiz with Explore / Saved / Settings as sheets (no tab bar).

## Behaviours that can look like bugs
- Empty Quiz: “Crate empty.” / “Save a work, then patch.” — tap “Explore”, then “Save” on a work, then “Frame”.
- “Frame” disabled (“Needs a shut work.”) until at least one saved work is not restored — Save from Explore first.
- Word chips disabled until a crop is framed; hint “Frame a crop first.” if you try earlier — tap “Frame”.
- Wrong chip: “Wrong word. The hole stays.” / chip marked “SMUDGE” and stays disabled — tap another chip; miss is intentional.
- Correct chip after Restored: next tip “Frame another crop.”; “This work is already restored.” if you try to patch that work again — Frame a different shut work.
- “Undo” disabled with “Nothing to undo.” until a patch or miss exists.
- Explore “Shelf quiet.” when the list is empty — “Show shelf” or clear the search field to see the local shelf.
- Search faults leave the shelf waiting — “Retry” or use the shelf rows.
- Save while another save is running: other rows disabled until it finishes.
- Saved “Nothing restored.” until you patch — CTA “Patch” closes the sheet so you can Frame/Patch on Quiz.
- Reset alert: “Keep” cancels; “Reset the crate” wipes the crate and shows onboarding again.
- After reset or first install, onboarding loops until Skip/Continue — intentional.
- Status can cycle SHUT → FRAMED → SMUDGE → RESTORED as you work; that is the fold, not a stuck screen.

## Starter content and resume
- Device: no pre-filled Restored/Misses crate. Explore with an empty query shows a fixed local shelf of ten National Gallery paintings (for example Woman with a Parasol - Madame Monet and Her Son by Claude Monet, A Girl with a Watering Can by Auguste Renoir, The Boating Party by Mary Cassatt, Ginevra de' Benci [obverse] by Leonardo da Vinci, Symphony in White, No. 1: The White Girl by James McNeill Whistler, The Railway by Edouard Manet, Breezing Up (A Fair Wind) by Winslow Homer, Watson and the Shark by John Singleton Copley, Farmhouse in Provence by Vincent van Gogh, The Skater (Portrait of William Grant) by Gilbert Stuart).
- Simulator-only demo crate may pre-fill works, a framed crop, Restored, and Misses so Quiz opens ready to patch; real devices do not get that seed.
- Resume: yes — saved works, the current framed crop and chips, Restored, and Misses persist across launches until Reset. Unfinished framed crops stay until patched, reframed, or undone.

## Permissions
- Notifications: asked at cold launch via the system permission alert (no custom usage-description string in the app’s property list).
- Camera is not requested. (A camera usage string “This app does not use the camera.” is present in build settings but the app never asks for camera access.)

## Absent
Login or accounts; in-app purchase; ads; analytics; user-generated content shared with others; account deletion flow; App Tracking Transparency prompt.

## Data and support
Works, patches, and misses stay on this device (onboarding and Settings both say so). Support control: Settings → “Contact” (detail “tratteggio-loupe.pro/contact-us”), which opens the support page.

## Scanning and health
None. No barcode or QR scanning. No health, medical, or product-health information. Collection credit points to the National Gallery of Art and open-access images only.

## Platform
English development region; numbers and dates follow the device locale. Forced light appearance. Portrait only on iPhone and iPad (both supported). Minimum iOS 17.0.

## Category
Education
