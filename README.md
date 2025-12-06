# Squid Proxy Auto Installer

Script tự động cài đặt và cấu hình Squid Proxy trên Ubuntu/Debian với các tùy chọn linh hoạt.

## Cách sử dụng

### 1. Tải script lên server

```bash
# Tải script
wget https://raw.githubusercontent.com/YOUR_USERNAME/squid-proxy/main/install_squid.sh

# Cấp quyền thực thi
chmod +x install_squid.sh
```

### 2. Chạy script

```bash
# Chạy với quyền root
sudo ./install_squid.sh
```

### 3. Làm theo hướng dẫn

Script sẽ hỏi bạn các câu hỏi sau:
1. **Có muốn đổi port mặc định (3128) không?**
   - Nhập `y` nếu muốn đổi, sau đó nhập số port mong muốn
   - Nhập `n` để sử dụng port mặc định (3128)

2. **Có muốn cài đặt xác thực người dùng không?**
   - Nhập `y` nếu muốn bật xác thực, sau đó nhập username và password
   - Nhập `n` nếu không cần xác thực

3. **Có muốn giới hạn IP được phép truy cập không?**
   - Nhập `y` nếu muốn giới hạn IP, sau đó nhập các IP cách nhau bởi dấu cách
   - Nhập `n` để cho phép tất cả IP truy cập

## Cách sử dụng sau khi cài đặt

- **Địa chỉ proxy**: `http://YOUR_SERVER_IP:PORT`
- **Xác thực** (nếu bật): Sử dụng username/password đã đặt

## Quản lý người dùng (nếu bật xác thực)

### Thêm người dùng mới:
```bash
htpasswd /etc/squid/passwords username
```

### Xóa người dùng:
```bash
htpasswd -D /etc/squid/passwords username
```

## Gỡ cài đặt

```bash
sudo apt remove --purge squid apache2-utils
sudo rm -f /etc/squid/passwords
```

## Lưu ý

- Script yêu cầu chạy với quyền root
- Hệ điều hành hỗ trợ: Ubuntu/Debian
- Luôn sao lưu cấu hình trước khi thay đổi
