# Setting Oracle Cloud (cloud.oracle.com) untuk VM Android / Rofwin

> Panduan pengaturan instance Oracle VM (`webvirtcloud.ai.studio`, OCI ap-singapore-1) agar siap menjalankan beban bergaya *Android/Windows guest* ala proyek **Rofwin** (source: `ivansslo/Rofwin`, fork Winlator), beserta penjelasan arsitektur yang jujur.

---

## 1) Fakta arsitektur (dibaca dulu)

| Topik | Kenyataan | Implikasi |
|---|---|---|
| Shape VM | `VM.Standard.A1` Ampere **ARM64** (aarch64) | Cocok untuk software ARM64 (Antigravity, proot Ubuntu, box64/fex) |
| Nested KVM | **tidak tersedia** di tipe VM — hanya *Bare Metal* shape yang mengekspos `/dev/kvm` | WebVirtCloud berjalan, tetapi guest KVM sesungguhnya tidak bisa; hanya TCG (emulasi, lambat) |
| Rofwin | emulator Windows **untuk perangkat Android** (Oppo CPH1823), bukan guest OS | Tidak diinstal sebagai OS; yang masuk akal di server: *runtime serupa* (Ubuntu proot + box64/fex + wine) di VM, di-stream lewat noVNC/RDP |
| Jaringan | IP publik `161.118.253.28` + tailnet `100.93.139.73` | Akses ganda; layanan sensitif sebaiknya lewat tunnel |

**Kesimpulan desain:** jangan mengejar "Android guest VM" di instance ini. Jalankan **runtime Winlator-like di dalam proot/container ARM64** dan expose tampilannya — pola yang sama dengan Antigravity (`antigravity.ai.studio`).

---

## 2) Setting di OCI Console (cloud.oracle.com)

### A. Networking → Security List (ingress rules wajib)
| Port TCP | Layanan | Catatan |
|---|---|---|
| 22 | SSH | admin (`roc-access ssh`) |
| 80 / 443 | nginx bridge (WVC, Kuma, Monitor, health) | sudah ada |
| 5905 | Antigravity web (opsional; lebih aman via tunnel) | bisa dibatasi tailnet |
| 6905 | noVNC Antigravity/Rofwin-style runtime | buka hanya bila tanpa tunnel; `https://novnc.roadfx.biz.id` tidak butuh port ini terbuka |
| 3389 | RDP (xrdp) | **opsional** — prefer `roc-access rdp fwd` |
| 6080 | noVNC WebVirtCloud (internal `/vm/novnc/`) | sudah termapping nginx |

### B. Oracle Cloud Agent → plugins (aktifkan)
- **Compute Instance Run Command** — *wajib* (ini jalur resmi pemasangan key & automation tanpa SSH).
- **Compute Instance Monitoring** — metrik dasar.
- (Opsional) **OS Management Hub** — patch.

### C. Jalur otomasi resmi: Run Command
Untuk semua "setting" tanpa SSH (contoh: memasang `authorized_keys`):
`Instance → Oracle Cloud Agent → Run command → Paste a script → Run` → status **Succeeded**.

### D. Zona waktu & chrony — sudah default pada image Ubuntu OCI.

---

## 3) Blueprint runtime Rofwin-style di VM (rekomendasi)

```
Oracle VM (aarch64)
└── proot / udocker: Ubuntu 24.04 arm64
    ├── box64 / fex-emu        → translasi x86_64 → arm64
    ├── wine(+dxvk/virgl)      → runtime Windows
    └── Xvfb + x11vnc + noVNC  → display :99, web :6905
         └── Cloudflare Tunnel → https://novnc.roadfx.biz.id
```

Semua komponen pengelolaan sudah tersedia di ekosistem ROC:

| Kebutuhan | Command |
|---|---|
| Masuk VM | `roc-access ssh` |
| Expose tampilan web | `roc-tunnel oracle-install → oracle-login → oracle-create → oracle-up` |
| SSH lewat Cloudflare (opsional) | hostname `sshvm.roadfx.biz.id` (bsd dari config tunnel VM; client: `cloudflared access ssh --hostname sshvm.roadfx.biz.id`) |
| Status semua | `roc-access status` + `roc-tunnel oracle-status` |

> Skrip instalasi Antigravity di VM (`vm/antigravity-vm-install.sh`) adalah contoh konkret pola yang sama (Xvfb→IDE→x11vnc→noVNC→systemd) — runtime Rofwin-style tinggal mengikuti cetakan itu.

---

## 4) Yang sengaja TIDAK dilakukan (keputusan jujur)

- ❌ Install Android-x86/Bliss OS sebagai guest KVM — tidak mungkin (tanpa `/dev/kvm`).
- ❌ Rofwin APK "dijalankan di VM" — target Rofwin tetap **perangkat Android** (build & rilisnya ada di repo `ivansslo/Rofwin` tag `v1.0.1`).
- ❌ Membuka 3389/6905 telanjang ke internet — selalu prefer tunnel (`roc-tunnel oracle-*`) atau SSH forward (`roc-access … fwd`).

---

## 5) Checklist cepat

- [ ] Security List sesuai tabel A
- [ ] Plugin Run Command = Running
- [ ] authorized_keys terpasang (sekali, via Run Command)
- [ ] `roc-access setup` di Termux → `roc-access ssh` hijau
- [ ] Antigravity @ VM: `vm/antigravity-vm-install.sh` → noVNC :6905
- [ ] Tunnel VM: `roc-tunnel oracle-*` → `https://novnc.roadfx.biz.id` 🟢
- [ ] (Tahap berikut) proot Ubuntu + box64/FEX + wine → runtime "Rofwin-style" headless
