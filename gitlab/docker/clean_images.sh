# 镜像清理后空间不会释放，得手动释放
docker exec -it gitlab gitlab-ctl registry-garbage-collect -m
