# Hướng Dẫn Cài Đặt và Sử Dụng Squid Proxy

## 🚀 Cài Đặt Nhanh

### Trên Server Linux, chạy 1 lệnh duy nhất:

```bash
bash <(curl -s https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/install_squid.sh)
```

**Lưu ý:** Thay `YOUR_USERNAME` và `YOUR_REPO` bằng thông tin GitHub của bạn.

Hoặc nếu server không có curl:

```bash
bash <(wget -qO- https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/install_squid.sh)
```

## 📝 Quá Trình Cài Đặt

Script sẽ hỏi bạn 3 câu hỏi:

### 1. Đổi Port?
- **Nhập `n`** (hoặc Enter) → Giữ port mặc định **3128**
- **Nhập `y`** → Nhập port bạn muốn (ví dụ: 8080, 9999, ...)

### 2. Cần Username và Password?
- **Nhập `n`** (hoặc Enter) → Không cần đăng nhập
- **Nhập `y`** → Nhập username và password

### 3. Allow tất cả IP?
- **Nhập `y`** (hoặc Enter) → Cho phép tất cả IP truy cập
- **Nhập `n`** → Nhập từng IP được phép (mỗi IP một dòng, Enter 2 lần để kết thúc)

## 💡 Ví Dụ

### Ví dụ 1: Cài đặt đơn giản nhất
```
Đổi port? [n]: (Enter)
Cần user/pass? [n]: (Enter)
Allow all IP? [y]: (Enter)
```
→ Port 3128, không cần đăng nhập, cho phép tất cả IP

### Ví dụ 2: Cài đặt có bảo mật
```
Đổi port? [n]: y
Port: 8080
Cần user/pass? [n]: y
Username: myuser
Password: mypass123
Allow all IP? [y]: (Enter)
```
→ Port 8080, cần đăng nhập với myuser/mypass123, cho phép tất cả IP

### Ví dụ 3: Chỉ cho phép IP cụ thể
```
Đổi port? [n]: (Enter)
Cần user/pass? [n]: (Enter)
Allow all IP? [y]: n
IP: 192.168.1.100
IP: 10.0.0.50
IP: (Enter)
```
→ Port 3128, không cần đăng nhập, chỉ cho phép 2 IP trên

## 🔧 Quản Lý Squid

### Khởi động
```bash
sudo systemctl start squid
```

### Dừng
```bash
sudo systemctl stop squid
```

### Khởi động lại
```bash
sudo systemctl restart squid
```

### Xem trạng thái
```bash
sudo systemctl status squid
```

### Xem log
```bash
sudo tail -f /var/log/squid/access.log
```

## 🌐 Sử Dụng Proxy

Sau khi cài đặt xong, script sẽ hiển thị thông tin proxy:

- **IP Server:** (IP của server)
- **Port:** (Port đã cấu hình)
- **Username/Password:** (nếu có)

### Cách dùng trong trình duyệt:

1. **Chrome/Edge:**
   - Cài extension **Proxy SwitchyOmega**
   - Hoặc Settings → System → Proxy → Manual

2. **Firefox:**
   - Settings → Network Settings → Manual proxy
   - Nhập IP và Port

3. **Terminal (Linux/Mac):**
```bash
export http_proxy=http://IP:PORT
export https_proxy=http://IP:PORT
```

4. **Windows:**
   - Settings → Network & Internet → Proxy
   - Hoặc dùng phần mềm như Proxifier

## 🔒 Thêm/Xóa User (nếu có cấu hình auth)

### Thêm user mới:
```bash
sudo htpasswd /etc/squid/passwords ten_user_moi
```

### Xóa user:
```bash
sudo htpasswd -D /etc/squid/passwords ten_user
```

### Đổi password:
```bash
sudo htpasswd /etc/squid/passwords ten_user
```

## 🛡️ Mở Firewall

Nếu không kết nối được, mở port trên firewall:

### Ubuntu/Debian:
```bash
sudo ufw allow 3128/tcp
```

### CentOS/RHEL:
```bash
sudo firewall-cmd --permanent --add-port=3128/tcp
sudo firewall-cmd --reload
```

## ⚠️ Lưu Ý

1. **Phải chạy với quyền root:** Dùng `sudo` hoặc đăng nhập root
2. **Mở firewall:** Nhớ mở port trên firewall nếu có
3. **Backup tự động:** Script tự động backup file cấu hình gốc
4. **File cấu hình:** Nằm tại `/etc/squid/squid.conf`

## 🐛 Xử Lý Lỗi

### Squid không chạy:
```bash
# Kiểm tra log
sudo journalctl -u squid -n 50

# Kiểm tra cấu hình
sudo squid -k parse
```

### Không kết nối được:
1. Kiểm tra Squid đang chạy: `sudo systemctl status squid`
2. Kiểm tra firewall đã mở port chưa
3. Kiểm tra IP whitelist (nếu có giới hạn)

## 📞 Hỗ Trợ

- File cấu hình: `/etc/squid/squid.conf`
- Log truy cập: `/var/log/squid/access.log`
- Log lỗi: `sudo journalctl -u squid`

