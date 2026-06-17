import SwiftUI
import Combine

/// View-model backing the floating bar. Holds the search/filter state and the
/// current keyboard selection, and exposes intents the controller wires up.
@MainActor
final class PanelViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var activeKind: ClipKind? = nil
    @Published var pinnedOnly: Bool = false
    @Published var selection: Int = 0
    /// Bumped each time the bar is presented so the UI can reset scroll/state.
    @Published var presentToken: Int = 0

    let store: ClipStore

    /// Forwards `store.objectWillChange` so that `results` (a plain computed
    /// property reading `store`) participates in SwiftUI's update cycle. Without
    /// this, `ContentView` observed two objects and the live data path (`store`)
    /// could update without driving a `body` re-evaluation through `model`.
    private var storeObserver: AnyCancellable?

    /// Invoked when the user commits a clip (Enter / double click). The `plain`
    /// flag requests "paste as plain text" (Option held at commit time).
    var onPaste: ((ClipItem, _ plain: Bool) -> Void)?
    /// Invoked when the user dismisses the bar (Esc).
    var onClose: (() -> Void)?

    init(store: ClipStore) {
        self.store = store
        // Republish store changes so the two-object observation collapses into
        // one deterministic update path — fixes the live-while-open refresh case.
        storeObserver = store.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    var results: [ClipItem] {
        store.filtered(kind: activeKind, query: query, pinnedOnly: pinnedOnly)
    }

    func resetSelection() { selection = 0 }

    // MARK: Keyboard intents

    func moveSelection(_ delta: Int) {
        let count = results.count
        guard count > 0 else { selection = 0; return }
        selection = (selection + delta + count) % count
    }

    func commitSelection(plain: Bool = false) {
        let r = results
        guard r.indices.contains(selection) else { return }
        onPaste?(r[selection], plain)
    }

    func deleteSelection() {
        let r = results
        guard r.indices.contains(selection) else { return }
        store.delete(r[selection])
        selection = min(selection, max(0, results.count - 1))
    }

    func pinSelection() {
        let r = results
        guard r.indices.contains(selection) else { return }
        store.togglePin(r[selection])
    }

    /// Number 1…9 quick-select.
    func quickSelect(_ n: Int, plain: Bool = false) {
        let r = results
        guard r.indices.contains(n - 1) else { return }
        onPaste?(r[n - 1], plain)
    }
}
