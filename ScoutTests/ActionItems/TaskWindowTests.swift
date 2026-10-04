import Foundation
import Testing
@testable import Scout

@Suite("TaskWindow")
struct TaskWindowTests {
    private func task(_ n: Int, indent: Int = 0) -> ActionTask {
        ActionTask(
            id: UUID(), lineNumber: n, done: false,
            subject: "[#IOTA] Task \(n)", plainSubject: "Task \(n)", body: "",
            comments: [], deepLinks: [], snoozedUntil: nil, carriedInFrom: nil,
            indentLevel: indent)
    }

    private func tasks(_ count: Int) -> [ActionTask] { (0..<count).map { task($0) } }

    @Test("a fresh window shows one page")
    func freshWindowShowsOnePage() {
        let all = tasks(TaskWindow.pageSize * 3)
        let window = TaskWindow()
        #expect(window.visible(all).map(\.id) == all.prefix(TaskWindow.pageSize).map(\.id))
        #expect(window.hiddenCount(in: all) == TaskWindow.pageSize * 2)
    }

    @Test("a list shorter than a page is shown whole")
    func shortListShownWhole() {
        let all = tasks(3)
        let window = TaskWindow()
        #expect(window.visible(all).map(\.id) == all.map(\.id))
        #expect(window.hiddenCount(in: all) == 0)
        #expect(window.nextPageCount(in: all) == 0)
    }

    @Test("show more reveals one more page, never more than remain")
    func showMoreRevealsOnePage() {
        let all = tasks(TaskWindow.pageSize + 7)
        var window = TaskWindow()
        #expect(window.nextPageCount(in: all) == 7)
        window.showMore()
        #expect(window.visible(all).count == all.count)
        #expect(window.hiddenCount(in: all) == 0)
        #expect(window.nextPageCount(in: all) == 0)
    }

    @Test("the cut never strands a sub-task from its parent")
    func cutKeepsChildrenWithParent() {
        // The page boundary falls on a parent; its two children come along.
        var all = tasks(TaskWindow.pageSize)
        all.append(task(900, indent: 1))
        all.append(task(901, indent: 2))
        all.append(task(902))
        let window = TaskWindow()
        let shown = window.visible(all)
        #expect(shown.count == TaskWindow.pageSize + 2)
        #expect(shown.last?.lineNumber == 901)
        #expect(window.hiddenCount(in: all) == 1)
    }
}
