import UIKit
import WebKit

@MainActor
enum CloudKitWebSignIn {
    static func authenticate(at url: URL) async throws -> String {
        guard isAppleSignInURL(url) else { throw CloudKitWebError.invalidSignInURL }
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              var presenter = scene.windows.first(where: \.isKeyWindow)?.rootViewController else {
            throw CloudKitWebError.signInUnavailable
        }
        while let presented = presenter.presentedViewController { presenter = presented }
        return try await withCheckedThrowingContinuation { continuation in
            let controller = SignInController(url: url) { continuation.resume(with: $0) }
            let navigation = UINavigationController(rootViewController: controller)
            presenter.present(navigation, animated: true) {
                navigation.presentationController?.delegate = controller
            }
        }
    }

    static func isAppleSignInURL(_ url: URL) -> Bool {
        guard url.scheme == "https", let host = url.host?.lowercased() else { return false }
        return ["apple.com", "icloud.com", "apple-cloudkit.com"].contains {
            host == $0 || host.hasSuffix("." + $0)
        }
    }

    static func token(from url: URL) -> String? {
        let callback = CloudKitWebConfiguration.callbackURL
        guard url.scheme == callback.scheme, url.host == callback.host,
              url.port == callback.port, url.path == callback.path else { return nil }
        return URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?
            .first(where: { $0.name == "ckWebAuthToken" })?.value.flatMap { $0.isEmpty ? nil : $0 }
    }
}

@MainActor
private final class SignInController: UIViewController, WKNavigationDelegate, WKUIDelegate,
    UIAdaptivePresentationControllerDelegate {
    private let signInURL: URL
    private var completion: ((Result<String, Error>) -> Void)?
    private let webView = WKWebView()

    init(url: URL, completion: @escaping (Result<String, Error>) -> Void) {
        signInURL = url
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Hubungkan iCloud"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        view.backgroundColor = .systemBackground
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        webView.load(URLRequest(url: signInURL))
    }

    @objc private func cancel() { finish(.failure(CancellationError())) }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        finish(.failure(CancellationError()))
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { decisionHandler(.cancel); return }
        if let token = CloudKitWebSignIn.token(from: url) {
            decisionHandler(.cancel)
            finish(.success(token))
        } else if CloudKitWebSignIn.isAppleSignInURL(url) || url.absoluteString == "about:blank" {
            decisionHandler(.allow)
        } else {
            decisionHandler(.cancel)
            finish(.failure(CloudKitWebError.invalidSignInURL))
        }
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil { webView.load(navigationAction.request) }
        return nil
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code != NSURLErrorCancelled { finish(.failure(error)) }
    }

    private func finish(_ result: Result<String, Error>) {
        guard let completion else { return }
        self.completion = nil
        webView.stopLoading()
        if let navigationController, navigationController.presentingViewController != nil {
            navigationController.dismiss(animated: true) { completion(result) }
        } else { completion(result) }
    }
}
