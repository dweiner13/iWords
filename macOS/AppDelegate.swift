//
//  AppDelegate.swift
//  words (iOS)
//
//  Created by Dan Weiner on 4/10/21.
//

import Cocoa
import Combine
import Intents

@main
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    static var shared: AppDelegate!

    @IBOutlet weak var latinToEnglishItem: NSMenuItem!
    @IBOutlet weak var englishToLatinItem: NSMenuItem!

    private var direction: Dictionary.Direction {
        get {
            keyWindowController()?.direction ?? DEFAULT_DIRECTION
        }
    }

    var observation: Any?

    override init() {
        super.init()
        guard Self.shared == nil else {
            fatalError()
        }
        Self.shared = self
    }

    func keyWindowController() -> LookupWindowController? {
        NSApp.keyWindow?.windowController as? LookupWindowController
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        registerDefaults()

        #if DEBUG
        startListeningToUserDefaults()
        #endif

        if NSApp.windows.isEmpty {
            newWindow(self)
        }

        observation = NotificationCenter.default.addObserver(forName: NSWindow.didBecomeKeyNotification,
                                               object: nil,
                                               queue: nil) { [weak self] notification in
            self?.updateDirectionItemsState()
        }

        NSApp.servicesProvider = ServiceProvider()
    }

    func updateDirectionItemsState() {
        latinToEnglishItem.state = direction == .latinToEnglish ? .on  : .off
        englishToLatinItem.state = direction == .englishToLatin ? .on :  .off
    }

    #if DEBUG
    private func startListeningToUserDefaults() {
        NSUserDefaultsController.shared.addObserver(self, forKeyPath: "values.diagnosticMode", options: .new, context: nil)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == "values.diagnosticMode" else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        print("User defaults changed", UserDefaults.standard.dictionaryRepresentation())
    }
    #endif

    private func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            "diagnosticMode": false,
            "history": [],
            "resultDisplayMode": ResultDisplayMode.raw.rawValue
        ])
    }

    @objc
    var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    @IBAction
    func newWindow(_ sender: Any?) {
        let newWindow = LookupWindowController.newWindow()

        if let keyWindow = NSApp.keyWindow {
            let newPoint = newWindow.cascadeTopLeft(from: keyWindow.topLeft)
            newWindow.setFrameTopLeftPoint(newPoint)
        } else {
            newWindow.center()
        }

        newWindow.makeKeyAndOrderFront(sender)
    }

    func application(_ application: NSApplication, willContinueUserActivityWithType userActivityType: String) -> Bool {
        print(userActivityType)
        return false
    }

    @available(macOS 12.0, *)
    func application(_ application: NSApplication, handlerFor intent: INIntent) -> Any? {
        switch intent {
        case is LookUpIntent: return LookUpIntentHandler()
        default: return nil
        }
    }

    /// - note: only "iwords:feedback" is valid, not "iwords://feedback"
    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }

        switch URLComponents(url: url, resolvingAgainstBaseURL: false)?.path {
        case "feedback":
            sendFeedback(application)
        case "help":
            openHelp()
        default:
            return
        }
    }

    fileprivate func showFeedbackErrorModal() {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = "Unable to compose an email automatically. Please send an email to support@danielweiner.org with your feedback."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func openHelp() {
        NSApp.showHelp(nil)
    }

    @IBAction
    private func sendFeedback(_ sender: Any?) {
        guard let service = NSSharingService(named: .composeEmail) else {
            showFeedbackErrorModal()
            return
        }
        service.recipients = ["support@danielweiner.org"]
        service.subject = "Feedback for iWords"
        let message = """


            ---- Version information ----
            iWords: Version \(Bundle.main.infoDictionary?["CFBundleVersion"] ?? "Unknown")
            macOS: \(ProcessInfo.processInfo.operatingSystemVersionString)
            """
        guard service.canPerform(withItems: [message]) else {
            showFeedbackErrorModal()
            return
        }
        service.perform(withItems: [message])
    }
}

extension NSWindow {
    var topLeft: NSPoint {
        convertPoint(toScreen: NSPoint(x: 0, y: frame.height))
    }
}

extension AppDelegate: HistoryDelegate {
    func historyController(_ historyController: HistoryController,
                           didSelectHistoryItem query: SearchQuery) {
        keyWindowController()?.setSearchQuery(query)
    }
}
