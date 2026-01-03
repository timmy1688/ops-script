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

如果你想签发一个泛域名证书（即 *.wtian.cloud，可以覆盖所有一级子域名，如 api.wtian.cloud、blog.wtian.cloud、abc.wtian.cloud 等），不能使用 --webroot 方式，因为 HTTP-01 挑战无法验证通配符域名。
必须改用 DNS-01 验证方式
certbot certonly --manual \
  --preferred-challenges dns \
  -d "*.wtian.cloud" \
  -d wtian.cloud \
  --email 123456@qq.com \
  --agree-tos \
  --no-eff-email
  
执行过程会这样交互：
1、Certbot 会暂停，并提示你去 DNS 控制台添加一条 TXT 记录，例如：
--------------
textPlease deploy a DNS TXT record under the name:
_acme-challenge.wtian.cloud

With the following value:
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
---------------
2、登录你的域名解析提供商（比如 Cloudflare、阿里云万网、DNSPod 等），添加一条 TXT 记录：
主机记录：_acme-challenge
类型：TXT
值：Certbot 给你的那串长字符串
3、保存后等待 1-5 分钟 DNS 生效（可以用 dig TXT _acme-challenge.wtian.cloud 检查）。
4、回车继续，Certbot 会自动验证通过，然后颁发证书




# 证书续签
certbot renew --webroot  \
  -w ./nginx/dist \
  -d wtian.cloud \
  -d www.wtian.cloud \
  --quiet

