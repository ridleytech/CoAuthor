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

**Status: Not started**

- Scope: cue list/detail, approval, silence cues, generation and
  asset selection.
- Design: `Sound cues`, `Cue detail, edit & audition alternatives`.

## M10 — Documents and publishing

**Status: Not started**

- Scope: document views, YouTube metadata, thumbnail selection,
  export UI.
- Design: `Documents hub`, `Document previews`, `Publishing kit`,
  `Exports`, `Asset Library`.

## M11 — Account and settings

**Status: Not started**

- Scope: authentication screens, profile, connections, credits,
  preferences.
- Design: `Settings`, `Account/*`, `Auth/*`, `Credits & Usage/*`.

## M12 — Backend integration

**Status: Not started**

- Scope: replace mocks with CoAuthor backend services incrementally.

## M13 — Final UI and accessibility review

**Status: Not started**

- Scope: cross-screen consistency, accessibility, device testing,
  production readiness.
