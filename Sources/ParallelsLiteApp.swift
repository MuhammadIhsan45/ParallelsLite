import SwiftUI

@main
public struct ParallelsLiteApp: App {
    public init() {}

    public var body: some Scene {
        WindowGroup {
            MainView()
                .frame(minWidth: 800, minHeight: 520)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Virtual Machine...") {
                    Task { @MainActor in
                        VMService.shared.isShowingCreateSheet = true
                    }
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            CommandMenu("Machine") {
                Button("Start Machine") {
                    Task { @MainActor in
                        if let selected = VMService.shared.selectedVM {
                            let engine = VMService.shared.engine(for: selected.id)
                            if engine.state.canStart {
                                engine.start { _ in }
                            }
                        }
                    }
                }
                .keyboardShortcut("r", modifiers: .command)

                Button("Pause Machine") {
                    Task { @MainActor in
                        if let selected = VMService.shared.selectedVM {
                            let engine = VMService.shared.engine(for: selected.id)
                            if engine.state.canPause {
                                engine.pause { _ in }
                            }
                        }
                    }
                }

                Button("Resume Machine") {
                    Task { @MainActor in
                        if let selected = VMService.shared.selectedVM {
                            let engine = VMService.shared.engine(for: selected.id)
                            if engine.state.canResume {
                                engine.resume { _ in }
                            }
                        }
                    }
                }

                Button("Stop Machine") {
                    Task { @MainActor in
                        if let selected = VMService.shared.selectedVM {
                            let engine = VMService.shared.engine(for: selected.id)
                            if engine.state.canStop {
                                engine.requestStop { _ in }
                            }
                        }
                    }
                }
                .keyboardShortcut(".", modifiers: .command)

                Divider()

                Button("Machine Settings...") {
                    Task { @MainActor in
                        VMService.shared.isShowingSettingsSheet = true
                    }
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}
