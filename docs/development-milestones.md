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

**Status: Not started**

- Scope: idea generator UI, deterministic mock generation, results
  list, idea detail, selection, persistence.
- Design: `Full Content/Generated ideas`, `Idea comparison & story setup`.

## M4 — Outline

**Status: Not started**

- Scope: outline sections, chapter summaries, editing, approval.
- Design: `Full Content/Outline workspace`.

## M5 — Script

**Status: Not started**

- Scope: chapter list, script reader/editor, persistence, word count
  and revision tracking.
- Design: `Full Content/Script reader`, `Full-screen chapter edit & revision`.

## M6 — Saved voices

**Status: Not started**

- Scope: voice list/detail, search, favorites, narrator assignment,
  mock account capacity.
- Design: `Full Content/Saved Voices`, `Saved Voice detail & casting picker`,
  `Voices & casting detail`, `Voice Capacity/Saved Voices — *`.

## M7 — Voice creation and casting

**Status: Not started**

- Scope: voice descriptions, auditions, selection, custom voice-slot
  limits, save confirmations.
- Design: `Voice Capacity/Create Voice — *`, `Casting — Full`,
  `Audition alternatives & paid confirmation`, `Other/Voice Capacity/*`.

## M8 — Narration

**Status: Not started**

- Scope: chapter selection, generation confirmation, job states,
  audio review.
- Design: `Narration studio`, `Audio review & generation confirmation`,
  `Generation activity`, `Other/Generation/*`.

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
