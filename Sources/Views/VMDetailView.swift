import SwiftUI

public struct VMDetailView: View {
    public let vm: VMConfiguration
    @ObservedObject public var engine: VirtualMachineEngine
    @ObservedObject public var vmService: VMService

    @State private var selectedTab: DetailTab = .console

    public enum DetailTab: String, CaseIterable, Identifiable {
        case console = "Display"
        case hardware = "Hardware"
        case storage = "Storage & Shares"

        public var id: String { rawValue }
    }

    public init(vm: VMConfiguration, engine: VirtualMachineEngine, vmService: VMService) {
        self.vm = vm
        self.engine = engine
        self.vmService = vmService
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 10) {
                        Text(vm.name)
                            .font(.title2.bold())

                        StatusBadgeView(state: engine.state)
                    }

                    Text("\(vm.osType.rawValue) • \(vm.cpuCount) vCPUs • \(Formatters.formatMegabytes(vm.memorySizeMB)) RAM")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Action Controls Toolbar
                HStack(spacing: 8) {
                    if engine.state.canStart {
                        Button(action: {
                            engine.start { _ in }
                        }) {
                            Label("Start", systemImage: "play.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }

                    if engine.state.canPause {
                        Button(action: {
                            engine.pause { _ in }
                        }) {
                            Label("Pause", systemImage: "pause.fill")
                        }
                        .buttonStyle(.bordered)
                    }

                    if engine.state.canResume {
                        Button(action: {
                            engine.resume { _ in }
                        }) {
                            Label("Resume", systemImage: "play.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                    }

                    if engine.state.canStop {
                        Menu {
                            Button("Graceful Shutdown") {
                                engine.requestStop { _ in }
                            }
                            Button("Force Stop", role: .destructive) {
                                engine.forceStop { _ in }
                            }
                        } label: {
                            Label("Stop", systemImage: "power")
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }

                    Button(action: {
                        vmService.isShowingSettingsSheet = true
                    }) {
                        Image(systemName: "gearshape")
                    }
                    .buttonStyle(.bordered)
                    .help("VM Settings")
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            // View Selector Tabs
            Picker("", selection: $selectedTab) {
                ForEach(DetailTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)

            // Content Area
            Group {
                switch selectedTab {
                case .console:
                    VMConsoleView(engine: engine)
                        .padding(16)

                case .hardware:
                    ScrollView {
                        VStack(spacing: 16) {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                let cpuPercentage = Double(vm.cpuCount) / Double(SystemInfo.hostCpuCores)
                                GaugeProgressView(
                                    title: "vCPU Cores",
                                    valueString: "\(vm.cpuCount) of \(SystemInfo.hostCpuCores) cores",
                                    percentage: cpuPercentage,
                                    icon: "cpu",
                                    tintColor: .blue
                                )

                                let hostRamMB = Double(SystemInfo.totalHostMemoryMB)
                                let ramPercentage = hostRamMB > 0 ? Double(vm.memorySizeMB) / hostRamMB : 0.25
                                GaugeProgressView(
                                    title: "Memory Allocation",
                                    valueString: "\(Formatters.formatMegabytes(vm.memorySizeMB)) / \(String(format: "%.0f", SystemInfo.totalHostMemoryGB)) GB",
                                    percentage: ramPercentage,
                                    icon: "memorychip",
                                    tintColor: .purple
                                )
                            }

                            GlassmorphicCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Display & Architecture Specs")
                                        .font(.headline)

                                    DetailRow(title: "Resolution", value: "\(vm.displayWidth) × \(vm.displayHeight) @ \(vm.displayDPI) DPI")
                                    DetailRow(title: "Display Adapter", value: "VirtIO GPU Accelerator")
                                    DetailRow(title: "Audio Controller", value: "VirtIO Sound Device (Host Output)")
                                    DetailRow(title: "Rosetta 2 Translation", value: vm.enableRosetta ? "Enabled (x86_64 binary compatibility)" : "Disabled")
                                    DetailRow(title: "Created On", value: Formatters.formatDate(vm.createdAt))
                                }
                            }
                        }
                        .padding(20)
                    }

                case .storage:
                    ScrollView {
                        VStack(spacing: 16) {
                            GlassmorphicCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Virtual Disk")
                                        .font(.headline)

                                    DetailRow(title: "Format", value: "Raw Sparse Image (.img)")
                                    DetailRow(title: "Capacity", value: Formatters.formatBytes(vm.diskSizeBytes))
                                    DetailRow(title: "File Path", value: vm.diskImagePath)
                                }
                            }

                            GlassmorphicCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Installation Media & Shared Folders")
                                        .font(.headline)

                                    DetailRow(title: "Boot ISO", value: vm.isoPath ?? "None (Direct Disk Boot)")
                                    DetailRow(title: "Shared Folder", value: vm.sharedFolderPath ?? "Disabled")
                                    DetailRow(title: "Filesystem Driver", value: "VirtioFS (High Speed Shared Filesystem)")
                                }
                            }
                        }
                        .padding(20)
                    }
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
    }
}

public struct DetailRow: View {
    public let title: String
    public let value: String

    public init(title: String, value: String) {
        self.title = title
        self.value = value
    }

    public var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .font(.system(size: 13))
    }
}
