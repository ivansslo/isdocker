# Tailscale (container node) · roc-containers

Menjalankan **Tailscale sebagai node mandiri di dalam container udocker**
(Ubuntu 22.04, `userspace-networking`). Ini mengatasi kegagalan Tailscale di
**Termux host** yang membutuhkan TUN/permission Android.

---

## 📦 Cara Install

Tidak ada langkah manual — instalasi **otomatis** saat pertama dijalankan.

1. Jalankan menu roc-containers:
   ```bash
   bash ~/.roc-containers/menu.sh
   ```
2. Pilih **[06] CLI Command → [2] Tailscale (container node)**.
3. Pada run pertama, container akan:
   - pull image `ubuntu:22.04` (via udocker),
   - menambah repo resmi Tailscale (`pkgs.tailscale.com`),
   - `apt-get install tailscale`,
   - menjalankan `tailscaled --tun=userspace-networking`.

State login disimpan di `data-tailscale-node/state` sehingga **bertahan
antar-run** (tidak perlu login ulang).

> Menjalankan langsung tanpa menu:
> ```bash
> bash ~/.roc-containers/apps/tailscale/tailscale.sh
> ```

---

## 🚀 Cara Penggunaan

### 1) Login

- **Auth Key** — menu **[1]**. Buat key di
  <https://login.tailscale.com/admin/settings/keys> (format `tskey-auth-...`),
  tempel saat diminta. Cocok untuk otomatis/headless.
- **Browser** — menu **[2]**. Container mencetak URL; buka di browser HP untuk
  otorisasi.

Cek koneksi: menu **[3] Status**, IP: menu **[4]**.

### 2) Exit Node (routing semua trafik lewat node ini)

Menu **[7] Jadikan Exit Node**. Script akan:
- mengaktifkan IP forwarding (best-effort),
- menjalankan `tailscale set --advertise-exit-node`.

**Wajib disetujui di admin console:**
<https://login.tailscale.com/admin/machines> → pilih node `roc-containers-node`
→ **Edit route settings** → centang **Use as exit node** → Save.

Lalu di perangkat lain (klien): pilih node ini sebagai exit node
(app Tailscale → Exit Node → `roc-containers-node`), atau CLI:
```bash
tailscale up --exit-node=<IP-atau-nama-node>
```

### 3) Advertise Routes (subnet router)

Menu **[8] Advertise Routes**. Masukkan CIDR subnet lokal, mis:
```
192.168.1.0/24
```
(boleh beberapa, pisah koma: `192.168.1.0/24,10.0.0.0/24`)

Script menjalankan `tailscale set --advertise-routes=<CIDR>`.

**Setujui di admin console** (sama seperti exit node): node `roc-containers-node`
→ Edit route settings → centang subnet → Save.

Klien yang ingin memakai subnet harus `--accept-routes` (roc-containers sudah
memakai flag ini saat `up`).

### 4) Reset

Menu **[9]** menghapus advertise exit-node & routes
(`--advertise-exit-node=false --advertise-routes=`).

### 5) Shell / Logout

- **[6] Shell** — masuk ke container untuk menjalankan perintah `tailscale`
  manual.
- **[5] Logout** — memutus & menghapus sesi login.

---

## ⚠️ Catatan & Batasan

- Mode **userspace-networking** dipakai karena udocker/proot tidak punya
  `/dev/net/tun`. Node tetap bisa online, menjadi exit node, dan subnet
  router, tetapi performa/fitur tingkat-kernel bisa berbeda dari instalasi
  Tailscale penuh.
- Exit node & subnet **tidak aktif** sampai **disetujui di admin console**.
- `sysctl` IP forwarding bersifat best-effort di dalam container; jika ditolak,
  Tailscale tetap meng-advertise (persetujuan admin yang menentukan).
- Hostname node default: `roc-containers-node` (ubah di variabel `HOSTNAME_TS`
  dalam `tailscale.sh` bila perlu).
