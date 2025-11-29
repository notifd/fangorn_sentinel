# GitHub Actions Self-Hosted Runner

This directory contains configuration for running an Ubuntu 24.04-based GitHub Actions self-hosted runner for the Fangorn Sentinel project.

## Quick Start

### Using Docker Run

```bash
docker build -f docker/Dockerfile.github-runner -t fangorn-github-runner .

docker run -d \
  --name fangorn-runner \
  -e RUNNER_URL="https://github.com/notifd" \
  -e RUNNER_TOKEN="YOUR_TOKEN_HERE" \
  -e RUNNER_NAME="fangorn-sentinel-runner" \
  -e RUNNER_LABELS="self-hosted,Linux,X64,ubuntu,fangorn" \
  fangorn-github-runner
```

### Using Docker Compose

1. Create a `.env` file in the `docker/` directory:

```bash
GITHUB_RUNNER_TOKEN=YOUR_TOKEN_HERE
```

2. Start the runner:

```bash
cd docker
docker-compose -f docker-compose.github-runner.yml up -d
```

3. Check logs:

```bash
docker-compose -f docker-compose.github-runner.yml logs -f
```

4. Stop the runner:

```bash
docker-compose -f docker-compose.github-runner.yml down
```

## Getting a Runner Token

To get a registration token for your organization:

1. Go to https://github.com/organizations/notifd/settings/actions/runners/new
2. Select "Linux" as the operating system
3. Copy the token from the configuration command

**Note**: Tokens expire after 1 hour. You'll need to regenerate them if the container hasn't started within that time.

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `RUNNER_URL` | GitHub organization/repo URL | `https://github.com/notifd` |
| `RUNNER_TOKEN` | Registration token (required) | - |
| `RUNNER_NAME` | Runner name | `hostname` |
| `RUNNER_LABELS` | Comma-separated labels | `self-hosted,Linux,X64` |
| `RUNNER_WORK_DIRECTORY` | Work directory | `_work` |

## Advanced Configuration

### Enable Docker-in-Docker

If your workflows need to build Docker images, uncomment these lines in `docker-compose.github-runner.yml`:

```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock
privileged: true
```

### Custom Labels

Add custom labels to target specific runners:

```bash
-e RUNNER_LABELS="self-hosted,Linux,X64,elixir,ios-build"
```

### Multiple Runners

To run multiple runners, use docker-compose scale:

```bash
docker-compose -f docker-compose.github-runner.yml up -d --scale github-runner=3
```

**Note**: Each runner needs a unique name. You may need to modify the compose file to generate unique names.

## Troubleshooting

### Runner not appearing in GitHub

1. Check logs: `docker logs fangorn-runner`
2. Verify token hasn't expired
3. Check network connectivity: `docker exec fangorn-runner ping github.com`

### Runner exits immediately

- Ensure `RUNNER_TOKEN` is set correctly
- Check if token has expired (tokens expire after 1 hour)
- Verify URL is correct

### Permission issues

If you see permission errors, the runner user may need additional privileges. Check the Dockerfile's sudo configuration.

## Security Considerations

- **Tokens**: Never commit runner tokens to version control. Use environment variables or secrets management.
- **Network**: Consider running runners in a private network with restricted egress.
- **Updates**: Regularly update the runner version in the Dockerfile (`RUNNER_VERSION` arg).
- **Isolation**: Each runner should be isolated and ephemeral for security.

## Updating Runner Version

To update to a newer GitHub Actions runner version:

1. Check latest version: https://github.com/actions/runner/releases
2. Update `RUNNER_VERSION` in `Dockerfile.github-runner`
3. Rebuild the image:

```bash
docker build -f docker/Dockerfile.github-runner -t fangorn-github-runner .
```

## Maintenance

### Cleanup

Remove stopped runners from GitHub:

```bash
docker exec fangorn-runner ./config.sh remove --token YOUR_TOKEN
```

### Logs

View runner logs:

```bash
docker logs -f fangorn-runner
```

### Shell Access

Access the runner container:

```bash
docker exec -it fangorn-runner /bin/bash
```
