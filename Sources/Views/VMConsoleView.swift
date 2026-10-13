import SwiftUI
import AppKit
#if canImport(Virtualization)
import Virtualization
#endif

/// Renders the real-time virtual machine graphics screen with mouse and keyboard input capture.
public struct VMConsoleView: View {
    @ObservedObject public var engine: VirtualMachineEngine

    public init(engine: VirtualMachineEngine) {
        self.engine = engine
    }

    public var body: some View {
        ZStack {
            Color.black

            switch engine.state {
            case .running, .paused:
                #if canImport(Virtualization)
                if let rawVM = engine.rawVirtualMachine {
                    NativeVZViewWrapper(virtualMachine: rawVM)
                        .edgesIgnoringSafeArea(.all)
                } else {
                    SimulationConsoleView(engine: engine)
                }
                #else
                SimulationConsoleView(engine: engine)
                #endif

            case .starting:
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Booting virtual machine...")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                    Text("Initializing virtual CPU, RAM, and VirtIO graphics")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }

            case .stopping:
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Shutting down guest OS...")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                }

            case .stopped:
                VStack(spacing: 16) {
                    Image(systemName: "power.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.3))
                    Text("Virtual Machine is Powered Off")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.6))
                    Button(action: {
                        engine.start { _ in }
                    }) {
                        Label("Start Machine", systemImage: "play.fill")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }

            case .error(let message):
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.red)
                    Text("Hypervisor Error")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Button("Try Again") {
                        engine.start { _ in }
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .frame(minWidth: 480, minHeight: 320)
        .cornerRadius(8)
    }
}

#if canImport(Virtualization)
/// NSViewRepresentable wrapping Apple's native VZVirtualMachineView
public struct NativeVZViewWrapper: NSViewRepresentable {
    public let virtualMachine: VZVirtualMachine

    public init(virtualMachine: VZVirtualMachine) {
        self.virtualMachine = virtualMachine
    }

    public func makeNSView(context: Context) -> VZVirtualMachineView {
        let view = VZVirtualMachineView()
        view.virtualMachine = virtualMachine
        view.capturesSystemKeys = true
        return view
    }

    public func updateNSView(_ nsView: VZVirtualMachineView, context: Context) {
        if nsView.virtualMachine !== virtualMachine {
            nsView.virtualMachine = virtualMachine
        }
    }
}
#endif

/// Fallback preview console displaying simulated TTY output
public struct SimulationConsoleView: View {
    @ObservedObject public var engine: VirtualMachineEngine

    public init(engine: VirtualMachineEngine) {
        self.engine = engine
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle().fill(Color.red).frame(width: 10, height: 10)
                Circle().fill(Color.yellow).frame(width: 10, height: 10)
                Circle().fill(Color.green).frame(width: 10, height: 10)
                Spacer()
                Text("\(engine.config.name) — Console")
                    .font(.caption.monospaced())
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
            }
            .padding(.bottom, 8)

            Group {
                Text("[ OK ] Started Hypervisor Virtualization.framework").foregroundColor(.green)
                Text("[ OK ] Configured \(engine.config.cpuCount) vCPUs, \(Formatters.formatMegabytes(engine.config.memorySizeMB)) RAM").foregroundColor(.white.opacity(0.9))
                Text("[ OK ] VirtIO block device mounted: \(engine.config.diskImagePath)").foregroundColor(.white.opacity(0.8))
                if let iso = engine.config.isoPath, !iso.isEmpty {
                    Text("[ OK ] Boot ISO mounted: \(iso)").foregroundColor(.cyan)
                }
                Text("[ OK ] VirtIO network adapter attached (NAT mode)").foregroundColor(.white.opacity(0.8))
                if engine.config.enableRosetta {
                    Text("[ OK ] Apple Rosetta 2 x86_64 translation layer active").foregroundColor(.yellow)
                }
                Text("[ OK ] EFI stub: Booting Guest Kernel...").foregroundColor(.white.opacity(0.8))
                Text("login: _").foregroundColor(.green)
            }
            .font(.system(size: 12, design: .monospaced))

            Spacer()
        }
        .padding(16)
        .background(Color.black.opacity(0.95))
    }
}
