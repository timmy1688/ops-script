cp 1776189635_2026_04_15_17.5.5_gitlab_backup.tar ./gitlab/data/backups/
chown 998:998 ./gitlab/data/backups/1776189635_2026_04_15_17.5.5_gitlab_backup.tar

# 如果没有这两个文件，2FA 密钥、CI/CD 变量、Runner Token 等加密数据会失效。
docker cp gitlab-secrets.json gitlab:/etc/gitlab/gitlab-secrets.json
docker cp gitlab.rb gitlab:/etc/gitlab/gitlab.rb

docker exec -it gitlab gitlab-ctl stop puma
docker exec -it gitlab gitlab-ctl stop sidekiq
docker exec -it gitlab gitlab-backup restore BACKUP=1776189635_2026_04_15_17.5.5 # 输入两次 yes，等待完成...
docker exec -it gitlab gitlab-ctl reconfigure
docker exec -it gitlab gitlab-ctl restart


- BACKUP= 后面的值 不含 _gitlab_backup.tar 后缀
- 过程中会提示 两次确认，都输入 yes
- 可能出现 ERROR: must be owner of extension pg_trgm 等报错，属正常现象，不影响恢复
- 根据数据量大小，恢复时间从 30 分钟到数小时不等
