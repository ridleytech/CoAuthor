# CoAuthor Development Milestones

Last updated: 2026-10-25 (M0 audit, M1 implementation)

## M0 — Design and project audit

**Status: Complete**

### Design inventory

Design references live in `Designs/` in two layouts, all at 393pt width
(iPhone 16 logical width):

- `Designs/Other/**/*.png` — device-viewport renders at 393×852pt.
  Covers Account, Auth, Generation sheets, and Voice Capacity sheets.
- `Designs/Full Content/**/*.png` — expanded full-scroll-content renders
  (taller than the viewport). These are scroll references, not device
  heights; the device viewport remains ~393×852pt and content scrolls.

**Note:** most core screens (Dashboard, Create project, Project overview,
etc.) ship only a Full Content reference — there is no separate
default-viewport PNG for them. The fixed chrome (header, bottom CTA,
tab bar) is identifiable at the top and bottom of each full-content
render; everything between scrolls.

### Screen → design mapping

| Screen                        | Design reference(s)                                                                                                                                           |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Projects dashboard            | `Full Content/Dashboard/Full Content.png`                                                                                                                     |
| Create project                | `Full Content/Create project/Full Content.png`                                                                                                                |
| Project overview              | `Full Content/Project overview/Full Content.png`                                                                                                              |
| Generated ideas               | `Full Content/Generated ideas/Full Content.png`                                                                                                               |
| Idea comparison / story setup | `Full Content/Idea comparison & story setup/Full Content.png`                                                                                                 |
| Outline workspace             | `Full Content/Outline workspace/Full Content.png`                                                                                                             |
| Script reader                 | `Full Content/Script reader/Full Content.png`                                                                                                                 |
| Chapter edit / revision       | `Full Content/Full-screen chapter edit & revision/Full Content.png`                                                                                           |
| Saved voices                  | `Full Content/Saved Voices/Full Content.png`, `Full Content/Voice Capacity/Saved Voices — *`                                                                  |
| Voice detail & casting        | `Full Content/Saved Voice detail & casting picker/Full Content.png`, `Full Content/Voices & casting detail/Full Content.png`, `Full Content/Voice Capacity/*` |
| Create voice / auditions      | `Full Content/Voice Capacity/Create Voice — *`, `Audition alternatives & paid confirmation`, `Other/Voice Capacity/*`                                         |
| Narration studio              | `Full Content/Narration studio/Full Content.png`                                                                                                              |
| Audio review / generation     | `Full Content/Audio review & generation confirmation/Full Content.png`, `Full Content/Generation activity/Full Content.png`, `Other/Generation/*`             |
| Sound cues                    | `Full Content/Sound cues/Full Content.png`, `Full Content/Cue detail, edit & audition alternatives/Full Content.png`                                          |
| Documents / publishing        | `Full Content/Documents hub`, `Document previews`, `Publishing kit`, `Exports`, `Asset Library`                                                               |
| Settings / account            | `Full Content/Settings`, `Full Content/Account/*`, `Other/Account/*`                                                                                          |
| Auth                          | `Other/Auth/*`, `Full Content/Auth/Create account — validation`                                                                                               |
| Credits & usage               | `Full Content/Credits & Usage/*`                                                                                                                              |

### Existing app audit

- Xcode 16.1 project, iOS 18.1 deployment target, SwiftUI + SwiftData
  template (Item/timestamp scaffold), file-system-synchronized groups.
- Template `Item.swift` and `ContentView.swift` replaced in M1.

### Architecture (established in M1)

- **Composition root**: `CoAuthorApp` builds the `ModelContainer`
  (versioned schema `CoAuthorSchemaV1`) and the `AppCoordinator`.
- **Navigation**: `AppCoordinator` (`@Observable`) owns per-tab
  `NavigationPath`s and sheet state. `AppRoute` is the typed route
  enum; `AppTab` defines the four tabs.
- **Screens**: SwiftUI views send actions to `@Observable` view models.
- **Persistence**: repository protocol (`DashboardRepository`) with a
  SwiftData implementation; view models never touch `ModelContext`.
- **Design system**: `Theme` tokens (color, type, spacing) plus small
  reusable components (`CardContainer`, `StatusBadge`, `SavedPill`,
  button styles). Components are added per-milestone, not up front.

---

## M1 — Foundation and Projects dashboard

**Status: Complete**

### Scope

Projects dashboard, app shell (header, tab bar, fixed bottom CTA),
SwiftData project storage, minimal design system.

### Design references

- `Full Content/Dashboard/Full Content.png` (only reference; 393×1129pt
  expanded scroll, interpreted against a 393×852pt viewport)

### Functional interactions

- Load and display persisted projects (featured "continue" card,
  recent-projects list, stat tiles).
- Featured card actions: "Continue narration" → development placeholder;
  "Open story" → project route (development placeholder).
- "New project" (header button + bottom CTA) → development placeholder
  (M2 will implement the real screen).
- Review queue rows → development placeholder.
- Tab bar switches tabs; Library/Activity/Settings are labeled
  development placeholders.
- Empty state shown when no projects exist.
- "Saved" header pill is a status indicator only (sync is local).

**Not present in the design reference** (deliberately not implemented):
search field, filter controls, pull-to-refresh, project deletion UI.

### Persistence

- `Project` model: UUID, title, genre, setting descriptor, premise,
  narrator format, runtime target, chapter counts, stage/status,
  timestamps, optional cover asset name.
- `ReviewItem` model: dashboard review-queue rows (title, detail,
  action label, sort order).
- Versioned schema: `CoAuthorSchemaV1`.
- Development seed data written once (UserDefaults flag
  `coauthor.seeded.v1`), never recreated after user deletion.
- Previews/tests use in-memory containers with deterministic samples.

### Acceptance criteria — results

- [x] Dashboard matches neutral design language (no purple theme).
- [x] Fixed header (brand + Saved pill), fixed bottom CTA + tab bar.
- [x] Card content scrolls; fixed chrome does not (verified by
      `testDashboardRendersAndScrollsToReviewQueue` UI test — swipes until
      "Review queue" is visible, header/tab bar stay put).
- [x] Projects persist across relaunch (on-disk SwiftData store;
      seeded data present on subsequent launches).
- [x] Empty state when store is empty (`testViewModelEmptyState`).
- [x] Placeholders are clearly labeled; no fake success messages.
- [x] Build succeeds with zero warnings/errors.
- [x] Unit tests: 5/5 pass (`DashboardRepositoryTests`).
- [x] Visual verification: iPhone 16 simulator screenshot at
      `Verification/m1-dashboard.png` — side-by-side with design: header,
      title block, continue card (full-bleed cover), stat tiles, recent
      projects, fixed bottom CTA + tab bar all match. "Single narrator ·
      ~60 min target · Edited today, …" line wraps when the timestamp is
      long — acceptable natural wrap.
- Note: disk was at 100% capacity during this run (~7GB free), which
  caused intermittent build/test failures mid-session; cleared
  DerivedData and recovered.

### Design uncertainties recorded

- Dashboard hero artwork is a design-provided image with the story
  title baked in (`DashboardHero` asset). Per-project covers are a
  future asset pipeline question — the card supports a fallback
  gradient when no cover exists.
- Exact serif face for story titles: implemented with the system serif
  (`.serif` design) pending font confirmation.
- Badge warm tones sampled from PNG (`#FBF2DE`, `#F7F5F0`); borders
  and grays are approximate (±a few points).
- "Saved" pill behavior on tap is unspecified — treated as read-only.

### Files

- `CoAuthor/CoAuthorApp.swift` (rewritten — composition root)
- `CoAuthor/DesignSystem/Theme.swift`, `Components.swift`
- `CoAuthor/Models/Project.swift`, `ReviewItem.swift`
- `CoAuthor/Persistence/SchemaV1.swift`, `DashboardRepository.swift`, `SampleData.swift`
- `CoAuthor/Navigation/AppCoordinator.swift`
- `CoAuthor/Features/Dashboard/DashboardView.swift`, `DashboardViewModel.swift`, `DashboardComponents.swift`
- `CoAuthor/Features/Shared/DevelopmentPlaceholderView.swift`
- `CoAuthor/Assets.xcassets/DashboardHero.imageset/`
- `CoAuthor/AppShell.swift`
- `CoAuthorTests/CoAuthorTests.swift` (repository/VM tests)
- `CoAuthorUITests/CoAuthorUITests.swift` (scroll verification test)
- `Verification/m1-dashboard.png` (simulator screenshot)
- Removed: `ContentView.swift`, `Item.swift` (template)
- `Designs/` is gitignored — kept local as design reference.

---

## M2 — Project creation

**Status: In progress** — implemented; build/visual verification not yet
run (deferred at user's request — code-only pass).

### Scope implemented

- New-project form ("Start with a story. Step 1 of 3") per
  `Full Content/Create project`: premise editor (focus ring, required),
  working title, genre/setting, tone, runtime/format pickers, workflow
  radio cards (Guided / Complete package), read-only creative-preferences
  summary, "Generate story ideas" CTA disabled until premise is non-empty.
- Project overview per `Full Content/Project overview`: back header,
  Overview/Story/Audio/Publish tab strip (non-Overview tabs route to
  labeled placeholders), serif title + pills, Your Story card, production
  stages checklist, derived recommended-next-step card, recent-activity
  card, "Review chapter audio" bottom CTA.
- Save persists `Project` via repository then routes to the idea
  generation placeholder (M3). Cancel/back discards without saving.
- Shared chrome extracted: `BrandTopBar`, `BackTopBar`, `BottomCTA`,
  `CAFormField`, `CAPickerField`, `RadioOptionCard`.
- `Project` model extended (additive, defaults — lightweight-migration
  safe): `toneAudience`, `workflow`, `narratorName`, `scriptRevision`,
  and production-stage summary fields.
- `AppCoordinator.pop()` + `.ideaGeneration` and `.placeholder` routes.
- Continue card falls back to `stageLabel` when a project has no
  chapters yet (avoids "0 of 0 narrated" for new projects).

### Design interpretations recorded

- "Recent activity" derives entries from created/edited timestamps;
  rich activity feed is a later-milestone concern.
- "Recommended next step" shows the first incomplete production stage;
  the design's stale-asset warning ("audio outdated") requires M8/M9
  asset-revision tracking.
- "Edit →" (creative preferences) and "Change →" (workflow) route to
  labeled placeholders — real screens land with idea generation (M3).

### Files added/changed

- Added: `Features/Projects/NewProjectView.swift`,
  `NewProjectViewModel.swift`, `ProjectOverviewView.swift`,
  `ProjectOverviewViewModel.swift`
- Changed: `Models/Project.swift`, `Persistence/SampleData.swift`,
  `Persistence/DashboardRepository.swift` (`fetchProject(id:)`),
  `Navigation/AppCoordinator.swift` (`pop`, routes), `AppShell.swift`
  (real destinations), `DesignSystem/Components.swift`, `Theme.swift`,
  `DashboardComponents.swift` (continue-card fallback), `DashboardView.swift`
  (shared chrome)

### Validation

- Pending: build, unit tests, simulator screenshot.

## M3 — Ideas

**Status: In progress** — implemented; build/visual verification not yet
run (deferred at user's request — code-only pass).

### Scope implemented

- `Idea` model (pitch, expanded pitch, protagonist/stakes/angle,
  `isSelected`, `isSaved`, per-project `projectID`) added to
  `CoAuthorSchemaV1`.
- `IdeasRepository` protocol + SwiftData implementation;
  `saveChanges()` added to `DashboardRepository`.
- `MockIdeaGenerator` — deterministic local generation (no AI): the
  Nth generation for a project always returns the same idea.
- Generated-ideas screen per `Full Content/Generated ideas`: project
  header + Story tab strip, idea cards (Selected/New badges,
  protagonist/stakes/angle lines, Save/Refine/View-idea actions),
  "Keep exploring" card with working "Generate more ideas", and a
  "Compare selected ideas" CTA enabled when anything is selected.
- First open auto-generates three ideas for a project that has none
  (e.g., a project just created in M2).
- Comparison screen per `Full Content/Idea comparison & story setup`:
  stacked comparison cards with ink-bordered chosen card, "Select this
  idea" (persists `project.selectedIdeaID`), story-configuration
  summary, progress card, "Next: review your outline" card, and a
  "Select and generate outline" CTA that commits the choice and routes
  to the M4 outline placeholder.
- Shared `ProjectSectionTabs` (Overview/Story/Audio/Publish) extracted
  from the overview; Story routes to the ideas screen. `InfoPill`
  shared across screens.

### Design interpretations recorded

- No dedicated idea-detail design exists — "View idea →" routes to the
  comparison screen (the fullest idea rendering supplied).
- The ideas list "Selected" badge toggles membership in the compare
  set; the comparison screen's "Select this idea" picks the story
  direction (`selectedIdeaID`).
- "Refine" is an AI-driven action — routes to a labeled M12 backend
  placeholder rather than pretending to work.
- Comparison subtitle uses the actual selected count ("Compare N
  ideas"); the design's fixed "two" is a sample value.

### Files added/changed

- Added: `Models/Idea.swift`, `Persistence/IdeasRepository.swift`
  (repository + `MockIdeaGenerator`), `Features/Ideas/IdeasViewModel.swift`,
  `Features/Ideas/IdeasView.swift`, `Features/Ideas/IdeaComparisonView.swift`,
  `Features/Projects/ProjectSectionTabs.swift`
- Changed: `Models/Project.swift` (`selectedIdeaID`), `SchemaV1.swift`
  (+`Idea`), `Persistence/SampleData.swift` (design-matching ideas),
  `Persistence/DashboardRepository.swift` (`saveChanges`),
  `Navigation/AppCoordinator.swift` (`.ideaComparison`), `AppShell.swift`
  (real destinations), `ProjectOverviewView.swift` (shared tab strip)

### Validation

- Pending: build, unit tests, simulator screenshot.

## M4 — Outline

**Status: In progress** — implemented; build/visual verification not yet
run (deferred at user's request — code-only pass).

### Scope implemented

- `Outline`, `OutlineChapter`, `OutlineCharacter` models added to
  `CoAuthorSchemaV1` (UUID-keyed by `projectID`/`outlineID`, no
  bidirectional relationships — consistent with `Idea`).
- `OutlineRepository` protocol + SwiftData implementation;
  `MockOutlineGenerator` produces a deterministic 10-chapter draft for
  projects that reach the workspace without an outline (no AI calls);
  `project.hasOutline` marks outline existence.
- Outline workspace per `Full Content/Outline workspace`: back header,
  Story tab strip, "Review your outline." title + revision/workflow
  subtitle, horizontal sections picker (focused section in ink),
  featured chapter card (number · est. minutes, serif title, summary,
  turn, "Edit chapter"), N-chapter arc list with tap-to-feature and a
  "View all" chapter list, character card, private-ending card, and a
  sticky "Approve outline and generate script" CTA.
- Approval is real (`outline.approved`, `project.outlineApproved`,
  `stageLabel` update, persists); script generation routes to a labeled
  M5 placeholder.
- Chapter editing screen (`ChapterEditView`): title/summary/turn/
  estimated-minutes form bound to the model, saved via context on exit.
- Story tab across overview/ideas/comparison now routes to the outline
  once `hasOutline` is set; ideas comparison CTA routes here.

### Design interpretations recorded

- The sections picker focuses a section (ink pill); it does not filter
  the page — the workspace shows all cards regardless, matching the
  reference's single scrolling page.
- "Featured chapter" card = the chapter tapped in the arc list
  (defaults to Chapter 1); the design doesn't specify the mechanic.
- Character card renders the first character; multiple-character UI
  isn't specified by the reference.
- "Regenerate" / character edit route to labeled placeholders —
  backend-driven in M12.

### Files

- Added: `Models/Outline.swift`, `Persistence/OutlineRepository.swift`
  (repository + `MockOutlineGenerator`), `Features/Outline/
OutlineViewModel.swift`, `OutlineView.swift`, `ChapterListView.swift`,
  `ChapterEditView.swift`
- Changed: `Models/Project.swift` (`hasOutline`), `SchemaV1.swift`
  (+3 outline models), `Persistence/SampleData.swift`
  (design-matching outline for The Numbers Widow),
  `Navigation/AppCoordinator.swift` (`.outline`, `.chapterEdit`,
  `.chapterList`), `AppShell.swift` (destinations),
  `ProjectSectionTabs.swift` (`storyDestination`),
  `ProjectOverviewView.swift`, `IdeasView.swift`,
  `IdeaComparisonView.swift` (outline routing)

### Validation

- Pending: build, unit tests, simulator screenshot.

## M5 — Script

**Status: In progress** — implemented; build/visual verification not yet
run (deferred at user's request — code-only pass).

### Scope implemented

- `ScriptChapter` model (body, `revision`, `audioRevision`,
  `audioSeconds`/`audioPosition`, computed `wordCount`,
  `estimatedSeconds` at ~150wpm, `isAudioOutdated`) added to
  `CoAuthorSchemaV1`.
- `ScriptRepository` protocol + SwiftData implementation;
  `MockScriptGenerator` builds a deterministic draft from the approved
  outline's chapters on first open (no AI calls).
- Script chapter list (`ScriptChapterListView`): Story tab strip,
  "Your script." title, per-chapter rows (number, title, words · est.
  duration · revision, Outdated badge, chevron) → reader.
- Script reader per `Full Content/Script reader`: serif chapter title,
  meta line ("Chapter 1 / 10 · N words · ~m:ss · Script rN · Saved"),
  "Outdated" notice card when `audioRevision < revision` (audio rN vs
  current rN explained, "Review affected assets" → M8 placeholder),
  reader card ("READ · SETTING" eyebrow + serif paragraphs), reader-tools
  card ("Revisions (N)" → M12 placeholder), audio strip (play/pause
  toggle, narrator · ElevenLabs · 1×, position / duration), sticky
  "Edit chapter" CTA.
- Full-screen revision editor per `Full-screen chapter edit & revision`:
  breadcrumb ("title · rN → proposed rN+1 · Full-screen editor · Not
  applied"), Before/After cards (serif original vs editable proposed
  TextEditor, "Not yet applied" badge, "Keep original" discard), revision
  actions + production rows → M12 placeholders, "Try another revision"
  (cycles deterministic mock variants), audio-impact card, "Accept
  revision" persists the proposal as the next revision — leaving older
  audio marked outdated.
- Outline "Approve outline and generate script" CTA now routes to the
  script chapter list; approval + first-open generation produce the
  draft.

### Design interpretations recorded

- Reader shows real computed values (word count, ~150wpm duration) —
  the design's "812 words · ~5:42" is sample content, so numbers differ
  from the reference.
- The audio strip is display-only with a play/pause toggle — no audio
  file exists yet (playback is M8). Position/duration persist on the
  model so the strip looks like the reference.
- The revision screen edits the whole chapter body rather than a single
  selected passage — the design's before/after is a passage-level diff,
  which needs backend rewrite support (M12) to be meaningful.
- Script generation happens lazily on first open of the script list
  after outline approval — no separate "generate" screen exists in the
  references.

### Files

- Added: `Models/ScriptChapter.swift`, `Persistence/ScriptRepository.swift`
  (repository + `MockScriptGenerator`), `Features/Script/
ScriptViewModel.swift` (list + reader VMs), `RevisionViewModel.swift`,
  `ScriptChapterListView.swift`, `ScriptReaderView.swift`,
  `RevisionView.swift`
- Changed: `SchemaV1.swift` (+`ScriptChapter`),
  `Persistence/SampleData.swift` (design-matching script for The Numbers
  Widow: ch1 r4, audio r3, mid-playback), `Navigation/AppCoordinator.swift`
  (`.scriptChapters`, `.scriptReader`, `.chapterRevision`), `AppShell.swift`
  (destinations), `Features/Outline/OutlineView.swift` (CTA → script list)

### Validation

- Pending: build, unit tests, simulator screenshot.

## M6 — Saved voices

**Status: In progress** — implemented; build/visual verification not yet
run (deferred at user's request — code-only pass).

### Scope implemented

- `Voice` model (origin/kind/roleTag, descriptor, summary, tags,
  `sampleSeconds`, `isFavorite`, `isAvailable`, `designPrompt`,
  `savedVoiceID`, local name/labels/notes, `assignedProjectID` +
  `assignmentLabel`) and `CastAssignment` model (character, role label,
  approved flag) added to `CoAuthorSchemaV1`.
- `VoiceRepository` protocol + SwiftData implementation;
  `VoiceCapacity`/`MockVoiceCapacity` — illustrative 8-of-10-slot
  account capacity ("slots are not credits").
- Saved Voices list per `Full Content/Saved Voices`: Library-tab root
  (browse mode) or pushed with a casting context ("Choosing for
  {project} → Series narrator"), Create Voice → M7 placeholder,
  capacity card with slot progress bar, working search field,
  "Sync ElevenLabs voices" → M12 placeholder, filter pills (All /
  Favorites / Narrator / Custom / Source dropdowns + clear), count
  line, voice cards (favorite toggle, tags, sample time, Details /
  Favorite / Assign actions, ink border on the context project's
  assigned voice, "Set default narrator"/"Edit local metadata" on
  assigned voices), audition strip + "Use this voice" CTA in context
  mode (assigns narrator + pops).
- Voice detail per `Saved Voice detail & casting picker`: Audio tab
  strip, availability line, capacity card, narrator card (favorited
  badge, favorite/set-default buttons), audition strip with play/pause
  toggle, original design prompt + saved voice ID, local name/labels/
  notes card → `VoiceEditView` editor, "Remove from CoAuthor" (deletes
  the local record), "Manage ElevenLabs Voices" → M12, sticky
  "Use this voice — {project}" CTA when opened in casting context
  (persists `project.narratorName`, `narratorConfirmed`, voice
  assignment).
- Casting detail per `Voices & casting detail` (Audio tab): "Find your
  narrator.", capacity card, Create New Voice → M7 / Choose Saved Voice
  → context Saved Voices, reusing-a-voice note, narrator suggestion
  card (assigned voice or deterministic catalog suggestion, "Suggested"
  - "Not generated" badges), audition sample card, Voice Design prompt
    card (`project.voiceDesignPrompt`, Edit → M7), audition &
    performance direction, cast assignments (Suggested/Approved badges
    from `CastAssignment` records), casting-context note, manage/plan
    rows, "Approval ≠ paid generation" card, sticky "Approve voice
    description" CTA (persists `project.voicePromptApproved`, disables
    after approval).
- Audio tab across project screens now routes to the casting screen.

### Design interpretations recorded

- The audition player is cosmetic (play/pause toggle, fixed position) —
  no audio preview exists until backend audition support (M7/M12).
- "Assign" / "Use this voice" set the project's narrator and mark the
  voice's assignment — single-narrator model; multi-voice casting is
  not in the references.
- Cast assignments render approval state only; per-character approval
  toggles aren't specified in the reference, so badges are read-only.
- The Library tab now hosts Saved Voices (Library is active in the
  list design); the casting-context entry point is the Audio tab's
  "Choose Saved Voice".
- Capacity is a fixed mock (8/10, "Jordan's studio"); refresh/sync are
  labeled placeholders.

### Files

- Added: `Models/Voice.swift` (+`CastAssignment`),
  `Persistence/VoiceRepository.swift` (+`VoiceCapacity`,
  `MockVoiceCapacity`), `Features/Voices/VoicesViewModel.swift` (list +
  detail VMs), `CastingViewModel.swift`, `SavedVoicesView.swift`,
  `VoiceDetailView.swift`, `VoiceEditView.swift`, `CastingView.swift`,
  `VoiceComponents.swift` (capacity card, tag pills, audition strip,
  search field)
- Changed: `Models/Project.swift` (`voiceDesignPrompt`,
  `voicePromptApproved`), `SchemaV1.swift` (+`Voice`, +`CastAssignment`), `Persistence/SampleData.swift` (10 voices +
  Widow cast assignments), `Navigation/AppCoordinator.swift`
  (`.savedVoices`, `.voiceDetail`, `.voiceEdit`, `.voiceCasting`),
  `AppShell.swift` (destinations, Library root = Saved Voices),
  `ProjectSectionTabs.swift` (Audio → casting)

### Validation

- Pending: build, unit tests, simulator screenshot.

## M7 — Voice creation and casting

**Status: In progress** — implemented; build/visual verification not yet
run (deferred at user's request — code-only pass).

### Scope implemented

- 4-step voice-creation flow inside `VoiceCreationView`
  (`VoiceCreationViewModel` holds the draft; `.voiceCreation(projectID:)`
  route, project optional). `BackTopBar` gained a status-pill variant —
  "Draft" / "Not Saved" / "Saved" / "Assigned" per step, matching the
  references.
- Step 1 Describe (`Create Voice — Describe`): "Create a voice",
  project → Series narrator context line, 4-segment step bar, capacity
  card, slot-use note (or "Saving needs room" when capacity is full —
  Create Voice — Full draft variant), name field, voice-description and
  audition-text editors (prefilled from `project.voiceDesignPrompt`),
  step-flow note, "Generate previews" → step 2, "Choose an existing
  voice" → context Saved Voices.
- Step 2 Previews (`Audition alternatives & paid confirmation`):
  "A voice you believe.", Audio tab strip, "Choose Saved Voice", capacity
  card, three deterministic mock auditions (single-select checkbox,
  Selected · Ready badges, "Proposed name" line, play buttons), "Request
  another audition" card with "Paid · Est. unavailable" and "Confirm
  paid audition" → M12 placeholder, mini player for the selected
  preview, "Save Voice" → step 3.
- Step 3 Save (`Save Voice — Confirmation sheet`): "Review your
  previews", preview rows with the selected one highlighted, "Fresh
  provider check complete" line, name/description/audition review,
  context note — then a "Save Voice" CTA (added so the flow can
  proceed; the reference is a sheet state without one). Saving creates
  a persisted `Voice` (custom, provider-style `savedVoiceID`) — local
  stand-in for the provider save until M12.
- Step 4 Assign (`Assign new saved voice`): "Assign {name}?", saved
  provider voice card, Project → Role row, "current → new" replacement
  note, capacity card showing 9/10 after the save, "Confirm assignment"
  (persists narrator, marks voice assignment, clears the project's
  other voice assignments) and "Keep {current}".
- Success state (`Existing voice — Assignment success`): "{name} is
  assigned", reused/assigned confirmation card, audition row, capacity
  card, "Capacity is unchanged" card, "Back to casting" + "Open
  existing audio" → M8 placeholder.
- `VoiceCapacity` is now configurable (`usedSlots`/`totalSlots`) so the
  assign step can show post-save capacity; `MockVoiceCapacity` stays
  8/10. Casting detail shows the "Custom voice slots are full" note
  when no slots remain (Casting — Full variant).
- "Create New Voice" / "Create Voice" buttons on casting and saved
  voices now open the real flow (M7 placeholders removed).

### Design interpretations recorded

- The whole flow renders inside one pushed view (step state in the
  view model) — draft state stays coherent without threading it
  through routes.
- Audition previews are deterministic mocks — real previews are
  paid/provider operations (M12). "Confirm paid audition" routes to a
  labeled placeholder, no fake success.
- "Save Voice" creates the local `Voice` record immediately; the
  provider save, capacity recheck and confirmation sheet are M12 work.
  Slot count bumps to 9/10 on the assign step as the references show.
- The assign/success screens appear only in the new-voice flow;
  existing-voice assignment still happens instantly via M6's
  "Use this voice".

### Files

- Added: `Features/Voices/VoiceCreationViewModel.swift`,
  `Features/Voices/VoiceCreationView.swift`
- Changed: `Persistence/VoiceRepository.swift` (configurable
  `VoiceCapacity`), `DesignSystem/Components.swift` (`BackTopBar`
  status-pill variant), `Navigation/AppCoordinator.swift`
  (`.voiceCreation`), `AppShell.swift` (destination),
  `Features/Voices/CastingView.swift` (create button + slots-full
  variant), `Features/Voices/SavedVoicesView.swift` (create button)

### Validation

- Pending: build, unit tests, simulator screenshot.

## M8 — Narration

**Status: In progress** — implemented; build/visual verification not yet
run (deferred at user's request — code-only pass).

### Scope implemented

- `ScriptChapter` extended with `audioState` (none/queued/generating/
  failed/canceled/ready), `reviewState` (—/Suggested/Approved),
  `isSelectedForGeneration`, `audioTake` — all additive with defaults.
- `GenerationJob` model + `GenerationRepository` for the Activity feed.
- New `StatusBadgeKind` fills: ready (green), failed (red), info
  (blue) — sampled approximations.
- Narration studio (`Narration studio` reference): Audio tab,
  "Chapter recordings" + generated-count subtitle, narrator-confirmed
  card (script revision, selection summary "☑ A + B", estimated batch
  duration, "Change narrator / selection" → casting), ten chapter
  cards with checkboxes, per-state status + review badges ("Outdated",
  "● Ready", "✓ Approved", "Suggested", "Queued", "↻ Generating",
  "Failed", "Canceled", "· Not generated"), and per-state actions
  (Listen / Review, Select chapter, Cancel job, Retry — all real
  state changes persisted via the repository). Player strip + "Generate
  selected chapters" → audio review.
- Audio review (`Audio review & generation confirmation`): "Listen &
  review", Generation/Review status badges, player card (play/pause,
  narrator · ElevenLabs · 1×, scrub hint, progress bar, timestamps,
  Regenerate → M12 / Download → M10), source-passage card (first
  paragraph excerpt, "Add performance correction" → M12), "Confirm
  generation" card (Paid badge, batch summary, estimated duration,
  confirm → queues the selected batch), mini audio strip, "Approve
  audio" CTA → persists `reviewState = Approved`.
- Generation activity (`Generation activity` reference) — now the
  Activity tab root: project/task/status filter menus (functional),
  job cards with status badges and per-state actions (Cancel → real
  state change; Open result → audio review via linked chapter;
  Retry → requeue; View details / Review source → script reader),
  "Refresh activity" CTA.
- Audio tab destination is now narrator-aware (`audioDestination`):
  casting until `narratorConfirmed`, the studio after — updated at
  all 11 `ProjectSectionTabs` call sites. The dashboard's "Continue
  narration" and overview "Review chapter audio" CTAs now reach the
  studio via `.narration(projectID:)` (fixed a latent route/destination
  mismatch).

### Design interpretations recorded

- Generation/queue/cancel/retry are local state changes — no paid
  provider calls; the paid-generation confirmation flow is the
  review screen's card, and real jobs are M12 backend work.
- The player is cosmetic (play/pause + static progress); no audio
  file exists.
- "Generate selected chapters" routes to the review screen whose
  confirm card covers the whole batch — matching how the references
  couple review + confirmation.
- Activity filters work on the seeded job set; provider sync is M12.

### Files

- Added: `Models/GenerationJob.swift`,
  `Persistence/GenerationRepository.swift`,
  `Features/Narration/NarrationViewModel.swift` (studio + review VMs),
  `NarrationView.swift`, `AudioReviewView.swift`,
  `GenerationActivityView.swift`
- Changed: `Models/ScriptChapter.swift` (+4 audio-state fields),
  `SchemaV1.swift` (+`GenerationJob`), `Persistence/SampleData.swift`
  (per-chapter states matching the studio reference + 7 seeded jobs
  linked to chapters), `DesignSystem/Components.swift`/`Theme.swift`
  (ready/failed/info badges), `Navigation/AppCoordinator.swift`
  (`.narrationStudio`, `.audioReview`), `AppShell.swift` (Activity root,
  `.narration` → studio), `ProjectSectionTabs.swift`
  (`audioDestination`), all project screens (audio destination),
  `ProjectOverviewView.swift` (CTA → studio)

### Validation

- Pending: build, unit tests, simulator screenshot.

## M9 — Sound cues

**Status: Implemented (unverified — code-only pass, no build/test run
per maintainer request)**

- Scope: cue list/detail, approval, silence cues, generation and
  asset selection.
- Design: `Sound cues`, `Cue detail, edit & audition alternatives`.

### Implemented

- `SoundCue` model (`code` SC-NN, chapter, importance, category,
  source passage, placement text, generation prompt, review state,
  generation state, batch selection, alternative labels + preferred
  take) registered in `CoAuthorSchemaV1`; `CueRepository` protocol +
  SwiftData implementation.
- `SoundCuesView` — "Sound cues" + live subtitle ("N cues · N
  approved · Script rN · N selected"), filter card (chapter menu,
  Core/Optional, review status, generation), "Select approved →"
  (selects every approved cue that needs audio), cue cards with
  Approved/Suggested/Skipped + Ready/Not generated/Queued/"No audio
  file needed" badges, selected-dot toggle, "N more cues · Load →"
  card with the design's silence-eligibility note (shown standalone
  when everything is loaded), "Generate selected cues" CTA.
- `CueDetailView` — cue title + "SC-NN · chapter · Core ambience ·
  Script rN" subtitle, status badges, exact source passage,
  placement & mixing with a working "Edit cue instructions" editor,
  generation-prompt card with Approve/Reject/Skip actions
  (persisted), "Compare alternatives" A/B take picker (preferred
  take persisted; "Use existing" → M10 asset-library placeholder),
  batch-confirmation card ("SC-01 + SC-04 · N approved audio cues.
  Silence SC-03 excluded. Paid generation requires confirmation.")
  whose confirm queues the approved audio batch, cosmetic take
  player strip + "Select preferred sound" CTA.
- Silence cues get a reduced detail (source + placement + a
  "no audio generated" note — prompt/alternatives/player hidden)
  and are excluded from batch eligibility and the selection dot.
- `MockCueGenerator` produces a deterministic starter set (ambience
  per early chapter + one silence cue) for projects that reach the
  screen with no cues — no AI calls.
- `Project.cuesApproved`/`cuesTotal` are synced from real cue
  records on load and after review changes, so the overview pill
  stays accurate.
- Routes: `.soundCues(projectID:)`, `.cueDetail(cueID:)`; entry
  point via a "Sound cues →" link on the narration studio's
  narrator card.
- Seed: SC-01…SC-06 for The Numbers Widow matching the design's
  state mix (2 selected, 3 approved incl. 1 silence, 1 skipped).

### Interpretations

- The list's "32 cues" is the design's sample total — the app shows
  real counts; the "more cues" card appears only when filters leave
  cues hidden beyond the visible limit.
- The card's action line ("Source / Placement / Edit →" / "Review
  silence cue →") routes to the same detail screen — the reference
  provides no separate source/placement sheets.
- "Select preferred sound" dismisses the detail — the preferred
  take is already persisted when a row is tapped.
- Batch confirm sets approved audio cues to "Queued" (local state;
  paid/provider generation is M12). The design's "Estimate
  unavailable" copy is kept verbatim.
- Entry point: no design shows how cues are reached, so a "Sound
  cues →" link was added to the narration studio's narrator card —
  the only Audio screen that leads to both cue screens in the
  references.

### Files

- Added: `Models/SoundCue.swift`, `Persistence/CueRepository.swift`,
  `Features/Cues/CuesViewModel.swift`,
  `Features/Cues/SoundCuesView.swift`,
  `Features/Cues/CueDetailView.swift`
- Changed: `SchemaV1.swift` (+`SoundCue`),
  `Persistence/SampleData.swift` (+6 seeded cues),
  `Navigation/AppCoordinator.swift` (+2 routes), `AppShell.swift`
  (destinations), `Features/Narration/NarrationView.swift`
  ("Sound cues →" link)

### Validation

- Pending: build, unit tests, simulator screenshot.

## M10 — Documents and publishing

**Status: Implemented (unverified — code-only pass, no build/test run
per maintainer request)**

- Scope: document views, YouTube metadata, thumbnail selection,
  export UI.
- Design: `Documents hub`, `Document previews`, `Publishing kit`,
  `Exports`, `Asset Library`.

### Implemented

- **Documents hub** (Publish tab landing): "Working documents" with
  six computed document cards — Story Outline, Full Script, Sound
  Cue Guide, Sound Generation Tracker ("Update available" → "Update"
  clears the flag), Voice Prompts, YouTube Upload Data ("Draft" until
  the kit is saved). Live source lines and approval counts derive
  from real outline/script/cue/kit records; Preview routes to
  per-document previews (YouTube → the kit screen);
  Download/Regenerate → M12 placeholders. Export-options card and
  "Download complete package" CTA route to Exports.
- **Document previews** — real content per kind: the Full Script
  card renders Chapter 1's actual prose in serif (title, genre,
  setting, "Chapter 1 · title", paragraphs, "Estimate unavailable ·
  Regenerate"); the Sound tracker card renders a live cue table
  (ID / Cue / Review / Generation, silence → "No file"); outline /
  voice-prompts / YouTube kinds get source-accurate summary cards.
- **Publishing kit** — "Ready to be discovered." with Kit ready /
  Estimate unavailable badges, hero thumbnail (project cover asset),
  Title card with live char count, Description, Tags & pinned
  comment, Chapters & disclosure with `[timestamp]` placeholders from
  real chapter titles, Selected-thumbnail card. Copy actions write
  to the real clipboard with a confirmation line; "Save publishing
  kit" persists `isSaved`/`savedAt` (flips the doc card to Current).
- **Exports** — package-contents checklist derived from data
  (narration "N Outdated" from `isAudioOutdated`, sounds "N Missing
  audio files" from approved ungenerated cues), "Resolve before
  packaging" card (issue count; "Review affected assets" → studio),
  latest-export card, "Download does not publish to YouTube" note.
  "Prepare selected package" persists an `ExportRecord` and a
  "Package export" `GenerationJob` visible in Activity.
- **Asset library** — Library tab gains a Voices / Narration /
  Sound Effects section strip (Narration → M12 placeholder). Sound
  Effects shows a working search, context card (project with the
  most cues), selectable asset cards (ink border + check + waveform
  strip), Play/Reuse/Download row, "Reuse in another project" card
  targeting the context project's first audio cue ("Use this sound"
  persists `reusedTargetCode`), cosmetic player strip, "Open Saved
  Voices" CTA.
- Models: `PublishingKit`, `SoundAsset`, `ExportRecord` in
  `CoAuthorSchemaV1`; `PublishingRepository` protocol + impl.
  Widow seed: saved kit matching the design's copy, three sound
  assets, one completed export. Dev stores seeded before M10
  self-heal — the kit is generated on demand and the asset VM
  inserts the starter set when empty.
- Routes: `.documents`, `.documentPreview(projectID:, kind:)`,
  `.publishingKit`, `.exports`, `.assetLibrary`; Publish tab now
  lands on the documents hub on every project screen.

### Interpretations

- All download/regenerate/format-picker actions are labeled M12
  placeholders — no files are produced; "Prepare package" records
  the export locally.
- The YouTube document's "Preview" opens the kit screen — the kit
  _is_ the upload-data document; the generic youtube preview kind
  remains for completeness.
- Copy actions are real clipboard writes — the only kit interaction
  that needs no backend.
- Reuse is a local link (`reusedTargetCode`); copying assets into
  another project's cues is M12 backend work.
- "Generated today, 9:13 AM" in document source lines mirrors the
  design's sample timestamp — real generation tracking is M12.

### Files

- Added: `Models/PublishingKit.swift`, `Models/SoundAsset.swift`,
  `Models/ExportRecord.swift`,
  `Persistence/PublishingRepository.swift`,
  `Features/Publishing/PublishingViewModel.swift` (3 VMs),
  `Features/Publishing/DocumentsView.swift`,
  `Features/Publishing/DocumentPreviewView.swift`,
  `Features/Publishing/PublishingKitView.swift`,
  `Features/Publishing/ExportsView.swift`,
  `Features/Library/AssetLibraryViewModel.swift`,
  `Features/Library/AssetLibraryView.swift` (+`LibrarySectionTabs`)
- Changed: `SchemaV1.swift` (+3 models),
  `Persistence/SampleData.swift` (kit/assets/export seeds),
  `Navigation/AppCoordinator.swift` (+5 routes), `AppShell.swift`
  (destinations), `ProjectSectionTabs.swift` (Publish → hub),
  `Features/Voices/SavedVoicesView.swift` (Library section strip)

### Validation

- Pending: build, unit tests, simulator screenshot.

## M11 — Account and settings

**Status: Implemented (unverified — code-only pass, no build/test run
per maintainer request)**

- Scope: authentication screens, profile, connections, credits,
  preferences.
- Design: `Settings`, `Account/*`, `Auth/*`, `Credits & Usage/*`.

### Implemented

- **Settings root** (tab, replaces the M11 placeholder): profile card
  (initials avatar, name, email → Manage account), Credits & Usage
  summary card with the design's illustrative figures (72,400 /
  27,600 of 100,000, progress bar, reset date, "Illustrative data ·
  not a live balance" footnote), Creative preferences rows (story
  defaults, default narrator → Saved Voices, document templates,
  Saved Voices), Account & services rows, Support rows with real app
  version, Danger zone (Sign out → create-account screen, Delete
  account → reauth flow).
- **Manage account** — profile block, Edit profile / Change email /
  Security / Linked sign-in rows (M12 placeholders), plan & billing
  card ("Plan: Not available · Price: Not available" per design),
  Delete account link.
- **ElevenLabs connection** — connected card (masked key `•••• 9b41`,
  last sync, Test connection → local status note), custom-voice
  capacity card derived from the real voice count (8/10 etc.),
  Saved Voices / Voice-type limits / Manage account / Credits &
  Usage / Sync voices rows (sync shows the design's green
  confirmation note), default narrator, Reconnect / Disconnect → M12.
- **Notifications** — persisted `NotificationSettings` toggles
  (Generation finished / failed / low credits; Security alerts
  locked on per design), Email / Push delivery channels, "Save
  preferences" → green saved note.
- **Credits & Usage** — illustrative balance card (Refresh → M12),
  CoAuthor-subscription separation card, example breakdown, and
  recent-activity cards backed by **real `GenerationJob` records**
  with illustrative credit amounts ("Open result" routes to linked
  chapters; failed → "View details" placeholder). "Open Generation
  activity" switches to the Activity tab.
- **Delete account reauth** — warning card, data-loss explainer,
  "Export projects first" and Privacy Policy links, working
  password field with Show/Hide + focus ring, Continue gated on
  input → M12 final-confirmation placeholder, Cancel pops.
- **Create account** — name/email/password fields with the design's
  inline red validation (full name, valid email, 12+ mixed-case +
  number), required ToS checkbox, Apple/Google + Sign-in → M12
  placeholders. Validation is real; account creation needs the
  backend.
- Models: `AccountProfile` (Jordan Davis seeded; auto-created for
  pre-M11 dev stores) and `NotificationSettings` in
  `CoAuthorSchemaV1`; `AccountRepository`; `CreditsSnapshot`
  illustrative-data struct kept out of persistence on purpose.
- Routes: `.manageAccount`, `.creditsUsage`, `.providerConnection`,
  `.notificationSettings`, `.deleteAccount`, `.createAccount`;
  `SettingsBackBar` + `SettingsNavRow` shared chrome.

### Interpretations

- The seven `Credits & Usage` state variants (Loading / Low /
  Exhausted / Stale / Usage based / Not connected) are states of one
  card — the Connected design is implemented; state plumbing arrives
  with real balances in M12.
- All credit figures are labeled "Illustrative" exactly as the
  design requires — no fake "live" numbers.
- "Sign out" routes to the auth screen — the only honest mock of a
  signed-out state this milestone provides.
- Job-credit amounts are illustrative mappings by job kind, noted
  in the UI as such.

### Files

- Added: `Models/AccountProfile.swift`,
  `Models/NotificationSettings.swift`,
  `Persistence/AccountRepository.swift` (+`CreditsSnapshot`),
  `Features/Settings/SettingsViewModel.swift` (7 VMs),
  `SettingsView.swift`, `SettingsComponents.swift`,
  `ManageAccountView.swift`, `CreditsUsageView.swift`,
  `NotificationsView.swift`, `ProviderConnectionView.swift`,
  `DeleteAccountView.swift`, `CreateAccountView.swift`
- Changed: `SchemaV1.swift` (+2 models),
  `Persistence/SampleData.swift` (profile + notification seeds),
  `Navigation/AppCoordinator.swift` (+6 routes), `AppShell.swift`
  (Settings root + destinations), `DesignSystem/Theme.swift`
  (+`caDestructive`, `caNoteSuccess`)

### Validation

- Pending: build, unit tests, simulator screenshot.

## M12 — Backend integration

**Status: Data-path integration implemented (unverified — code-only
pass, no build/test run). Provider/paid actions remain stubs.**

- Scope: replace mocks with CoAuthor backend services incrementally.

### Architecture

- `BackendConfiguration.shared` — global mock ↔ backend switch
  (Settings → Developer → "Use backend data", persisted in
  UserDefaults; `baseURL` defaults to the local runner).
- `URLSessionBackendClient` — protocol-based transport
  (`get<Response: Decodable>`), injected into view models like the
  repositories.
- `BackendDTO` — decoding shapes for backend payloads; each DTO
  maps into a local `@Model` so hydration stays behind repository
  protocols and the app remains SwiftData-backed in both modes.
- Seam pattern everywhere: view model checks
  `BackendConfiguration.shared.useBackend` at the point a mock
  generator would run → `Task { await hydrate…() }` fetches, maps,
  and persists via the repository; **any failure falls back to the
  existing mock path**, so backend mode can't break the app.

### Backend (`backend/` — gitignored local scaffold)

- Node.js Lambda handler (`src/index.mjs`) serving real JSON reads:
  `GET /v1/projects/{id}/ideas`, `/outline`, `/cues`, `GET /v1/jobs`,
  `/v1/assets`, `/v1/credits` — deterministic data matching the
  app's DTOs (verified via direct handler invocation).
- POST generation endpoints remain `not_implemented` stubs —
  honest until provider keys exist.
- `src/local.mjs` dev runner on `localhost:3100`.

### Wired seams (mock → backend with fallback)

- `IdeasViewModel` — first-open generation hydrates from
  `/v1/projects/{id}/ideas`.
- `OutlineViewModel` — outline + chapters + characters from
  `/v1/projects/{id}/outline`.
- `CuesViewModel` — starter cue set from `/v1/projects/{id}/cues`.
- `GenerationViewModel` — activity feed hydrates from `/v1/jobs`
  when the local store is empty (avoids duplicating local jobs;
  projectID resolved by title).
- `AssetLibraryViewModel` — catalog from `/v1/assets`, falling back
  to the seeded starter set.
- `CreditsUsageViewModel` — balance from `/v1/credits` with a
  "Live data · backend" badge when live figures land (done in the
  pre-work commit).

### Deferred within M12

- Real provider calls (OpenAI text, ElevenLabs audio, credit
  reporting) — POST stubs await keys; all paid-action placeholders
  in the UI correctly remain placeholders.
- Voices catalog, document generation, exports packaging,
  auth/account mutations — still local/mock; next integration pass.
- Job/asset dedup across repeated hydration (hydrate-when-empty is
  the current policy).
- Schema versioning for the accumulated `CoAuthorSchemaV1`
  additive models before any shipped store.

### Files

- Added: `Backend/BackendDTOs.swift` (+ earlier `BackendClient.swift`,
  `BackendConfiguration.swift`); `backend/src/index.mjs` data routes
- Changed: `IdeasViewModel`, `OutlineViewModel`, `CuesViewModel`,
  `GenerationActivityView` (VM + init), `AssetLibraryViewModel` —
  backend seam + mock fallback each

### Validation

- Backend routes verified by invoking `handler` directly.
- Pending: app build, unit tests, simulator run with backend mode
  toggled on/off.

## M13 — Final UI and accessibility review

**Status: Not started**

- Scope: cross-screen consistency, accessibility, device testing,
  production readiness.
M13 proceeded as a static audit only — builds/tests were off per
standing instruction, so device testing and a simulator pass remain
pending.

### Findings and fixes

- **VoiceOver labels added** to every icon-only control found by an
  app-wide scan — all use dynamic labels that reflect state:
  - Play/pause players: narration studio, audio review (x2),
    script reader, shared audition strip (`VoiceAuditionStrip`),
    cue detail player, asset-library player, voice-detail strip.
  - Saved-voice favorite star: "Add/Remove {name} from favorites".
  - Narration chapter checkbox: "Select/Deselect {title}"
    (goes through `checkmark.square.fill`/`square` icons).
  - Filter chevron: VoiceOver now hears the filter label.
- **Decorative icons hidden** — `accessibilityHidden(true)` on
  icons whose meaning is carried by adjacent text: play icons in
  casting/voice-creation audition rows and the voice-creation mini
  player, the activity chevron, top-bar red square, all progress
  bars (credits %, capacity, color ramps — values stated in text),
  and the underline bar in `ProjectSectionTabs` tab items.
- **Cover art labeled** — `ProjectCard` covers read
  "{title} cover"; the publishing-kit hero reads
  "Selected thumbnail for {title}".
- **Selected-state trait** — `.isSelected` added to
  `ProjectSectionTabs` items and the bottom tab bar so VoiceOver
  announces which tab/section is active.
- **Consistency fix** — one raw `Color.red` in the activity feed's
  Cancel action switched to `Color.caDestructive`; the scan
  confirmed no other hard-coded colors outside `Theme.swift`.

### Reviewed, no change needed

- Arrow-right / chevron-right icons sit inside labeled text buttons
  — VoiceOver already reads the label.
- Tap targets: all icon buttons are 24–40pt glyphs inside
  `contentShape(Rectangle)` hit areas on 44pt+ rows.
- Dynamic Type: all text uses relative styles (`subheadline`,
  `.caSerif`, etc.) or the theme's scaled tokens.
- Status badges pair color with text/icons — no color-only
  semantics.

### Pending

- Simulator VoiceOver + Accessibility Inspector pass, Dynamic Type
  audit at AX sizes, and real-device check — requires a build.

## M14 — Provider-mode switch + hydration dedup

**Status: Code complete — verified at handler level; app build pending**

### Backend (gitignored scaffold)

- `src/config.mjs` — `PROVIDER_MODE=stub|live` env switch, the
  backend-side counterpart of `BackendConfiguration.useBackend`.
  Per-provider `enabled` checks: live mode + key present → real
  calls; either missing → that provider stays stubbed, so modes
  can mix during integration.
- `src/providers/openai.mjs` — `generateIdeas` / `generateOutline`
  via chat completions (JSON mode), prompts shaped to the app's
  `BackendDTO` decoding shapes.
- `src/providers/elevenlabs.mjs` — `textToSpeech` (inline base64
  audio until object storage exists) and `credits` (real
  subscription balance via `/v1/user/subscription`).
- POST generation routes dispatch live when the provider is
  enabled, else honest stubs; provider failures return
  `502 provider_error` — the app falls back to mock on any error.
- `GET /health` reports `{mode, openai, elevenlabs}` status;
  `GET /v1/credits` returns the live balance when enabled.
- `.env.example` documents the variables; `local.mjs` loads
  `backend/.env` when present.

### App-side dedup

Hydration paths upgraded from insert-when-empty to keyed upserts —
each re-fetches inside the async gap (closing the double-`load()`
race) and skips rows whose stable key already exists, so repeated
hydration is idempotent and never clobbers local edits:

- Ideas — keyed by title · Cues — by cue number
- Jobs — by project+kind+subject · Assets — by title+project
- Outline — re-checks for an existing outline after the await;
  inserts children only when none exists

### Verified

- Stub mode: all routes unchanged; health reports stub.
- Live mode, no keys: per-provider stub degradation.
- Live mode, bogus key: real OpenAI call attempted, 401 → clean
  `502 provider_error`.
- Pending: real-key end-to-end, app build.

### Still deferred

- S3/object storage for generated audio (returned inline for now).
- Voices catalog, document generation, exports packaging, auth.
- `CoAuthorSchemaV1` version bump before any shipped store.

## M15 — Remaining deferred items

**Status: Code complete — backend verified; app build pending**

### Backend (gitignored scaffold)

- `GET /v1/voices` — stub catalog mirrors `SampleData.makeVoices`
  (10 voices); live mode maps the real ElevenLabs `/v1/voices`
  library onto the app's Voice DTO shape.
- `POST /v1/projects/{id}/documents/{kind}:generate` — OpenAI
  produces spoiler-free markdown document bodies in live mode.
- `POST /v1/exports` — returns a GenerationJob-shaped record; real
  file packaging still pending.
- `POST /v1/auth/signin|signup` — development auth only: a `dev_`
  token + echoed profile; documented as pre-IdP.
- `AUDIO_STORAGE=inline|s3` + `src/storage/s3.mjs` — SigV4-signed
  PUT upload via pure `node:crypto` (no AWS SDK); audio routes
  return `audioUrl` + bytes instead of `audioBase64` when enabled.
- `matchRoute` now extracts path params (`{kind}:generate`).

### App

- `BackendClient.post` + DTOs: Voice, ExportResponse, AuthSession,
  DocumentResponse.
- `VoicesViewModel` — hydrates `/v1/voices` in backend mode,
  deduped by name so locally created voices survive.
- `ExportsViewModel` — posts `/v1/exports` in backend mode and
  records the returned job; local job fallback on failure.
- `CreateAccountViewModel` — `submit()` is now async: validates,
  then posts `/v1/auth/signup` in backend mode; `serverError`
  surfaces API failures; mock mode keeps the placeholder flow.
- **Schema versioning** — `CoAuthorSchemaV2` (same model set —
  the bump formalizes the accumulated additive models) +
  `CoAuthorMigrationPlan` lightweight stage; `ModelContainer` now
  takes the plan. Future schema edits get a real migration path.

### Verified

- Handler-level smoke: all new routes in stub mode, path-param
  extraction, auth validation, storage status in health.
- Pending: real-key provider calls, S3 credentials, app build.

### Still deferred

- Real identity provider (Cognito/JWT) — auth routes are dev-only.
- Export file packaging (documents → actual files/zip).
- Account deletion mutation; voice remove/sync mutations to
  provider.

## M16 — Export packaging + provider mutations

**Status: Code complete — backend verified; app build pending**

### Backend (gitignored scaffold)

- `src/packaging/zip.mjs` — dependency-free ZIP builder: CRC32 in
  pure JS + `zlib.deflateRawSync` compression. Verified end-to-end:
  `unzip -l`/`unzip -p` on a generated archive extract correctly.
- `src/packaging/package.mjs` — assembles the export package from
  the served data: `outline.txt`, `sound-cues.csv`, `voices.txt`,
  `project.json`, `README.txt`.
- `POST /v1/exports` now returns `{job, package}` — the package is
  a real zip in base64 (same convention as inline audio).
- Provider mutations:
  - `POST /v1/voices:sync` — live mode returns the real ElevenLabs
    library; stub returns the catalog (flagged `simulated`).
  - `DELETE /v1/voices/{id}` — live mode calls ElevenLabs DELETE;
    stub mode removes the row from the in-memory catalog so
    subsequent GETs reflect it.
  - `DELETE /v1/account` — dev-auth acknowledgment; documented as
    having no identity store.

### App

- `BackendClient.delete` added (GET/POST/DELETE now covered).
- `ExportsViewModel` — backend exports write the returned zip to
  the temp directory; `ExportRecord.sizeLabel`/`fileCount` update
  from the real package; the exports screen swaps "Download
  package" for a working **ShareLink** when a package exists.
- `VoiceDetailViewModel.removeFromCoAuthor` — DELETEs the provider
  voice (by `savedVoiceID`) in backend mode before removing the
  local record.
- `ProviderConnectionViewModel` — "Test connection" pings
  `GET /health` and reports per-provider live/stub status; "Sync
  voices" posts `/v1/voices:sync` and merges new catalog entries
  (name-deduped, local labels preserved).
- `DeleteAccountViewModel` — Continue calls `DELETE /v1/account`
  in backend mode; `serverError` surfaces failures and blocks
  proceeding.

### Verified

- Real zip produced and extracted via `unzip` (5 files, deflate).
- Voice delete removes from catalog; sync reflects it.
- Pending: app build, real ElevenLabs mutation calls.

### Still deferred

- Real identity provider (Cognito/JWT).
- S3 delivery for export packages (currently inline base64).
