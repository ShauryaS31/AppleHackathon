#if os(iOS)
import RecalledCore
import SwiftUI
import UIKit

final class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let content = SharePlaceholderView { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: nil)
        }
        let host = UIHostingController(rootView: content)
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        host.didMove(toParent: self)
    }
}

private struct SharePlaceholderView: View {
    let onDone: @MainActor () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text(RecalledPlaceholder.appName)
                .font(.title)
            Text("Sharing support is coming soon.")
            Button("Done", action: onDone)
        }
        .padding()
    }
}
#endif
