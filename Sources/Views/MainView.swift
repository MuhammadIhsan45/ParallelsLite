import SwiftUI

public struct MainView: View {
    @StateObject private var vmService = VMService.shared

    public init() {}

    public var body: some View {
        NavigationSplitView {
            SidebarView(vmService: vmService)
                .frame(minWidth: 220, idealWidth: 260)
        } detail: {
            if let selectedVM = vmService.selectedVM {
                let engine = vmService.engine(for: selectedVM.id)
                VMDetailView(vm: selectedVM, engine: engine, vmService: vmService)
            } else {
                EmptySelectionView(vmService: vmService)
            }
        }
        .sheet(isPresented: $vmService.isShowingCreateSheet) {
            CreateVMView(vmService: vmService)
        }
        .sheet(isPresented: $vmService.isShowingSettingsSheet) {
            if let selectedVM = vmService.selectedVM {
                SettingsView(vmService: vmService, vm: selectedVM)
            }
        }
    }
}

public struct EmptySelectionView: View {
    @ObservedObject public var vmService: VMService

    public var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "display.2")
                .font(.system(size: 64))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No Virtual Machine Selected")
                .font(.title2.bold())

            Text("Select a virtual machine from the sidebar or create a new one.")
                .foregroundColor(.secondary)
                .font(.subheadline)

            Button(action: {
                vmService.isShowingCreateSheet = true
            }) {
                Label("Create New Virtual Machine", systemImage: "plus")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
