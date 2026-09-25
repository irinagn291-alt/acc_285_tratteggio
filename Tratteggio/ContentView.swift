import SwiftUI
import UIKit

/// Role: Loupe. Root shell. Onboarding cover, then the locked Quiz loupe. ReviewScreen is applied after onboarding.
struct ContentView: View {
    @State private var chrome: LoupeChrome
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(chrome: LoupeChrome = LoupeChrome.live()) {
        _chrome = State(wrappedValue: chrome)
    }

    var body: some View {
        ZStack {
            LoupeInk.background.ignoresSafeArea()
            if chrome.isBooting {
                Image(LoupeArt.splash)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
            } else if chrome.showsOnboarding {
                OnboardingCover(
                    onSkip: { Task { await chrome.finishOnboarding() } },
                    onFinish: { Task { await chrome.finishOnboarding() } }
                )
            } else {
                QuizView(chrome: chrome)
            }
        }
        .preferredColorScheme(.light)
        .tint(LoupeInk.accent)
        .animation(SnapMotion.swap(reduceMotion), value: chrome.showsOnboarding)
        .animation(SnapMotion.swap(reduceMotion), value: chrome.isBooting)
        .task { await chrome.boot() }
        .task {
            for await notice in NotificationCenter.default.notifications(named: .loupeJob) {
                if let job = LoupeJob.parse(notification: notice) {
                    chrome.handle(job)
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            Task { await chrome.handle(phase: phase) }
        }
        .onOpenURL { chrome.handle(url: $0) }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            chrome.refreshDay()
        }
    }
}

#Preview {
    ContentView()
}
