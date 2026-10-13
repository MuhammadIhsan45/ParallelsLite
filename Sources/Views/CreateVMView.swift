import SwiftUI
import AppKit

public struct CreateVMView: View {
    @ObservedObject public var vmService: VMService
    @Environment(\.dismiss) private var dismiss

    @State private var selectedOS: OSType = .ubuntu
    @State private var name: String = "Ubuntu 24.04 LTS"
    @State private var cpuCount: Int = 4
    @State private var memoryGB: Double = 4.0
    @State private var diskGB: Double = 25.0
    @State private var isoPath: String = ""
    @State private var sharedFolderPath: String = ""
    @State private var enableRosetta: Bool = true
    @State private var errorMessage: String? = nil
    @State private var isCreating: Bool = false

    public init(vmService: VMService) {
        self.vmService = vmService
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Create Virtual Machine")
                        .font(.title2.bold())
                    Text("Powered by Apple Virtualization.framework")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding(20)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // OS Preset Selection
                    VStack(alignment: .leading, spacing: 10) {
                        Text("1. Select Operating System")
                            .font(.headline)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(OSType.allCases) { os in
                                Button(action: {
                                    selectedOS = os
                                    name = "\(os.rawValue)"
                                    cpuCount = os.defaultCpuCount
                                    memoryGB = Double(os.defaultMemoryMB) / 1024.0
                                    diskGB = Double(os.defaultDiskGB)
                                }) {
                                    HStack(spacing: 10) {
                                        Image(systemName: os.systemSymbolName)
                                            .font(.title3)
                                            .foregroundColor(selectedOS == os ? .white : .accentColor)
                                        Text(os.rawValue)
                                            .fontWeight(.medium)
                                            .foregroundColor(selectedOS == os ? .white : .primary)
                                        Spacer()
                                    }
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedOS == os ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Divider()

                    // VM Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("2. Machine Name")
                            .font(.headline)

                        TextField("Virtual Machine Name", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }

                    Divider()

                    // Hardware Resources
                    VStack(alignment: .leading, spacing: 16) {
                        Text("3. Hardware Allocation")
                            .font(.headline)

                        // CPU Cores Slider
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("vCPU Cores:")
                                Spacer()
                                Text("\(cpuCount) cores")
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

                        // RAM Slider
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Memory (RAM):")
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

                        // Disk Size Slider
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Virtual Disk Size:")
                                Spacer()
                                Text("\(Int(diskGB)) GB")
                                    .fontWeight(.bold)
                            }
                            Slider(value: $diskGB, in: 10...200, step: 5)
                        }
                    }

                    Divider()

                    // Installation Media & Shares
                    VStack(alignment: .leading, spacing: 12) {
                        Text("4. Media & Shared Folder")
                            .font(.headline)

                        // ISO Path
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Bootable Installer ISO (Optional):")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            HStack {
                                TextField("Path to .iso file", text: $isoPath)
                                    .textFieldStyle(.roundedBorder)
                                Button("Browse...") {
                                    chooseFile(allowedExtensions: ["iso", "img"]) { path in
                                        isoPath = path
                                    }
                                }
                            }
                        }

                        // Shared Folder Path
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Host Shared Directory (VirtioFS):")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            HStack {
                                TextField("Host folder to share", text: $sharedFolderPath)
                                    .textFieldStyle(.roundedBorder)
                                Button("Browse...") {
                                    chooseFolder { path in
                                        sharedFolderPath = path
                                    }
                                }
                            }
                        }

                        // Rosetta 2 compatibility
                        Toggle("Enable Apple Rosetta 2 x86_64 translation in Linux guest", isOn: $enableRosetta)
                            .toggleStyle(.checkbox)
                            .font(.system(size: 13))
                    }

                    if let error = errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
                .padding(20)
            }

            Divider()

            // Footer / Actions
            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }

                Button(action: createVirtualMachine) {
                    if isCreating {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text("Create & Finish")
                            .fontWeight(.semibold)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isCreating || name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(16)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(minWidth: 540, minHeight: 620)
    }

    private func createVirtualMachine() {
        isCreating = true
        errorMessage = nil

        let memMB = UInt64(memoryGB * 1024)
        let disk = UInt64(diskGB)

        let result = vmService.createVM(
            name: name,
            osType: selectedOS,
            cpuCount: cpuCount,
            memoryMB: memMB,
            diskGB: disk,
            isoPath: isoPath.isEmpty ? nil : isoPath,
            sharedFolderPath: sharedFolderPath.isEmpty ? nil : sharedFolderPath,
            enableRosetta: enableRosetta
        )

        isCreating = false

        switch result {
        case .success:
            dismiss()
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private func chooseFile(allowedExtensions: [String], completion: @escaping (String) -> Void) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            completion(url.path)
        }
    }

    private func chooseFolder(completion: @escaping (String) -> Void) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            completion(url.path)
        }
    }
}
