##具体可参考https://developer.aliyun.com/mirror/docker-ce?spm=a2c6h.13651102.0.0.57e31b110iCbia

#一件部署脚本
----------------
# step 1: 安装必要的一些系统工具
apt update && \
apt -y install ca-certificates curl gnupg  && \

# step 2: 信任 Docker 的 GPG 公钥
install -m 0755 -d /etc/apt/keyrings && \
curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
chmod a+r /etc/apt/keyrings/docker.gpg && \

# Step 3: 写入软件源信息
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.aliyun.com/docker-ce/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null && \
 
# Step 4: 安装Docker
apt update && \
apt -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
------------------

# 安装指定版本的Docker-CE:
# Step 1: 查找Docker-CE的版本:
# apt-cache madison docker-ce
#   docker-ce | 17.03.1~ce-0~ubuntu-xenial | https://mirrors.aliyun.com/docker-ce/linux/ubuntu xenial/stable amd64 Packages
#   docker-ce | 17.03.0~ce-0~ubuntu-xenial | https://mirrors.aliyun.com/docker-ce/linux/ubuntu xenial/stable amd64 Packages
# Step 2: 安装指定版本的Docker-CE: (VERSION例如上面的17.03.1~ce-0~ubuntu-xenial)
# sudo apt-get -y install docker-ce=[VERSION]

# docker-ce：Docker 引擎本身，负责容器的生命周期管理。
# docker-ce-cli：命令行工具，允许用户与 Docker 引擎交互。
# containerd：底层容器运行时，负责容器的实际运行和管理。

#扩展1: 安装nvidia-container,使用nvidia显卡
apt install -y nvidia-container-toolkit
nvidia-ctk runtime configure --runtime=docker
systemctl restart docker

#扩展2：安装docker-compose
curl -L "https://github.whrstudio.top/https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
