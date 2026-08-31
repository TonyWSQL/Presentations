---
name: build-travel-post
description: Turn a raw trip capture file (blogposts/travel/YYYY-MM.md) into styled travel blog post draft(s) — .html + .json pairs under blogposts/drafts/ — following the V-RodDBA voice and template conventions in blogposts/CLAUDE.md. Use when the user wants to build/generate a blog post from a travel capture file, or asks to turn trip notes into a draft.
---

# Build Travel Post

Turns raw trip notes into styled, on-brand blog post drafts. This skill is **draft-generation only** — it never touches images, `publish.py`, or `blogposts/published.json`.

## Inputs

- An explicit path to a capture file, e.g. `blogposts/travel/2026-10.md`, passed as an argument.
- If no path is given, find the most recently modified file under `blogposts/travel/` and confirm with the user that it's the right one before proceeding.

## Process

1. **Read the source of truth first.** Read `blogposts/CLAUDE.md` in full — it is the authoritative style guide (voice/tone rules, HTML structure per post type, icon color mapping, pun guidelines, JSON metadata schema, filename conventions). Do not rely on memory of these rules or duplicate them here; always re-read the live file since it may have changed.
2. **Read the structural reference.** Read `blogposts/travel-template.html` to see the current concrete markup/CSS patterns (masthead, route ribbon, day cards, footer) to match — don't invent new structure or styling.
3. **Read the capture file** the user pointed to (or the most recent one under `blogposts/travel/`).
4. **Determine the split.** Look for distinct legs — different destinations, separate events, or multi-day gaps between clusters of activity (the September trip was split into 4 posts: Lafayette→Jacksonville, Jacksonville→Miami, Miami→Key West→Miami, Miami→home). Propose a specific split (post count + suggested filenames using the `YYYY-MM-description` convention from CLAUDE.md) and **ask the user to confirm or adjust before writing any files.** Never split or merge silently.
5. **Surface thin/TBD content.** If a day or section has placeholder text (e.g. "location TBD", "presentation TBD", or is otherwise sparse), call it out explicitly to the user as an open question — ask whether to leave a clearly-marked placeholder in the draft or wait until it's filled in. Never invent specifics (restaurant names, talk titles, people's reactions) to fill a gap. Regardless of which way the draft handles it, **add each TBD item to `blogposts/Todo.md`** under a section for this post (matching the existing per-post checklist format there), so it isn't lost once the draft is written.
6. **Generate the draft(s).** For each confirmed post, write:
   - `blogposts/drafts/{filename}.html` — following the travel template structure exactly: masthead, route ribbon (airport/city codes with arrows), intro paragraph, one day card per day with the vertical day-label sidebar and activity rows, closing paragraph, footer. `BEGIN TRAN` and `COMMIT TRAN` each get their **own dedicated `<p>`, wrapped in `<code>`** — `BEGIN TRAN` as `<code>BEGIN TRAN</code><br/>` at the top of the intro paragraph (followed by the intro text on the next line, upright not italic), `COMMIT TRAN` as its own standalone `<p><code>COMMIT TRAN</code></p>` after the last day card and before the footer. Never fold either into an activity row's body text — see `blogposts/travel/2026-08-albany.html` for the reference pattern. Apply icon circle colors by activity type per CLAUDE.md. Leave day-photo `<img src="">` empty using the existing `display:none`/`onload`/`onerror` placeholder pattern — do not add real image URLs.
   - **Do not add a Thank You or Photo Album block at draft time**, even though the Albany reference post has both. Those only exist post-event — the Thank You block needs real organizer names to credit, and the Photo Album block needs a real album link, neither of which exist while a trip is still upcoming. Instead, log both as follow-up items in `blogposts/Todo.md` (per step 5) so they get added once the trip has happened and the post is being finalized for publish.
   - `blogposts/drafts/{filename}.json` — every field publish.py understands listed explicitly (title, labels, publishedAt, updatePublishedDate, htmlFile), even at default values. Use `publishedAt: null` unless the user gives a specific scheduled time; `updatePublishedDate: false` by default.
7. **Apply the voice rules while drafting**, not just structure:
   - Prefer specific logistics ("Up at 4am, coffee before the car") over generic gloss ("early morning travel")
   - Avoid bow-wrap closers that summarize a paragraph's vibe after it's already shown
   - Avoid identical closing rhythm across multiple day-card rows/entries
   - Avoid rhetorical-question sign-offs
   - Keep puns sparse (max one or two per post) and only where they land naturally
   - Let some entries stay flat/unresolved — not everything needs a satisfying wrap-up
8. **Report back** a summary: which files were written, which legs they cover, and a list of anything still open (unresolved TBDs, missing images to wire up later, anything you left as a placeholder).

## Explicit non-goals

- Do not create, move, or reference real image files or GitHub raw URLs — leave `src=""` placeholders.
- Do not modify `blogposts/publish.py` or `blogposts/published.json`, and do not check whether a post is "already published" — this skill only ever produces new drafts.
- Do not silently decide the leg split — always confirm with the user first.
- Do not fabricate specifics for thin/TBD sections — ask instead.
