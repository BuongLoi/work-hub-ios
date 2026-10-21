import SwiftUI
import WebKit
import UIKit

struct ContentView: View {
    @State private var isLoading = true
    @State private var loadFailed = false
    @State private var reloadToken = UUID()
    @State private var estimatedProgress: Double = 0.0

    let targetURL = URL(string: "https://work.buongloi.me")!

    // Linear / Raycast Indigo-Violet Brand Palette (#09090B, #6366F1, #8B5CF6)
    private let bgDark = Color(red: 0.035, green: 0.035, blue: 0.043)         // #09090B
    private let indigoAccent = Color(red: 0.388, green: 0.400, blue: 0.945)   // #6366F1
    private let violetAccent = Color(red: 0.545, green: 0.361, blue: 0.965)   // #8B5CF6

    var body: some View {
        ZStack(alignment: .top) {
            bgDark
                .ignoresSafeArea(.all)

            WebViewContainer(
                url: targetURL,
                isLoading: $isLoading,
                loadFailed: $loadFailed,
                progress: $estimatedProgress,
                reloadToken: reloadToken
            )
            .ignoresSafeArea(.all)

            // Top Loading Progress Bar
            if isLoading && estimatedProgress < 1.0 {
                GeometryReader { geo in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [indigoAccent, violetAccent]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(estimatedProgress), height: 3)
                        .animation(.linear(duration: 0.2), value: estimatedProgress)
                }
                .frame(height: 3)
            }

            // Initial Splash Screen
            if isLoading && estimatedProgress < 0.28 {
                VStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [indigoAccent, violetAccent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 74, height: 74)
                            .shadow(color: indigoAccent.opacity(0.4), radius: 18, x: 0, y: 8)

                        Image(systemName: "checklist.checked")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Text("Work Hub")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Personal Task & Knowledge Workspace • v2.0")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(white: 0.62))

                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: indigoAccent))
                        .scaleEffect(1.2)
                        .padding(.top, 6)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(bgDark)
                .ignoresSafeArea(.all)
                .transition(.opacity)
            }

            // Offline / Connection Error View
            if loadFailed {
                VStack(spacing: 20) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 52))
                        .foregroundColor(indigoAccent)

                    Text("Không thể kết nối Work Hub")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Vui lòng kiểm tra lại kết nối Internet hoặc trạng thái máy chủ work.buongloi.me.")
                        .font(.subheadline)
                        .foregroundColor(Color(white: 0.68))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        loadFailed = false
                        isLoading = true
                        reloadToken = UUID()
                    }) {
                        Label("Thử lại ngay", systemImage: "arrow.clockwise")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [indigoAccent, violetAccent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(24)
                            .shadow(color: indigoAccent.opacity(0.35), radius: 8, x: 0, y: 4)
                    }
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(bgDark)
                .ignoresSafeArea(.all)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isLoading)
    }
}

// MARK: - WKWebView Wrapper
struct WebViewContainer: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var loadFailed: Bool
    @Binding var progress: Double
    let reloadToken: UUID

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        config.websiteDataStore = WKWebsiteDataStore.default()
        config.applicationNameForUserAgent = "WorkHubApp/2.0 (iOS)"

        let userContentController = WKUserContentController()
        userContentController.add(context.coordinator, name: "haptic")
        config.userContentController = userContentController

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.bounces = true

        let darkColor = UIColor(red: 0.035, green: 0.035, blue: 0.043, alpha: 1.0)
        webView.backgroundColor = darkColor
        webView.isOpaque = false
        webView.scrollView.backgroundColor = darkColor
        webView.scrollView.contentInsetAdjustmentBehavior = .never

        // Pull-to-Refresh with Indigo Accent spinner
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor(red: 0.388, green: 0.400, blue: 0.945, alpha: 0.95)
        refreshControl.addTarget(context.coordinator, action: #selector(Coordinator.handleRefresh(_:)), for: .valueChanged)
        webView.scrollView.refreshControl = refreshControl

        // Observe loading progress
        context.coordinator.progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { wv, _ in
            DispatchQueue.main.async {
                self.progress = wv.estimatedProgress
            }
        }

        context.coordinator.webView = webView
        let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 25)
        webView.load(request)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if context.coordinator.lastReloadToken != reloadToken {
            context.coordinator.lastReloadToken = reloadToken
            let target = webView.url ?? url
            let request = URLRequest(url: target, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 25)
            webView.load(request)
        }
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        var parent: WebViewContainer
        weak var webView: WKWebView?
        var progressObservation: NSKeyValueObservation?
        var lastReloadToken: UUID?

        init(_ parent: WebViewContainer) {
            self.parent = parent
            self.lastReloadToken = parent.reloadToken
        }

        deinit {
            progressObservation?.invalidate()
        }

        @objc func handleRefresh(_ sender: UIRefreshControl) {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            webView?.reload()
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "haptic" {
                let styleStr = (message.body as? String) ?? "light"
                let style: UIImpactFeedbackGenerator.FeedbackStyle
                switch styleStr {
                case "heavy": style = .heavy
                case "medium": style = .medium
                case "rigid": style = .rigid
                case "soft": style = .soft
                default: style = .light
                }
                let impact = UIImpactFeedbackGenerator(style: style)
                impact.impactOccurred()
            }
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
                self.parent.loadFailed = false
            }
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.loadFailed = false
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.loadFailed = false
                webView.scrollView.refreshControl?.endRefreshing()
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            let nsError = error as NSError
            if nsError.code == NSURLErrorCancelled { return }
            DispatchQueue.main.async {
                self.parent.isLoading = false
                webView.scrollView.refreshControl?.endRefreshing()
            }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            let nsError = error as NSError
            if nsError.code == NSURLErrorCancelled { return }
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.loadFailed = true
                webView.scrollView.refreshControl?.endRefreshing()
            }
        }

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            webView.reload()
        }

        // Handle target="_blank" & window.open links (keep internal & Cloudflare Access inside WebView, open external bookmarks in Safari)
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            guard let targetURL = navigationAction.request.url else { return nil }
            let host = targetURL.host?.lowercased() ?? ""

            if host.contains("buongloi.me") || host.contains("buongloi.live") || host.contains("buongloi.dev") || host.contains("cloudflareaccess.com") {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                webView.load(navigationAction.request)
            } else {
                UIApplication.shared.open(targetURL, options: [:], completionHandler: nil)
            }
            return nil
        }
    }
}
