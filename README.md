# Script Tự Động Cài Đặt Squid Proxy Server

Script bash tự động cài đặt và cấu hình Squid Proxy Server trên Linux với các tùy chọn tùy chỉnh.

## 📋 Yêu Cầu

- Hệ điều hành: Ubuntu/Debian hoặc CentOS/RHEL/Fedora
- Quyền root hoặc sudo
- Kết nối Internet

## 🚀 Cách Sử Dụng

### Cách 1: Chạy trực tiếp từ GitHub (Khuyến nghị)

Chỉ cần chạy 1 lệnh duy nhất trên server:

```bash
bash <(curl -s https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/install_squid.sh)
```

Hoặc nếu dùng wget:

```bash
bash <(wget -qO- https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/install_squid.sh)
```

**Lưu ý:** Thay `YOUR_USERNAME` và `YOUR_REPO` bằng thông tin repository GitHub của bạn.

### Cách 2: Tải về và chạy

```bash
# Tải file về
wget https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/install_squid.sh

# Cấp quyền thực thi
chmod +x install_squid.sh

# Chạy script
sudo ./install_squid.sh
```

## ⚙️ Cấu Hình

Script sẽ hỏi bạn các câu hỏi sau:

### 1. Port
- **Mặc định:** 3128
- Nếu muốn đổi, nhập `y` và nhập port mong muốn (1-65535)

### 2. Authentication (Username/Password)
- **Mặc định:** Không cần
- Nếu muốn bảo mật, nhập `y` và nhập username/password

### 3. IP Whitelist
- **Mặc định:** Allow tất cả IP
- Nếu muốn giới hạn, nhập `n` và nhập các IP được phép (mỗi IP một dòng)

## 📝 Ví Dụ Sử Dụng

### Ví dụ 1: Cài đặt cơ bản (mặc định)
```bash
sudo bash install_squid.sh
# Trả lời: n, n, y (giữ nguyên port, không auth, allow all)
```

### Ví dụ 2: Cài đặt với port tùy chỉnh và authentication
```bash
sudo bash install_squid.sh
# Trả lời: y (đổi port) -> 8080
# Trả lời: y (cần auth) -> username: myuser, password: mypass
# Trả lời: y (allow all)
```

### Ví dụ 3: Cài đặt với IP whitelist
```bash
sudo bash install_squid.sh
# Trả lời: n (giữ port mặc định)
# Trả lời: n (không cần auth)
# Trả lời: n (không allow all) -> nhập: 192.168.1.100, 10.0.0.50
```

## 🔧 Quản Lý Squid

### Khởi động dịch vụ
```bash
sudo systemctl start squid
```

### Dừng dịch vụ
```bash
sudo systemctl stop squid
```

### Khởi động lại dịch vụ
```bash
sudo systemctl restart squid
```

### Xem trạng thái
```bash
sudo systemctl status squid
```

### Xem log truy cập
```bash
sudo tail -f /var/log/squid/access.log
```

### Xem log cache
```bash
sudo tail -f /var/log/squid/cache.log
```

## 🔍 Kiểm Tra Cấu Hình

### Xem file cấu hình
```bash
sudo cat /etc/squid/squid.conf
```

### Kiểm tra cú pháp cấu hình
```bash
sudo squid -k parse
```

### Test cấu hình và reload
```bash
sudo squid -k reconfigure
```

## 🌐 Sử Dụng Proxy

Sau khi cài đặt, bạn có thể sử dụng proxy với thông tin:

- **Host:** IP của server
- **Port:** Port đã cấu hình (mặc định 3128)
- **Username/Password:** (nếu có cấu hình)

### Cấu hình trong trình duyệt

1. **Chrome/Edge:**
   - Settings → Advanced → System → Open proxy settings
   - Hoặc sử dụng extension như SwitchyOmega

2. **Firefox:**
   - Settings → Network Settings → Settings
   - Chọn Manual proxy configuration
   - Nhập IP và Port

3. **Terminal (Linux/Mac):**
```bash
export http_proxy=http://username:password@IP:PORT
export https_proxy=http://username:password@IP:PORT
```

4. **Windows PowerShell:**
```powershell
$env:http_proxy="http://username:password@IP:PORT"
$env:https_proxy="http://username:password@IP:PORT"
```

## 🔒 Bảo Mật

### Thêm user mới (nếu đã cấu hình auth)
```bash
sudo htpasswd /etc/squid/passwords newusername
```

### Xóa user
```bash
sudo htpasswd -D /etc/squid/passwords username
```

### Thay đổi password
```bash
sudo htpasswd /etc/squid/passwords username
```

### Chỉnh sửa IP whitelist
1. Chỉnh sửa file `/etc/squid/squid.conf`
2. Thêm/xóa các dòng `acl allowed_ips src IP_ADDRESS`
3. Reload: `sudo systemctl reload squid`

## 📂 Các File Quan Trọng

- **Cấu hình:** `/etc/squid/squid.conf`
- **Backup cấu hình:** `/etc/squid/squid.conf.backup.*`
- **Password file:** `/etc/squid/passwords` (nếu có auth)
- **Log truy cập:** `/var/log/squid/access.log`
- **Log cache:** `/var/log/squid/cache.log`
- **Cache directory:** `/var/spool/squid`

## 🐛 Xử Lý Lỗi

### Squid không khởi động
```bash
# Kiểm tra log
sudo journalctl -u squid -n 50

# Kiểm tra cú pháp cấu hình
sudo squid -k parse

# Kiểm tra port có bị chiếm không
sudo netstat -tulpn | grep :3128
```

### Không kết nối được proxy
1. Kiểm tra firewall:
```bash
# Ubuntu/Debian
sudo ufw allow 3128/tcp

# CentOS/RHEL
sudo firewall-cmd --permanent --add-port=3128/tcp
sudo firewall-cmd --reload
```

2. Kiểm tra Squid đang chạy:
```bash
sudo systemctl status squid
```

3. Kiểm tra IP whitelist (nếu có giới hạn)

## 📄 License

Tự do sử dụng và chỉnh sửa.

## 🤝 Đóng Góp

Nếu có vấn đề hoặc đề xuất, vui lòng tạo issue trên GitHub.

## 📞 Hỗ Trợ

Nếu gặp vấn đề, kiểm tra:
1. Log của Squid: `sudo journalctl -u squid`
2. File cấu hình: `/etc/squid/squid.conf`
3. Quyền truy cập file: `ls -la /etc/squid/`

