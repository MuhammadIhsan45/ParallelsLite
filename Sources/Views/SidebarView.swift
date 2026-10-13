import SwiftUI

public struct SidebarView: View {
    @ObservedObject public var vmService: VMService
    @State private var searchText: String = ""

    public init(vmService: VMService) {
        self.vmService = vmService
    }

    private var filteredVMs: [VMConfiguration] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return vmService.vms
        }
        return vmService.vms.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.osType.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    public var body: some View {
        List(selection: $vmService.selectedVMId) {
            Section(header: Text("Virtual Machines").font(.caption.bold())) {
                ForEach(filteredVMs) { vm in
                    let engine = vmService.engine(for: vm.id)
                    VMRowView(vm: vm, engine: engine)
                        .tag(vm.id)
                        .contextMenu {
                            Button("Start") {
                                engine.start { _ in }
                            }
                            .disabled(!engine.state.canStart)

                            Button("Pause") {
                                engine.pause { _ in }
                            }
                            .disabled(!engine.state.canPause)

                            Button("Resume") {
                                engine.resume { _ in }
                            }
                            .disabled(!engine.state.canResume)

                            Button("Stop") {
                                engine.requestStop { _ in }
                            }
                            .disabled(!engine.state.canStop)

                            Divider()

                            Button("Settings...") {
                                vmService.selectedVMId = vm.id
                                vmService.isShowingSettingsSheet = true
                            }

                            Button(role: .destructive) {
                                vmService.deleteVM(id: vm.id)
                            } label: {
                                Text("Delete Machine")
                            }
                        }
                }
            }
        }
        .listStyle(.sidebar)
        .searchable(text: $searchText, placement: .sidebar, prompt: "Search VMs...")
        .safeAreaInset(edge: .bottom) {
            Button(action: {
                vmService.isShowingCreateSheet = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accentColor)
                    Text("New Virtual Machine")
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .padding(10)
        }
        .navigationTitle("Parallels Lite")
    }
}

public struct VMRowView: View {
    public let vm: VMConfiguration
    @ObservedObject public var engine: VirtualMachineEngine

    public init(vm: VMConfiguration, engine: VirtualMachineEngine) {
        self.vm = vm
        self.engine = engine
    }

    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: vm.osType.systemSymbolName)
                .font(.system(size: 18))
                .foregroundColor(.accentColor)
                .frame(width: 28, height: 28)
                .background(Color.accentColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text(vm.name)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)

                Text(vm.osType.rawValue)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            StatusBadgeView(state: engine.state)
        }
        .padding(.vertical, 4)
    }
}
