# ParallelsLite — Native macOS Virtual Machine Hypervisor

A lightweight, high-performance, native Virtual Machine manager for macOS built with **Swift**, **SwiftUI**, and Apple's **`Virtualization.framework`**. Designed with a zero-crash architecture, strict state machines, and modern macOS aesthetics.

---

## Fitur Utama (Key Features)

1. **Native Hypervisor Acceleration**:
   - Memanfaatkan Apple `Virtualization.framework` (Type-2 native hypervisor di Apple Silicon & Intel Mac).
   - Akselerasi grafis hardware dengan VirtIO GPU Scanout.
   - Performa CPU guest mendekati 1:1 kecepatan bare-metal Mac.

2. **Zero-Crash Architecture**:
   - Menghindari force unwrapping (`!`) secara total.
   - Validasi parameter pra-boot (vCPU, alokasi RAM, integritas sparse disk).
   - Thread-safe state machine: `stopped`, `starting`, `running`, `paused`, `stopping`, `error`.
   - Penanganan error runtime hypervisor secara elegan tanpa membuat aplikasi keluar (*crash*).

3. **Dukungan Guest OS Lengkap**:
   - **Linux Distributions**: Ubuntu, Debian, Fedora, Arch Linux, Alpine.
   - **Windows 11 ARM**: Menggunakan UEFI bootloader (`VZEFIBootLoader`).
   - **macOS Guest**: Mendukung virtualisasi macOS di atas Apple Silicon.
   - **Apple Rosetta 2**: Dukungan eksekusi biner x86_64 di dalam Linux guest (Apple Silicon).

4. **Integrasi Perangkat Keras Modern**:
   - **VirtIO Networking**: NAT otomatis dengan akses internet instan dari host Mac.
   - **VirtioFS Shared Folders**: Sinkronisasi folder antara macOS host dan Guest OS dengan kecepatan tinggi.
   - **Live Display Console**: Menggunakan `VZVirtualMachineView` untuk interaksi keyboard & kursor mouse secara presisi.
   - **Sparse Disk Engine**: Alokasi disk virtual cerdas yang hanya memakai kapasitas SSD saat data ditulis.

---

## Struktur Folder Project

```
Pararells/
├── Package.swift                    # Definisi Swift Package Manager (macOS 13.0+)
├── VirtualizationApp.entitlements    # Entitlement com.apple.security.virtualization
├── README.md                        # Dokumentasi penggunaan & arsitektur
├── Scripts/
│   └── build.sh                     # Script otomatis build .app bundle & codesign
└── Sources/
    ├── ParallelsLiteApp.swift       # Entry point @main SwiftUI dengan menu bar & shortcut
    ├── Models/
    │   ├── VMState.swift            # State machine siklus hidup VM
    │   ├── VMConfiguration.swift    # Schema konfigurasi & validator input
    │   └── OSTemplate.swift         # Preset & template sistem operasi
    ├── Services/
    │   ├── VMService.swift          # Koordinator VM, persistensi JSON, CRUD
    │   ├── VirtualMachineEngine.swift # Driver Apple Virtualization.framework
    │   └── DiskManager.swift        # Manajer sparse disk image & file storage
    ├── Views/
    │   ├── MainView.swift           # Root NavigationSplitView
    │   ├── SidebarView.swift        # Daftar VM, filter pencarian, & badge status
    │   ├── VMDetailView.swift       # Dashboard kontrol, toolbar, & monitoring
    │   ├── VMConsoleView.swift      # Render layar grafis VZVirtualMachineView
    │   ├── CreateVMView.swift       # Wizard pembuatan VM baru
    │   ├── SettingsView.swift       # Modal konfigurasi hardware VM
    │   └── Components/
    │       ├── StatusBadgeView.swift
    │       ├── GaugeProgressView.swift
    │       └── GlassmorphicCard.swift
    └── Utils/
        ├── SystemInfo.swift         # Deteksi core CPU host & kapasitas RAM
        └── Formatters.swift         # Formatting ukuran bytes, tanggal, & string
```

---

## Persyaratan Sistem (System Requirements)

- **macOS**: macOS 13.0 (Ventura), macOS 14 (Sonoma), atau macOS 15 (Sequoia) atau lebih baru.
- **Hardware**: Mac dengan prosesor Apple Silicon (M1/M2/M3/M4) atau Intel Core Mac.
- **Tools**: Xcode 15+ atau Command Line Tools (`swift --version` >= 5.9).

---

## Cara Menjalankan & Membangun (How to Build & Run)

### Opsi 1: Menggunakan Xcode (Direkomendasikan)
1. Buka Terminal di folder project:
   ```bash
   xed .
   # atau double-click Package.swift
   ```
2. Di Xcode, pilih skema target **ParallelsLite** > **My Mac**.
3. Pastikan **Signing & Capabilities** memiliki file entitlements [VirtualizationApp.entitlements](file:///d:/FIle%20Project%20Mandiri%20Ihsan/Pararells/VirtualizationApp.entitlements) yang menyertakan entitlement `com.apple.security.virtualization`.
4. Tekan **Cmd + R** untuk menjalankan aplikasi.

### Opsi 2: Menggunakan Terminal / Command Line
1. Berikan izin eksekusi pada script build:
   ```bash
   chmod +x Scripts/build.sh
   ```
2. Jalankan build:
   ```bash
   ./Scripts/build.sh
   ```
3. Buka aplikasi bundle yang dihasilkan:
   ```bash
   open ParallelsLite.app
   ```

---

## Keyboard Shortcuts

| Shortcut | Aksi |
|---|---|
| `Cmd + N` | Buat Virtual Machine Baru |
| `Cmd + R` | Start / Jalankan VM yang dipilih |
| `Cmd + .` | Stop / Matikan VM |
| `Cmd + ,` | Buka Pengaturan VM (Settings) |

---

## Lisensi & Catatan Keamanan
- Proyek ini menggunakan API publik native resmi Apple (`Virtualization.framework`).
- Tidak menggunakan kode bajakan atau modifikasi ilegal dari proprietary Parallels Desktop milik Alludo.
