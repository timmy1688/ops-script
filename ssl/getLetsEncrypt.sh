#免费申请证书

# 下载certbot工具用于申请Let s Encrypt免费ssl证书
apt install certbot -y

# 申请证书
certbot certonly --webroot \
  -w ./nginx/dist \
  -d wtian.cloud \
  -d www.wtian.cloud \
  --email 123456@qq.com \
  --agree-tos \
  --no-eff-email

# Certbot 命令：使用 webroot 方式为 wtian.cloud 和 www.wtian.cloud 申请 Let's Encrypt 免费证书
# 
# certonly              : 只申请证书，不自动安装或修改服务器配置（如 Nginx）
# --webroot             : 使用 webroot 验证方式（通过在网站目录放临时文件验证域名所有权）
# -w ./nginx/dist       : 指定网站根目录路径（宿主机路径），验证文件会放在这里
# -d wtian.cloud        : 要申请证书的第一个域名（主域名）
# -d www.wtian.cloud    : 要申请证书的第二个域名（www 子域名，一张证书可包含多个域名）
# --email 593817844@qq.com : 绑定邮箱，用于接收证书到期提醒和重要安全通知
# --agree-tos            : 自动同意 Let's Encrypt 的服务条款（避免交互式确认）
# --no-eff-email         : 不加入 EFF（电子前沿基金会）的邮件订阅列表（不接收宣传邮件）

# 证书续签
certbot renew --webroot  \
  -w ./nginx/dist \
  -d wtian.cloud \
  -d www.wtian.cloud \
  --quiet

