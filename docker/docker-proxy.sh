mkdir -p /etc/systemd/system/docker.service.d

cat > /etc/systemd/system/docker.service.d/http-proxy.conf <<'EOF'
[Service]
Environment="HTTP_PROXY=http://192.168.0.104:7897"
Environment="HTTPS_PROXY=http://192.168.0.104:7897"
Environment="NO_PROXY=localhost,127.0.0.1,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12"
EOF

systemctl daemon-reload
systemctl restart docker

systemctl show --property=Environment docker
