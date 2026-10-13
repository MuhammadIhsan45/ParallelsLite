import SwiftUI
import AppKit

public struct SettingsView: View {
    @ObservedObject public var vmService: VMService
    public let vm: VMConfiguration
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var cpuCount: Int
    @State private var memoryGB: Double
    @State private var isoPath: String
    @State private var sharedFolderPath: String
    @State private var enableRosetta: Bool
    @State private var errorMessage: String? = nil

    public init(vmService: VMService, vm: VMConfiguration) {
        self.vmService = vmService
        self.vm = vm
        _name = State(initialValue: vm.name)
        _cpuCount = State(initialValue: vm.cpuCount)
        _memoryGB = State(initialValue: Double(vm.memorySizeMB) / 1024.0)
        _isoPath = State(initialValue: vm.isoPath ?? "")
        _sharedFolderPath = State(initialValue: vm.sharedFolderPath ?? "")
        _enableRosetta = State(initialValue: vm.enableRosetta)
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(vm.name) — Settings")
                        .font(.title3.bold())
                    Text("Modify virtual machine hardware allocations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding(16)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Machine Name
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Machine Name")
                            .font(.subheadline.bold())
                        TextField("Name", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }

                    Divider()

                    // CPU
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("vCPU Cores:")
                            Spacer()
                            Text("\(cpuCount) Cores")
                                .fontWeight(.bold)
                        }
                        Slider(
                            value: Binding(
                                get: { Double(cpuCount) },
                                set: { cpuCount = Int($0) }
                            ),
                            in: 1...Double(max(1, SystemInfo.hostCpuCores)),
                            step: 1
                        )
                    }

                    // RAM
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("RAM (Memory):")
                            Spacer()
                            Text("\(String(format: "%.1f", memoryGB)) GB")
                                .fontWeight(.bold)
                        }
                        Slider(
                            value: $memoryGB,
                            in: 1.0...Double(max(2, Int(SystemInfo.totalHostMemoryGB))),
                            step: 0.5
                        )
                    }

                    Divider()

                    // ISO Path
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Installer ISO Image:")
                            .font(.subheadline.bold())
                        HStack {
                            TextField("Path to .iso", text: $isoPath)
                                .textFieldStyle(.roundedBorder)
                            Button("Browse...") {
                                chooseFile(allowedExtensions: ["iso", "img"]) { path in
                                    isoPath = path
                                }
                            }
                            if !isoPath.isEmpty {
                                Button("Eject") {
                                    isoPath = ""
                                }
                            }
                        }
                    }

                    // Shared Folder
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Shared Folder (VirtioFS):")
                            .font(.subheadline.bold())
                        HStack {
                            TextField("Path to directory", text: $sharedFolderPath)
                                .textFieldStyle(.roundedBorder)
                            Button("Browse...") {
                                chooseFolder { path in
                                    sharedFolderPath = path
                                }
                            }
                            if !sharedFolderPath.isEmpty {
                                Button("Clear") {
                                    sharedFolderPath = ""
                                }
                            }
                        }
                    }

                    Toggle("Enable Rosetta 2 inside guest", isOn: $enableRosetta)
                        .toggleStyle(.checkbox)

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(20)
            }

            Divider()

            // Actions
            HStack {
                Spacer()
                Button("Save Changes") {
                    saveSettings()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(14)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(minWidth: 480, minHeight: 520)
    }

    private func saveSettings() {
        var updated = vm
        updated.name = name
        updated.cpuCount = cpuCount
        updated.memorySizeMB = UInt64(memoryGB * 1024)
        updated.isoPath = isoPath.isEmpty ? nil : isoPath
        updated.sharedFolderPath = sharedFolderPath.isEmpty ? nil : sharedFolderPath
        updated.enableRosetta = enableRosetta

        if case .failure(let err) = updated.validate() {
            errorMessage = err.localizedDescription
            return
        }

        vmService.updateVM(updated)
        dismiss()
    }

    private func chooseFile(allowedExtensions: [String], completion: @escaping (String) -> Void) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            completion(url.path)
        }
    }

    private func chooseFolder(completion: @escaping (String) -> Void) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        if panel.runModal() == .OK, let url = panel.url {
            completion(url.path)
        }
    }
}
