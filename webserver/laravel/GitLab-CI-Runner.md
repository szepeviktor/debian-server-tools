# Set up a specific GitLab CI Runner manually

See https://docs.gitlab.com/runner/register/index.html#docker

```bash
docker run --rm -i -t -v /opt:/etc/gitlab-runner gitlab/gitlab-runner:latest register
#  --non-interactive \
#  --url "https://gitlab.com/" \
#  --registration-token "PROJECT-REGISTRATION-TOKEN" \
#  --executor "docker" \
#  --docker-image "php:7.2-stretch" \
#  --description "gitlab-runner on UpCloud" \
#  --tag-list "upcloud,docker" \
#  --run-untagged \
#  --locked="false"
cat /opt/config.toml

docker run -v /opt:/etc/gitlab-runner -v /var/run/docker.sock:/var/run/docker.sock gitlab/gitlab-runner:latest run
```

Add `-d` to run in detached mode. View log with `docker logs -f CONTAINER-ID`

**Allow new connecting IP.**

### Cache adapter

Supports: s3, gcs.

See https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runnerscache-section
