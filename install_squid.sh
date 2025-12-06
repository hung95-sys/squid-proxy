#!/bin/bash

# Script tự động cài đặt và cấu hình Squid Proxy Server
# Tác giả: Auto-generated
# Ngày: $(date +%Y-%m-%d)

set -e

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Kiểm tra quyền root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Vui lòng chạy script với quyền root (sudo)${NC}"
    exit 1
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Script cài đặt Squid Proxy Server${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Hỏi về port
echo -e "${YELLOW}Bạn có muốn đổi port mặc định (3128) không? (y/n)${NC}"
read -p "Nhập lựa chọn [n]: " change_port
change_port=${change_port:-n}

if [ "$change_port" = "y" ] || [ "$change_port" = "Y" ]; then
    read -p "Nhập port bạn muốn sử dụng: " squid_port
    if ! [[ "$squid_port" =~ ^[0-9]+$ ]] || [ "$squid_port" -lt 1 ] || [ "$squid_port" -gt 65535 ]; then
        echo -e "${RED}Port không hợp lệ, sử dụng port mặc định 3128${NC}"
        squid_port=3128
    fi
else
    squid_port=3128
fi

# Hỏi về authentication
echo -e "${YELLOW}Bạn có cần username và password không? (y/n)${NC}"
read -p "Nhập lựa chọn [n]: " need_auth
need_auth=${need_auth:-n}

if [ "$need_auth" = "y" ] || [ "$need_auth" = "Y" ]; then
    read -p "Nhập username: " squid_user
    read -sp "Nhập password: " squid_pass
    echo ""
    if [ -z "$squid_user" ] || [ -z "$squid_pass" ]; then
        echo -e "${RED}Username hoặc password không được để trống, bỏ qua authentication${NC}"
        need_auth="n"
    fi
fi

# Hỏi về IP whitelist
echo -e "${YELLOW}Bạn có muốn allow tất cả IP không? (y/n)${NC}"
read -p "Nhập lựa chọn [y]: " allow_all
allow_all=${allow_all:-y}

if [ "$allow_all" != "y" ] && [ "$allow_all" != "Y" ]; then
    echo -e "${YELLOW}Nhập các IP được phép truy cập (mỗi IP một dòng, nhấn Enter 2 lần để kết thúc):${NC}"
    allowed_ips=()
    while true; do
        read -p "IP (hoặc Enter để kết thúc): " ip
        if [ -z "$ip" ]; then
            break
        fi
        # Kiểm tra định dạng IP cơ bản
        if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] || [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$ ]]; then
            allowed_ips+=("$ip")
        else
            echo -e "${RED}IP không hợp lệ: $ip${NC}"
        fi
    done
    
    if [ ${#allowed_ips[@]} -eq 0 ]; then
        echo -e "${RED}Không có IP nào được nhập, sẽ allow tất cả IP${NC}"
        allow_all="y"
    fi
fi

echo ""
echo -e "${GREEN}Bắt đầu cài đặt Squid...${NC}"

# Cập nhật hệ thống
echo -e "${YELLOW}[1/6] Cập nhật hệ thống...${NC}"
if command -v apt-get &> /dev/null; then
    apt-get update -y
    apt-get upgrade -y
elif command -v yum &> /dev/null; then
    yum update -y
elif command -v dnf &> /dev/null; then
    dnf update -y
else
    echo -e "${RED}Không tìm thấy package manager phù hợp${NC}"
    exit 1
fi

# Cài đặt Squid
echo -e "${YELLOW}[2/6] Cài đặt Squid...${NC}"
if command -v apt-get &> /dev/null; then
    apt-get install -y squid apache2-utils
elif command -v yum &> /dev/null; then
    yum install -y squid httpd-tools
elif command -v dnf &> /dev/null; then
    dnf install -y squid httpd-tools
fi

# Backup cấu hình gốc
echo -e "${YELLOW}[3/6] Backup cấu hình gốc...${NC}"
cp /etc/squid/squid.conf /etc/squid/squid.conf.backup.$(date +%Y%m%d_%H%M%S)

# Tạo cấu hình Squid
echo -e "${YELLOW}[4/6] Tạo cấu hình Squid...${NC}"

# Cấu hình cơ bản
cat > /etc/squid/squid.conf << EOF
# Cấu hình Squid Proxy Server
# Được tạo tự động bởi install_squid.sh

# Port lắng nghe
http_port $squid_port

# Thư mục cache
cache_dir ufs /var/spool/squid 100 16 256

# Log files
access_log /var/log/squid/access.log
cache_log /var/log/squid/cache.log

# Cấu hình ACL và Rules
EOF

# Thêm ACL cho IP whitelist
if [ "$allow_all" = "y" ] || [ "$allow_all" = "Y" ]; then
    cat >> /etc/squid/squid.conf << EOF
# Allow tất cả IP
acl allowed_ips src all
http_access allow allowed_ips
EOF
else
    cat >> /etc/squid/squid.conf << EOF
# ACL cho các IP được phép
EOF
    for ip in "${allowed_ips[@]}"; do
        echo "acl allowed_ips src $ip" >> /etc/squid/squid.conf
    done
    cat >> /etc/squid/squid.conf << EOF
http_access allow allowed_ips
EOF
fi

# Cấu hình authentication nếu cần
if [ "$need_auth" = "y" ] || [ "$need_auth" = "Y" ]; then
    echo -e "${YELLOW}[5/6] Cấu hình authentication...${NC}"
    
    # Tạo file password
    htpasswd -cb /etc/squid/passwords "$squid_user" "$squid_pass" 2>/dev/null || \
    htpasswd -b /etc/squid/passwords "$squid_user" "$squid_pass"
    
    chmod 640 /etc/squid/passwords
    chown root:proxy /etc/squid/passwords
    
    # Thêm cấu hình auth vào squid.conf
    cat >> /etc/squid/squid.conf << EOF

# Authentication
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwords
auth_param basic children 5
auth_param basic realm Squid Proxy Server
auth_param basic credentialsttl 2 hours
acl authenticated proxy_auth REQUIRED
http_access allow authenticated
EOF
else
    echo -e "${YELLOW}[5/6] Bỏ qua authentication...${NC}"
fi

# Thêm deny all ở cuối
cat >> /etc/squid/squid.conf << EOF

# Deny tất cả các request khác
http_access deny all

# Cấu hình khác
visible_hostname $(hostname)
forwarded_for off
request_header_access X-Forwarded-For deny all
EOF

# Tạo thư mục cache
echo -e "${YELLOW}[6/6] Khởi tạo cache và khởi động dịch vụ...${NC}"
squid -z

# Khởi động và enable Squid
systemctl enable squid
systemctl restart squid

# Kiểm tra trạng thái
sleep 2
if systemctl is-active --quiet squid; then
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Cài đặt thành công!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${GREEN}Thông tin cấu hình:${NC}"
    echo -e "  Port: ${YELLOW}$squid_port${NC}"
    if [ "$need_auth" = "y" ] || [ "$need_auth" = "Y" ]; then
        echo -e "  Username: ${YELLOW}$squid_user${NC}"
        echo -e "  Password: ${YELLOW}******${NC}"
    else
        echo -e "  Authentication: ${YELLOW}Không${NC}"
    fi
    if [ "$allow_all" = "y" ] || [ "$allow_all" = "Y" ]; then
        echo -e "  IP Access: ${YELLOW}Tất cả IP${NC}"
    else
        echo -e "  IP Access: ${YELLOW}Chỉ các IP được phép${NC}"
        for ip in "${allowed_ips[@]}"; do
            echo -e "    - $ip"
        done
    fi
    echo ""
    echo -e "${GREEN}Các lệnh quản lý:${NC}"
    echo -e "  Khởi động: ${YELLOW}systemctl start squid${NC}"
    echo -e "  Dừng: ${YELLOW}systemctl stop squid${NC}"
    echo -e "  Khởi động lại: ${YELLOW}systemctl restart squid${NC}"
    echo -e "  Xem trạng thái: ${YELLOW}systemctl status squid${NC}"
    echo -e "  Xem log: ${YELLOW}tail -f /var/log/squid/access.log${NC}"
    echo ""
    echo -e "${GREEN}Để sử dụng proxy:${NC}"
    echo -e "  Host: ${YELLOW}$(hostname -I | awk '{print $1}')${NC}"
    echo -e "  Port: ${YELLOW}$squid_port${NC}"
    if [ "$need_auth" = "y" ] || [ "$need_auth" = "Y" ]; then
        echo -e "  Username: ${YELLOW}$squid_user${NC}"
        echo -e "  Password: ${YELLOW}$squid_pass${NC}"
    fi
    echo ""
else
    echo -e "${RED}Lỗi: Squid không khởi động được. Kiểm tra log: journalctl -u squid${NC}"
    exit 1
fi

