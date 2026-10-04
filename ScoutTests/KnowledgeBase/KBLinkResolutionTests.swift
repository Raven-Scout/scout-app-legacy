import Foundation
import Testing
@testable import Scout

@Suite("KBIndex link resolution")
struct KBIndexResolveTests {
    private let index = KBIndex(
        stemToPath: ["alex": "knowledge-base/people/alex.md", "people": "knowledge-base/people.md"],
        outByFile: [:], textByFile: [:], typeByFile: [:], vaultNames: [])

    @Test func bareStemAnyCase() {
        #expect(index.resolve("alex") == "knowledge-base/people/alex.md")
        #expect(index.resolve("Alex") == "knowledge-base/people/alex.md")
        #expect(index.resolve("ghost") == nil)
    }

    @Test func pathFormMatchesByPathSuffix() {
        #expect(index.resolve("people/alex") == "knowledge-base/people/alex.md")
        #expect(index.resolve("knowledge-base/people/alex") == "knowledge-base/people/alex.md")
        #expect(index.resolve("knowledge-base/people") == "knowledge-base/people.md")
        #expect(index.resolve("projects/alex") == nil)             // stem exists, path doesn't
    }

    @Test func anchorsAndExtension() {
        #expect(index.resolve("alex#Role") == "knowledge-base/people/alex.md")
        #expect(index.resolve("alex#^block1") == "knowledge-base/people/alex.md")
        #expect(index.resolve("alex.md") == "knowledge-base/people/alex.md")
        #expect(index.resolve("people/alex.md#Role") == "knowledge-base/people/alex.md")
    }

    @Test func anchorOnlyIsTheLinkingNote() {
        #expect(index.resolve("#Role", from: "knowledge-base/hub.md") == "knowledge-base/hub.md")
        #expect(index.resolve("#Role") == nil)
    }
}

@MainActor
@Suite("KnowledgeBaseService path and anchor links")
struct KBServicePathLinkTests {
    /// hub → `[[people/alex]]`; alex → `[[hub#Intro]]` + `[[#Role]]`;
    /// priya → `[[hub.md]]`. All resolve; none is dangling.
    private func makeKB() throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("kbpath-\(UUID().uuidString)")
        let kb = root.appendingPathComponent("knowledge-base")
        let people = kb.appendingPathComponent("people")
        try FileManager.default.createDirectory(at: people, withIntermediateDirectories: true)
        try "Owner: [[people/alex]].".write(to: kb.appendingPathComponent("hub.md"), atomically: true, encoding: .utf8)
        try "See [[hub#Intro]] and [[#Role]].\n## Role"
            .write(to: people.appendingPathComponent("alex.md"), atomically: true, encoding: .utf8)
        try "[[hub.md]]".write(to: people.appendingPathComponent("priya.md"), atomically: true, encoding: .utf8)
        return root
    }

    @Test func pathAnchorAndExtensionLinksBecomeEdgesAndBacklinks() async throws {
        let root = try makeKB(); defer { try? FileManager.default.removeItem(at: root) }
        let svc = KnowledgeBaseService(scoutDirectory: root, fileEvents: NoopFS())
        await svc.reparseAndWait()

        #expect(svc.resolveWikilink("people/alex") == "knowledge-base/people/alex.md")
        #expect(svc.outgoingLinks(for: "knowledge-base/hub.md")
                == [KBLink(target: "people/alex", resolved: "knowledge-base/people/alex.md")])
        #expect(svc.graphStats().links == 2)                       // hub–alex, hub–priya
        #expect(Set(svc.backlinks(for: "knowledge-base/hub.md").map(\.path))
                == ["knowledge-base/people/alex.md", "knowledge-base/people/priya.md"])
        let toAlex = svc.backlinks(for: "knowledge-base/people/alex.md")
        #expect(toAlex.map(\.path) == ["knowledge-base/hub.md"])
        #expect(toAlex.first?.excerpt == "Owner: [[people/alex]].")
        #expect(svc.networkStats().dangling.isEmpty)
    }
}
