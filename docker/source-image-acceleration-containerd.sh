# docker.io代理
mkdir -p /etc/containerd/certs.d/docker.io
cat >> /etc/containerd/certs.d/docker.io/hosts.toml <<EOF
server = "https://registry-1.docker.io"

[host."https://docker.xuanyuan.me"]
  capabilities = ["pull", "resolve"]

[host."https://docker.m.daocloud.io"]
  capabilities = ["pull", "resolve"]
EOF


# registry.k8s.io代理
sudo mkdir -p /etc/containerd/certs.d/registry.k8s.io
cat <<EOF | sudo tee /etc/containerd/certs.d/registry.k8s.io/hosts.toml
server = "https://registry.k8s.io"

[host."https://k8s.m.daocloud.io"]
  capabilities = ["pull", "resolve"]
EOF

systemctl restart containerd
