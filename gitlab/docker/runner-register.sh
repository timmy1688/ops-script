有以下两种部署方式

1、runner容器部署
docker exec gitlab-runner gitlab-runner register \
  --non-interactive \
  --url "https://gitlab.com/" \
  --token "<your_registration_token>" \
  --executor "docker" \
  --docker-image "docker:24.0.5" \
  --description "docker-runner" \
  --tag-list "docker,ci" \
  --run-untagged="true" \
  --locked="false" \
  --docker-volumes "/var/run/docker.sock:/var/run/docker.sock"


2、apt部署runner,指定docker为执行器（推荐）
#runner部署
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash
apt-get install gitlab-runner


#runner注册
sudo gitlab-runner register \
  --non-interactive \
  --url http://gitlab.com \
  --token glrt-t1_xxxxxxxxxxxxxxx \
  --executor docker \
  --docker-image docker:latest \
  --description "ci" \
  --docker-volumes /var/run/docker.sock:/var/run/docker.sock \
  --docker-privileged=true

  注意：url token参数在gitlab web平台新建runner的时候会有。成功注册后web界面中runner的标识会变绿
