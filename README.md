# 📋 Work Hub — iOS Native App (`Personal Task & Knowledge Workspace v2.0`)

> **Work Hub iOS Native Wrapper**  
> Ứng dụng quản lý công việc (Kanban + Subtasks), ghi chú Markdown (Split-View), danh bạ, bookmarks và trợ lý AI cá nhân tại [https://work.buongloi.me](https://work.buongloi.me) — hỗ trợ cả **Light Mode & Dark Mode** theo phong cách **Linear / Raycast**.

---

## 📱 Thông Tin Ứng Dụng

| Hạng mục | Chi tiết |
|---|---|
| **Tên ứng dụng** | Work Hub |
| **Bundle Identifier** | `me.buongloi.workhub` |
| **Phiên bản** | `2.0.0` (Build `2`) |
| **Yêu cầu hệ điều hành** | iOS 16.0 trở lên (Tương thích iPhone & iPad, hỗ trợ xoay ngang/dọc) |
| **Máy chủ Web App** | `https://work.buongloi.me` (VPS port `8097`) |
| **Hình thức đóng gói** | Unsigned IPA (Cài đặt qua ESign / TrollStore / AltStore / Sideloadly) |

---

## ✨ Tính Năng Nổi Bật Trên iOS

- **Linear / Raycast UI (Light & Dark Mode)**: Giao diện thích ứng hoàn hảo cả ban ngày lẫn ban đêm, hỗ trợ bảng Kanban kéo thả, Subtasks checklist và trình soạn thảo Markdown.
- **Lưu trữ phiên đăng nhập bền vững**: Tương thích mượt mà với cả **Cloudflare Access** (`buongloi.cloudflareaccess.com`) và phiên đăng nhập nội bộ (`iron-session`) trong `WKWebsiteDataStore.default()`.
- **Haptic Feedback & Pull-to-Refresh**: Phản hồi rung xúc giác khi thao tác và kéo xuống để làm mới dữ liệu tức thì.
- **Mở liên kết thông minh**: Các Bookmark / liên kết ngoài (`target="_blank"`) tự động mở bằng Safari hệ thống, trong khi các luồng xác thực nội bộ giữ nguyên trong ứng dụng.

---

## 🚀 Cách Build File `.ipa` qua GitHub Actions

Dự án sử dụng **GitHub Actions** với runner `macos-14` + `Xcode 16` + `XcodeGen` để tự động biên dịch ra file `WorkHub.ipa`.

### 1. Tự động khi Push code:
```bash
git add .
git commit -m "feat: update WorkHub iOS v2.0"
git push origin main
```

### 2. Kích hoạt thủ công:
1. Truy cập mục **Actions**: [https://github.com/BuongLoi/work-hub-ios/actions](https://github.com/BuongLoi/work-hub-ios/actions)
2. Chọn workflow **`Build iOS (.ipa)`** ở cột trái.
3. Bấm **`Run workflow`** ➔ Chọn branch `main` ➔ Bấm **`Run workflow`**.

---

## 📥 Tải & Cài Đặt Lên iPhone Bằng ESign / TrollStore

1. Vào [https://github.com/BuongLoi/work-hub-ios/actions](https://github.com/BuongLoi/work-hub-ios/actions).
2. Chọn lượt chạy thành công mới nhất (dấu tích xanh ✅).
3. Cuộn xuống mục **Artifacts** ➔ Tải file **`WorkHub-ipa`** (dạng `.zip`).
4. Giải nén trong ứng dụng **Tệp (Files)** trên iPhone để lấy file **`WorkHub.ipa`**.
5. Mở **ESign** (hoặc **TrollStore** / **Sideloadly**) ➔ Nhập file `WorkHub.ipa` ➔ Ký chứng chỉ cá nhân và bấm **Cài đặt**.
