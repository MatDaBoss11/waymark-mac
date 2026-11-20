import ServiceManagement
import SwiftUI

@Observable @MainActor
final class Preferences {
    private let defaults: UserDefaults
    var didChangeIdle: (() -> Void)?
    var idleLimit: Double {
        didSet {
            defaults.set(idleLimit, forKey: "idleLimit")
            if idleLimit != oldValue { didChangeIdle?() }
        }
    }
    var loginStatus = SMAppService.mainApp.status
    var loginError: String?

    init(defaults: UserDefaults) {
        self.defaults = defaults
        let stored = defaults.double(forKey: "idleLimit")
        idleLimit = [90, 180, 300].contains(stored) ? stored : 180
    }

    func setLogin(_ enabled: Bool) {
        defer { loginStatus = SMAppService.mainApp.status }
        loginError = nil
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            loginError = error.localizedDescription
        }
    }
}

struct SettingsView: View {
    @Bindable var preferences: Preferences
    let preview: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center, spacing: 15) {
                Image(systemName: "signpost.right.fill")
                    .font(.system(size: 27, weight: .medium))
                    .foregroundStyle(Color(red: 0.14, green: 0.30, blue: 0.22))
                    .frame(width: 61, height: 61)
                    .background(Color(red: 0.86, green: 0.92, blue: 0.85), in: RoundedRectangle(cornerRadius: 17))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Waymark").font(.system(size: 32, weight: .regular, design: .serif))
                    Text("A moment to choose what you do next.")
                        .font(.system(size: 13)).foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                LabeledContent("Reset after no input for") {
                    Picker("Reset after no input for", selection: $preferences.idleLimit) {
                        Text("90 seconds").tag(90.0)
                        Text("3 minutes").tag(180.0)
                        Text("5 minutes").tag(300.0)
                    }
                    .labelsHidden()
                    .frame(width: 123)
                }
                Text("This applies when macOS has no sign that an app is keeping the display awake. Scrolling counts as input.")
                    .font(.system(size: 12)).foregroundStyle(.secondary)

                Divider().padding(.vertical, 2)

                Toggle("Open at login", isOn: Binding(
                    get: { preferences.loginStatus == .enabled || preferences.loginStatus == .requiresApproval },
                    set: { preferences.setLogin($0) }
                ))
                .toggleStyle(.switch)
                .controlSize(.small)

                if preferences.loginStatus == .requiresApproval {
                    Button("Review Login Items") { SMAppService.openSystemSettingsLoginItems() }
                }
                if let error = preferences.loginError {
                    Text(error).font(.system(size: 11)).foregroundStyle(.secondary)
                }
            }
            .padding(15)
            .background(.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 12))

            Button("Preview a check-in", action: preview)
        }
        .padding(25)
        .frame(width: 425, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }
}
