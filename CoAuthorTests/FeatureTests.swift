//
//  FeatureTests.swift
//  CoAuthorTests
//
//  Coverage added after M16 — DTO contract decoding, cue batch
//  logic, hydration dedup, and form validation.
//

import XCTest
import SwiftData
@testable import CoAuthor

/// Decodes canned JSON through any BackendClient — lets hydrate
/// paths run without a network.
private struct StubBackendClient: BackendClient {
    /// path → JSON payload
    var responses: [String: String]

    private func decode<Response: Decodable>(
        _ path: String, as type: Response.Type
    ) throws -> Response {
        guard let json = responses[path],
              let data = json.data(using: .utf8)
        else { throw URLError(.badServerResponse) }
        return try JSONDecoder().decode(Response.self, from: data)
    }

    func get<Response: Decodable>(_ path: String) async throws -> Response {
        try decode(path, as: Response.self)
    }
    func post<Response: Decodable>(
        _ path: String, body: some Encodable
    ) async throws -> Response {
        try decode(path, as: Response.self)
    }
    func delete<Response: Decodable>(_ path: String) async throws -> Response {
        try decode(path, as: Response.self)
    }
}

// MARK: - DTO contract decoding

final class BackendDTOTests: XCTestCase {

    func testIdeaDTODecodesAndMapsToModel() throws {
        let json = """
        [{"title":"The Quiet Ledger","tagline":"t","pitch":"p",
          "expandedPitch":"ep","protagonist":"pr","stakes":"s",
          "angle":"a"}]
        """
        let dtos = try JSONDecoder().decode(
            [BackendDTO.Idea].self, from: Data(json.utf8))
        XCTAssertEqual(dtos.count, 1)
        let model = dtos[0].model(projectID: UUID(), sortOrder: 0)
        XCTAssertEqual(model.title, "The Quiet Ledger")
        XCTAssertEqual(model.expandedPitch, "ep")
    }

    func testCueDTODecodes() throws {
        // schema_version 5 envelope — a Silence cue and a Bed cue.
        let json = """
        {"schema_version":"1.0.0","metadata_type":"sound_cues",
         "cue_count":2,"cues":[
          {"cue_id":"WCK03","chapter_number":1,
           "chapter_title":"The Monday Money","sound":"Marked pause",
           "priority":"Core","treatment":"Silence",
           "story_passage":"x","generation_complete":"N/A"},
          {"cue_id":"WCK01","chapter_number":1,
           "chapter_title":"The Monday Money","sound":"Repast kitchen",
           "priority":"Core","treatment":"Bed",
           "story_passage":"p","start_and_placement":"s",
           "stop_and_fade":"e","sound_to_find_or_generate":"g",
           "mixing_guidance":"m","generation_complete":"No"}]}
        """
        let set = try JSONDecoder().decode(
            BackendDTO.CueSet.self, from: Data(json.utf8))
        XCTAssertEqual(set.cues.count, 2)

        let silence = set.cues[0].model(projectID: UUID())
        XCTAssertEqual(silence.number, 3)
        XCTAssertTrue(silence.isSilence)
        XCTAssertFalse(silence.needsAudio)

        let bed = set.cues[1].model(projectID: UUID())
        XCTAssertEqual(bed.category, "Ambience")
        XCTAssertEqual(bed.generationPrompt, "g")
        XCTAssertEqual(bed.generationState, "Not generated")
        XCTAssertTrue(bed.placementText.contains("s"))
    }

    func testOutlineDTODecodesV5Sections() throws {
        let json = """
        {"schema_version":"1.0.0","metadata_type":"outline",
         "story_title":"T",
         "sections":[
          {"heading":"Writing approach","level":1,
           "paragraphs":["Close third person."]},
          {"heading":"Main characters","level":1,
           "paragraphs":["Naomi Mercer, 32 — Payroll clerk. Detail."]},
          {"heading":"Ending and central question","level":1,
           "paragraphs":["The ending.","Central question: Who pays?"]}],
         "chapters":[
          {"chapter_number":1,"chapter_title":"Ch One",
           "paragraphs":["p1","p2"]}]}
        """
        let dto = try JSONDecoder().decode(
            BackendDTO.Outline.self, from: Data(json.utf8))
        XCTAssertEqual(dto.writingApproach, "Close third person.")
        XCTAssertEqual(dto.privateEnding, "The ending.")
        XCTAssertEqual(dto.centralQuestion, "Who pays?")
        XCTAssertEqual(dto.characters.first?.name, "Naomi Mercer")
        XCTAssertEqual(dto.characters.first?.role, "Payroll clerk")
        XCTAssertEqual(dto.chapters.first?.chapterNumber, 1)
        XCTAssertEqual(dto.chapters.first?.summary, "p1\n\np2")
    }

    func testScriptDTODecodesChapters() throws {
        let json = """
        {"schema_version":"1.0.0","metadata_type":"full_script",
         "story_title":"T","front_matter":["Detroit 1981"],
         "sections":[],
         "chapters":[
          {"chapter_number":2,"chapter_title":"Ch Two",
           "paragraphs":["body"]}]}
        """
        let dto = try JSONDecoder().decode(
            BackendDTO.Script.self, from: Data(json.utf8))
        XCTAssertEqual(dto.settingLabel, "Detroit 1981")
        XCTAssertEqual(dto.chapters.first?.chapterNumber, 2)
    }

    func testVoicePromptsAndYouTubeDecode() throws {
        let prompts = """
        {"schema_version":"1.0.0","voices":[
          {"character_name":"Narrator","role":"Series narrator",
           "voice_design_prompt":"Warm baritone.",
           "preview_text":"p","performance_notes":"n",
           "saved_voice_name":null,"saved_voice_id":null}]}
        """
        let yt = """
        {"schema_version":"1.0.0","youtube_title":"T | Audiobook",
         "video_description":"d","tags":["a","b"],
         "pinned_comment":"c"}
        """
        let decoder = JSONDecoder()
        let voices = try decoder.decode(
            BackendDTO.VoicePrompts.self, from: Data(prompts.utf8))
        let youtube = try decoder.decode(
            BackendDTO.YouTubeData.self, from: Data(yt.utf8))
        XCTAssertEqual(voices.voices.first?.characterName, "Narrator")
        XCTAssertEqual(voices.voices.first?.role, "Series narrator")
        XCTAssertEqual(youtube.tags, ["a", "b"])
    }

    func testThumbnailShortsAndPanelDecode() throws {
        let thumbs = """
        {"schema_version":"1.0.0","story_title":"T","chapters":[
          {"chapter_number":1,"title":"Ch One","audio_file":null,
           "thumbnails":[
            {"id":"01A","image_file":"01A.png",
             "title":"The question","image_prompt":"Church basement.",
             "order":1}]}]}
        """
        let shorts = """
        {"schema_version":"1.0.0","story_title":"T","chapters":[
          {"chapter_number":1,"chapter_title":"Ch One",
           "audio_file":null,"script_text":"body"}],
         "clips":[{"clip_id":"WCK_S01","title":"Short title",
           "description":"d","tags":["t"],
           "estimated_duration_seconds":58}]}
        """
        let meta = """
        {"schema_version":"1.0.0",
         "recommended_first_three_clip_ids":["WCK_S01"],
         "clips":[{"clip_id":"WCK_S01",
           "recommendation_heading":"Short 1 Intrusion",
           "chapter_number":1,"title":"Short title",
           "description":"d","tags":["t"],
           "estimated_duration_seconds":58}]}
        """
        let panel = """
        {"schema_version":"1.0.0",
         "tracks":{"A1":"Narration (existing)","A2":"Ambience beds"},
         "level_convention":"levels","pan_convention":"pan",
         "file_naming":"naming"}
        """
        let decoder = JSONDecoder()
        let t = try decoder.decode(
            BackendDTO.ChapterThumbnails.self, from: Data(thumbs.utf8))
        let s = try decoder.decode(
            BackendDTO.YouTubeShorts.self, from: Data(shorts.utf8))
        let m = try decoder.decode(
            BackendDTO.ShortsMetadata.self, from: Data(meta.utf8))
        let p = try decoder.decode(
            BackendDTO.CuePanel.self, from: Data(panel.utf8))

        XCTAssertEqual(t.first?.id, "01A")
        XCTAssertEqual(t.first?.imagePrompt, "Church basement.")
        XCTAssertEqual(s.chapters.first?.scriptText, "body")
        XCTAssertEqual(s.clips?.first?.clipId, "WCK_S01")
        XCTAssertEqual(m.recommendedFirstThreeClipIds, ["WCK_S01"])
        XCTAssertEqual(m.clips.first?.estimatedDurationSeconds, 58)
        XCTAssertEqual(p.tracks?["A2"], "Ambience beds")
        XCTAssertEqual(p.levelConvention, "levels")
    }

    func testProjectMetaDecodesToProject() throws {
        let json = """
        [{"title":"What the Church Kept",
          "genre":"community crime drama and mystery.",
          "settingDescriptor":"Detroit in November and December 1981.",
          "premise":"After church treasurer Isaiah Mercer dies…",
          "narratorFormat":"Single narrator",
          "runtimeTargetMinutes":65,"totalChapters":10,
          "narratedChapters":0,"stageLabel":"Ready to produce",
          "status":"draft"}]
        """
        let metas = try JSONDecoder().decode(
            [BackendDTO.ProjectMeta].self, from: Data(json.utf8))
        let project = metas[0].model()
        XCTAssertEqual(project.title, "What the Church Kept")
        XCTAssertEqual(project.runtimeTargetMinutes, 65)
        XCTAssertEqual(project.status, .draft)
    }

    func testExportResponsePackageBothModes() throws {
        let inline = """
        {"status":"ready","job":{"projectTitle":"P","kind":"Package export",
         "subject":"s","provider":"CoAuthor","status":"ready","detail":"d",
         "startedAt":0},
         "package":{"format":"zip","fileCount":5,"bytes":100,
          "files":["a.txt"],"base64":"AAAA"}}
        """
        let s3 = """
        {"status":"ready","job":{"projectTitle":"P","kind":"Package export",
         "subject":"s","provider":"CoAuthor","status":"ready","detail":"d",
         "startedAt":0},
         "package":{"format":"zip","fileCount":5,"bytes":100,
          "files":["a.txt"],"downloadUrl":"https://b.s3.r.amazonaws.com/k"}}
        """
        let decoder = JSONDecoder()
        let inlineDTO = try decoder.decode(
            BackendDTO.ExportResponse.self, from: Data(inline.utf8))
        let s3DTO = try decoder.decode(
            BackendDTO.ExportResponse.self, from: Data(s3.utf8))

        XCTAssertNotNil(inlineDTO.package?.zipData)
        XCTAssertNil(inlineDTO.package?.remoteURL)
        XCTAssertNil(s3DTO.package?.zipData)
        XCTAssertEqual(
            s3DTO.package?.remoteURL?.absoluteString,
            "https://b.s3.r.amazonaws.com/k")
        XCTAssertEqual(inlineDTO.job.kind, "Package export")
    }

    func testAuthSessionDecodesErrorAndToken() throws {
        let ok = """
        {"token":"dev_x","profile":{"name":"J","email":"j@x.co"},
         "development":true}
        """
        let bad = """
        {"error":"invalid_signup"}
        """
        let decoder = JSONDecoder()
        let okDTO = try decoder.decode(
            BackendDTO.AuthSession.self, from: Data(ok.utf8))
        let badDTO = try decoder.decode(
            BackendDTO.AuthSession.self, from: Data(bad.utf8))
        XCTAssertEqual(okDTO.token, "dev_x")
        XCTAssertEqual(okDTO.profile?.email, "j@x.co")
        XCTAssertNil(badDTO.token)
        XCTAssertEqual(badDTO.error, "invalid_signup")
    }

    func testCreditsResponseAppliesLiveFigures() throws {
        let json = """
        {"provider":"elevenlabs","remaining":9000,"limit":100000,
         "illustrative":false}
        """
        let response = try JSONDecoder().decode(
            CreditsSnapshot.Response.self, from: Data(json.utf8))
        let live = CreditsSnapshot().applying(response)
        XCTAssertEqual(live.remaining, 9000)
        XCTAssertEqual(live.limit, 100000)
        XCTAssertTrue(live.isLive)
        XCTAssertEqual(live.used, 91000)
    }
}

// MARK: - Cue logic

@MainActor
final class CuesViewModelTests: XCTestCase {
    private var container: ModelContainer!
    private var projects: SwiftDataDashboardRepository!
    private var cues: SwiftDataCueRepository!
    private var scripts: SwiftDataScriptRepository!
    private var project: Project!

    override func setUpWithError() throws {
        let schema = CoAuthorSchema.current
        container = try ModelContainer(
            for: schema,
            configurations: [
                ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            ])
        projects = SwiftDataDashboardRepository(
            context: container.mainContext,
            defaults: UserDefaults(suiteName: "t-\(UUID())")!)
        cues = SwiftDataCueRepository(context: container.mainContext)
        scripts = SwiftDataScriptRepository(context: container.mainContext)

        project = Project(
            title: "T", genre: "g", settingDescriptor: "s",
            premise: "p", narratorFormat: "Single narrator",
            runtimeTargetMinutes: 60, totalChapters: 10,
            narratedChapters: 0, stageLabel: "x", status: .inProgress,
            scriptRevision: 4)
        try projects.insert(project)
        let seeds: [(Int, String, String, String)] = [
            (1, "Ambience", "Approved", "Not generated"),
            (2, "Spot", "Approved", "Not generated"),
            (3, "Silence", "Approved", "No audio file needed"),
            (4, "Spot", "Suggested", "Not generated"),
        ]
        for seed in seeds {
            try cues.insert(SoundCue(
                projectID: project.id, number: seed.0, title: "C\(seed.0)",
                chapterTitle: "Ch", importance: "Core", category: seed.1,
                reviewState: seed.2, generationState: seed.3))
        }
    }

    private func makeViewModel() -> CuesViewModel {
        let vm = CuesViewModel(
            projectID: project.id,
            projectsRepository: projects,
            cueRepository: cues,
            scriptRepository: scripts,
            backendClient: StubBackendClient(responses: [:]))
        vm.load()
        return vm
    }

    func testBatchEligibleExcludesSilenceAndUnapproved() {
        let vm = makeViewModel()
        XCTAssertEqual(vm.cues.count, 4)
        // C1+C2 approved & need audio; C3 is silence; C4 unapproved.
        XCTAssertEqual(vm.batchEligible.map(\.number), [1, 2])
    }

    func testSilenceCueCannotBeSelected() {
        let vm = makeViewModel()
        let silence = vm.cues.first { $0.number == 3 }!
        vm.toggleSelection(silence)
        XCTAssertFalse(silence.isSelected)
    }

    func testGenerateSelectedQueuesAndClears() {
        let vm = makeViewModel()
        vm.selectApproved()
        XCTAssertEqual(vm.selectedCues.map(\.number), [1, 2])
        vm.generateSelected()
        XCTAssertTrue(vm.selectedCues.isEmpty)
        XCTAssertEqual(
            vm.cues.filter { $0.generationState == "Queued" }
                .map(\.number),
            [1, 2])
    }

    func testSubtitleCountsApprovedAndSelected() {
        let vm = makeViewModel()
        vm.selectApproved()
        XCTAssertEqual(
            vm.subtitle,
            "4 cues · 3 approved · Script r4 · 2 selected")
    }
}

// MARK: - Hydration dedup

@MainActor
final class IdeaHydrationTests: XCTestCase {
    private var container: ModelContainer!
    private var projects: SwiftDataDashboardRepository!
    private var ideas: SwiftDataIdeasRepository!
    private var project: Project!

    private let ideasJSON = """
        [{"title":"A","tagline":"t","pitch":"p","expandedPitch":"e",
          "protagonist":"pr","stakes":"s","angle":"a"},
         {"title":"B","tagline":"t","pitch":"p","expandedPitch":"e",
          "protagonist":"pr","stakes":"s","angle":"a"}]
        """

    override func setUpWithError() throws {
        let schema = CoAuthorSchema.current
        container = try ModelContainer(
            for: schema,
            configurations: [
                ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            ])
        projects = SwiftDataDashboardRepository(
            context: container.mainContext,
            defaults: UserDefaults(suiteName: "t-\(UUID())")!)
        ideas = SwiftDataIdeasRepository(context: container.mainContext)
        project = Project(
            title: "T", genre: "g", settingDescriptor: "s",
            premise: "p", narratorFormat: "Single narrator",
            runtimeTargetMinutes: 60, totalChapters: 10,
            narratedChapters: 0, stageLabel: "x", status: .draft)
        try projects.insert(project)
        BackendConfiguration.shared.useBackend = true
    }

    override func tearDownWithError() throws {
        BackendConfiguration.shared.useBackend = false
    }

    private func client() -> StubBackendClient {
        StubBackendClient(responses: [
            "/v1/projects/\(project!.id.uuidString)/ideas": ideasJSON
        ])
    }

    /// Polls until the condition holds or the deadline passes —
    /// hydrate runs on a Task inside load().
    private func waitUntil(
        _ condition: () -> Bool,
        timeout: TimeInterval = 3
    ) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        return condition()
    }

    func testHydrateInsertsBackendIdeas() async throws {
        let vm = IdeasViewModel(
            projectID: project.id,
            projectsRepository: projects,
            ideasRepository: ideas,
            backendClient: client())
        vm.load()
        let hydrated = await waitUntil { vm.ideas.count == 2 }
        XCTAssertTrue(hydrated, "backend ideas should hydrate")
        XCTAssertEqual(Set(vm.ideas.map(\.title)), ["A", "B"])
    }

    func testDoubleLoadDoesNotDuplicateIdeas() async throws {
        let vm = IdeasViewModel(
            projectID: project.id,
            projectsRepository: projects,
            ideasRepository: ideas,
            backendClient: client())
        vm.load()
        let hydrated = await waitUntil { vm.ideas.count == 2 }
        XCTAssertTrue(hydrated)

        // Simulate the .onAppear race — a second load before/after
        // hydration must not duplicate rows.
        vm.load()
        let stillTwo = await waitUntil { vm.ideas.count == 2 }
        XCTAssertTrue(stillTwo)
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(try ideas.fetchIdeas(projectID: project.id).count, 2)
    }

    func testFailedBackendFallsBackToMock() async throws {
        let vm = IdeasViewModel(
            projectID: project.id,
            projectsRepository: projects,
            ideasRepository: ideas,
            backendClient: StubBackendClient(responses: [:]))  // 404
        vm.load()
        let ok = await waitUntil { vm.ideas.count == 3 }
        XCTAssertTrue(ok, "mock fallback should generate 3 ideas")
    }
}

// MARK: - Create-account validation

@MainActor
final class CreateAccountValidationTests: XCTestCase {

    private func valid() -> CreateAccountViewModel {
        let vm = CreateAccountViewModel(
            backendClient: StubBackendClient(responses: [:]))
        vm.name = "Jordan Davis"
        vm.email = "jordan@example.com"
        vm.password = "ValidPassw0rd!"
        vm.acceptedTerms = true
        return vm
    }

    func testValidFormPasses() async {
        let vm = valid()
        let passed = await vm.submit()
        XCTAssertTrue(passed)
    }

    func testInvalidFieldsProduceErrors() async {
        let vm = valid()
        vm.name = "Jordan"           // single word
        vm.email = "not-an-email"
        vm.password = "short"
        vm.acceptedTerms = false
        let passed = await vm.submit()
        XCTAssertFalse(passed)
        XCTAssertNotNil(vm.nameError)
        XCTAssertNotNil(vm.emailError)
        XCTAssertNotNil(vm.passwordError)
        XCTAssertNotNil(vm.termsError)
    }

    func testErrorsHiddenUntilSubmitAttempted() {
        let vm = CreateAccountViewModel(
            backendClient: StubBackendClient(responses: [:]))
        XCTAssertNil(vm.nameError)
        XCTAssertNil(vm.emailError)
        XCTAssertNil(vm.termsError)
    }

    func testBackendErrorSurfaces() async {
        BackendConfiguration.shared.useBackend = true
        defer { BackendConfiguration.shared.useBackend = false }
        let vm = CreateAccountViewModel(
            backendClient: StubBackendClient(responses: [:]))  // 404
        vm.name = "Jordan Davis"
        vm.email = "jordan@example.com"
        vm.password = "ValidPassw0rd!"
        vm.acceptedTerms = true
        let passed = await vm.submit()
        XCTAssertFalse(passed)
        XCTAssertNotNil(vm.serverError)
    }
}
