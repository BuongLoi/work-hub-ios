import SwiftUI
import WebKit
import UIKit
import UserNotifications
import AVFoundation

struct ContentView: View {
    @State private var isLoading = true
    @State private var loadFailed = false
    @State private var reloadToken = UUID()
    @State private var estimatedProgress: Double = 0.0
    @State private var activeURL = URL(string: "https://work.buongloi.me")!

    private let bgDark = Color(red: 0.035, green: 0.035, blue: 0.043)         // #09090B
    private let indigoAccent = Color(red: 0.388, green: 0.400, blue: 0.945)   // #6366F1
    private let violetAccent = Color(red: 0.545, green: 0.361, blue: 0.965)   // #8B5CF6

    var body: some View {
        ZStack(alignment: .top) {
            bgDark
                .ignoresSafeArea(.all)

            WebViewContainer(
                url: activeURL,
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

                    Text("Shift Cockpit • AI Vision & Focus • v2.1")
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
        .onReceive(NotificationCenter.default.publisher(for: .workHubQuickAction)) { note in
            guard let shortcutType = note.object as? String else { return }
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()

            let targetPath: String
            switch shortcutType {
            case "me.buongloi.workhub.aiscan":
                targetPath = "https://work.buongloi.me/today?action=ai-scan"
            case "me.buongloi.workhub.focus":
                targetPath = "https://work.buongloi.me/today?action=focus"
            case "me.buongloi.workhub.kanban":
                targetPath = "https://work.buongloi.me/tasks?view=board"
            case "me.buongloi.workhub.scratchpad":
                targetPath = "https://work.buongloi.me/scratchpad"
            default:
                targetPath = "https://work.buongloi.me/today"
            }

            if let newURL = URL(string: targetPath) {
                activeURL = newURL
                reloadToken = UUID()
            }
        }
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
        config.applicationNameForUserAgent = "WorkHubApp/2.1 (iOS)"

        let userContentController = WKUserContentController()
        userContentController.add(context.coordinator, name: "haptic")
        userContentController.add(context.coordinator, name: "workhub")
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
            let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 25)
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
                triggerHaptic(styleStr: styleStr)
                return
            }

            guard message.name == "workhub",
                  let body = message.body as? [String: Any],
                  let type = body["type"] as? String else { return }

            let payload = body["payload"]

            switch type {
            case "haptic":
                if let dict = payload as? [String: Any], let style = dict["style"] as? String {
                    triggerHaptic(styleStr: style)
                } else {
                    triggerHaptic(styleStr: "medium")
                }

            case "scheduleNotifications":
                handleScheduleNotifications(payload)

            case "setSound":
                if let dict = payload as? [String: Any], let enabled = dict["enabled"] as? Bool {
                    if enabled {
                        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
                        try? AVAudioSession.sharedInstance().setActive(true)
                    } else {
                        try? AVAudioSession.sharedInstance().setActive(false)
                    }
                }

            case "shareText":
                if let dict = payload as? [String: Any], let text = dict["text"] as? String {
                    presentShareSheet(items: [text])
                }

            default:
                break
            }
        }

        private func triggerHaptic(styleStr: String) {
            DispatchQueue.main.async {
                let style: UIImpactFeedbackGenerator.FeedbackStyle
                switch styleStr {
                case "heavy": style = .heavy
                case "medium": style = .medium
                case "rigid": style = .rigid
                case "soft": style = .soft
                default: style = .light
                }
                let generator = UIImpactFeedbackGenerator(style: style)
                generator.prepare()
                generator.impactOccurred()
            }
        }

        private func presentShareSheet(items: [Any]) {
            DispatchQueue.main.async {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return }

                let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = rootVC.view
                    popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }

                var topVC = rootVC
                while let presented = topVC.presentedViewController {
                    topVC = presented
                }
                topVC.present(activityVC, animated: true)
            }
        }

        private func handleScheduleNotifications(_ payload: Any?) {
            guard let items = payload as? [[String: Any]] else { return }
            let center = UNUserNotificationCenter.current()

            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                guard granted else { return }
                center.removeAllPendingNotificationRequests()

                let isoFractional = ISO8601DateFormatter()
                isoFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let isoStandard = ISO8601DateFormatter()

                for item in items {
                    guard let id = item["id"] as? String,
                          let dateStr = item["date"] as? String,
                          let title = item["title"] as? String,
                          let body = item["body"] as? String else { continue }

                    guard let date = isoFractional.date(from: dateStr) ?? isoStandard.date(from: dateStr) else { continue }
                    if date <= Date() { continue }

                    let content = UNMutableNotificationContent()
                    content.title = title
                    content.body = body
                    content.sound = .default

                    let components = Calendar.current.dateComponents(
                        [.year, .month, .day, .hour, .minute, .second],
                        from: date
                    )
                    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                    let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                    center.add(request, withCompletionHandler: nil)
                }
            }
        }

        // Auto-grant Microphone & Camera capture inside WKWebView for Voice-to-Task & AI Vision
        @available(iOS 15.0, *)
        func webView(
            _ webView: WKWebView,
            requestMediaCapturePermissionFor origin: WKSecurityOrigin,
            initiatedByFrame frame: WKFrameInfo,
            type: WKMediaCaptureType,
            decisionHandler: @escaping (WKPermissionDecision) -> Void
        ) {
            decisionHandler(.grant)
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
