#!/usr/bin/env bash
# install_squid.sh - Script tự động cài & cấu hình Squid proxy

set -e

echo "=== Script cài đặt & cấu hình Squid proxy ==="

# Kiểm tra quyền root
if [[ "$EUID" -ne 0 ]]; then
  echo "Vui lòng chạy script với quyền root (sudo)."
  exit 1
fi

# Phát hiện trình quản lý gói
PM=""
if command -v apt-get >/dev/null 2>&1; then
  PM="apt"
elif command -v dnf >/dev/null 2>&1; then
  PM="dnf"
elif command -v yum >/dev/null 2>&1; then
  PM="yum"
else
  echo "Không tìm thấy apt, dnf hoặc yum. Script chỉ hỗ trợ Debian/Ubuntu/CentOS/RHEL."
  exit 1
fi

echo "Trình quản lý gói phát hiện: $PM"

# Cài đặt Squid + công cụ tạo user/password
echo "=== Cài đặt Squid và công cụ hỗ trợ ==="
if [[ "$PM" == "apt" ]]; then
  apt-get update -y
  apt-get install -y squid apache2-utils
else
  $PM install -y squid httpd-tools
fi

SQUID_CONF="/etc/squid/squid.conf"
SQUID_PASSWD="/etc/squid/passwd"

# Backup config cũ
if [[ -f "$SQUID_CONF" ]]; then
  cp "$SQUID_CONF" "${SQUID_CONF}.bak.$(date +%Y%m%d%H%M%S)"
  echo "Đã backup file cấu hình cũ: ${SQUID_CONF}.bak.*"
fi

echo
echo "=== Cấu hình Squid ==="

# Hỏi port
read -rp "Nhập port cho Squid (mặc định 3128, Enter để dùng mặc định): " SQUID_PORT
if [[ -z "$SQUID_PORT" ]]; then
  SQUID_PORT=3128
fi

# Hỏi có dùng user/password không
read -rp "Bạn có muốn bật xác thực user/password cho Squid? (y/N): " ENABLE_AUTH
ENABLE_AUTH=${ENABLE_AUTH,,}  # chuyển về chữ thường

USE_AUTH="no"
SQUID_USER=""
SQUID_PASS=""
if [[ "$ENABLE_AUTH" == "y" || "$ENABLE_AUTH" == "yes" ]]; then
  USE_AUTH="yes"
  read -rp "Nhập username dùng để login proxy: " SQUID_USER
  while [[ -z "$SQUID_USER" ]]; do
    echo "Username không được để trống."
    read -rp "Nhập username dùng để login proxy: " SQUID_USER
  done

  read -srp "Nhập password cho user '$SQUID_USER': " SQUID_PASS
  echo
  while [[ -z "$SQUID_PASS" ]]; do
    echo "Password không được để trống."
    read -srp "Nhập password cho user '$SQUID_USER': " SQUID_PASS
    echo
  done
fi

# Hỏi có allow all IP không
read -rp "Bạn có muốn ALLOW ALL (cho tất cả IP truy cập proxy)? (y/N): " ALLOW_ALL
ALLOW_ALL=${ALLOW_ALL,,}

ALLOW_MODE="restricted"
ALLOWED_IPS=""
if [[ "$ALLOW_ALL" == "y" || "$ALLOW_ALL" == "yes" ]]; then
  ALLOW_MODE="all"
else
  echo "Nhập danh sách IP / dải IP (CIDR) được phép dùng proxy."
  echo "Ví dụ: 1.2.3.4 5.6.7.0/24 10.0.0.0/8"
  read -rp "IP/dải IP (cách nhau bằng khoảng trắng): " ALLOWED_IPS
  if [[ -z "$ALLOWED_IPS" ]]; then
    echo "Không nhập IP => không ai truy cập được proxy ngoại trừ localhost."
    ALLOW_MODE="localhost_only"
  fi
fi

# Tìm đường dẫn basic_ncsa_auth
AUTH_HELPER=""
if [[ "$USE_AUTH" == "yes" ]]; then
  if [[ -x /usr/lib/squid/basic_ncsa_auth ]]; then
    AUTH_HELPER="/usr/lib/squid/basic_ncsa_auth"
  elif [[ -x /usr/lib64/squid/basic_ncsa_auth ]]; then
    AUTH_HELPER="/usr/lib64/squid/basic_ncsa_auth"
  else
    echo "Không tìm thấy basic_ncsa_auth. Kiểm tra lại gói squid hoặc helper auth."
    exit 1
  fi
fi

# Tạo user/password nếu cần
if [[ "$USE_AUTH" == "yes" ]]; then
  echo "=== Tạo file user/password cho Squid ==="
  # -c: tạo mới file, -b: dùng password trong command line
  htpasswd -b -c "$SQUID_PASSWD" "$SQUID_USER" "$SQUID_PASS"
  chmod 640 "$SQUID_PASSWD"
  chown proxy:proxy "$SQUID_PASSWD" 2>/dev/null || true
fi

# Ghi file cấu hình mới
echo "=== Ghi file cấu hình $SQUID_CONF ==="

cat > "$SQUID_CONF" <<EOF
# Cấu hình Squid do script tạo tự động

http_port $SQUID_PORT

# Định nghĩa ACL cơ bản
acl localhost src 127.0.0.1/32 ::1
acl to_localhost dst 127.0.0.0/8 ::1

EOF

# ACL IP được phép (nếu có)
if [[ "$ALLOW_MODE" == "all" ]]; then
  echo "# Cho phép tất cả IP truy cập (NGUY HIỂM nếu server public internet)" >> "$SQUID_CONF"
elif [[ "$ALLOW_MODE" == "restricted" ]]; then
  echo "# Chỉ cho phép các IP/dải IP cụ thể truy cập" >> "$SQUID_CONF"
  echo -n "acl allowed_ips src" >> "$SQUID_CONF"
  for ip in $ALLOWED_IPS; do
    echo -n " $ip" >> "$SQUID_CONF"
  done
  echo >> "$SQUID_CONF"
elif [[ "$ALLOW_MODE" == "localhost_only" ]]; then
  echo "# Chỉ cho phép localhost truy cập" >> "$SQUID_CONF"
fi

echo >> "$SQUID_CONF"

# Cấu hình xác thực (nếu bật)
if [[ "$USE_AUTH" == "yes" ]]; then
  cat >> "$SQUID_CONF" <<EOF
# Cấu hình xác thực basic với file passwd
auth_param basic program $AUTH_HELPER $SQUID_PASSWD
auth_param basic realm Squid proxy
auth_param basic credentialsttl 2 hours
acl authenticated proxy_auth REQUIRED

EOF
fi

# Luật http_access
echo "# Thứ tự http_access rất quan trọng" >> "$SQUID_CONF"
echo "http_access deny to_localhost" >> "$SQUID_CONF"
echo "http_access allow localhost" >> "$SQUID_CONF"

if [[ "$USE_AUTH" == "yes" ]]; then
  if [[ "$ALLOW_MODE" == "all" ]]; then
    echo "http_access allow authenticated" >> "$SQUID_CONF"
  elif [[ "$ALLOW_MODE" == "restricted" ]]; then
    echo "http_access allow authenticated allowed_ips" >> "$SQUID_CONF"
  elif [[ "$ALLOW_MODE" == "localhost_only" ]]; then
    # đã allow localhost ở trên, user/pass chỉ áp cho các IP khác (nhưng hiện tại không có IP nào khác được allow)
    :
  fi
else
  if [[ "$ALLOW_MODE" == "all" ]]; then
    echo "http_access allow all" >> "$SQUID_CONF"
  elif [[ "$ALLOW_MODE" == "restricted" ]]; then
    echo "http_access allow allowed_ips" >> "$SQUID_CONF"
  elif [[ "$ALLOW_MODE" == "localhost_only" ]]; then
    # chỉ localhost đã được allow ở trên
    :
  fi
fi

echo "http_access deny all" >> "$SQUID_CONF"

cat >> "$SQUID_CONF" <<'EOF'

# Một số tuỳ chọn đề xuất
cache_mem 256 MB
maximum_object_size_in_memory 512 KB
cache_dir ufs /var/spool/squid 2000 16 256
access_log /var/log/squid/access.log
cache_log /var/log/squid/cache.log

# Ẩn bớt thông tin
via off
forwarded_for delete
request_header_access X-Forwarded-For deny all
request_header_access Via deny all
request_header_access Cache-Control deny all
EOF

# Khởi tạo cache directory nếu cần
echo "=== Khởi tạo cache (nếu cần) ==="
if [[ -d /var/spool/squid ]]; then
  squid -z || true
fi

# Restart & enable service
echo "=== Restart Squid service ==="
if command -v systemctl >/dev/null 2>&1; then
  systemctl enable squid >/dev/null 2>&1 || true
  systemctl restart squid
  systemctl --no-pager -l status squid || true
else
  service squid restart
  service squid status || true
fi

echo
echo "=== Hoàn tất cài đặt Squid ==="
echo "Port: $SQUID_PORT"
if [[ "$USE_AUTH" == "yes" ]]; then
  echo "Xác thực: BẬT (user: $SQUID_USER)"
else
  echo "Xác thực: TẮT (không cần user/password)"
fi

if [[ "$ALLOW_MODE" == "all" ]]; then
  echo "ACL IP: ALLOW ALL (NGUY HIỂM nếu server public internet)"
elif [[ "$ALLOW_MODE" == "restricted" ]]; then
  echo "ACL IP: chỉ cho phép các IP/dải IP sau: $ALLOWED_IPS"
elif [[ "$ALLOW_MODE" == "localhost_only" ]]; then
  echo "ACL IP: chỉ localhost"
fi

echo
echo "File cấu hình: $SQUID_CONF"
echo "File backup: ${SQUID_CONF}.bak.* (nếu cần rollback)"
if [[ "$USE_AUTH" == "yes" ]]; then
  echo "File user/password: $SQUID_PASSWD"
fi
echo "Log truy cập: /var/log/squid/access.log"
echo
echo "Xong. Bạn hãy thử dùng proxy: SERVER_IP:$SQUID_PORT"
if [[ "$USE_AUTH" == "yes" ]]; then
  echo "Login với user/password vừa tạo."
fi
