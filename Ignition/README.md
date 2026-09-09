# Ignition 8.3.9 Maker Edition

Minimal container deployment of Inductive Automation Ignition 8.3.9 Maker Edition for the home automation environment.

This setup is intended for **manual deployment using the Portainer Stack Web editor**, matching the other manually managed stacks. It does not contain CI/CD, webhooks, automatic stack updates, Caddy changes, or changes to any other repository.

## What is deployed

- Official image: `inductiveautomation/ignition:8.3.9`
- Maker Edition
- ARM64-compatible image for Raspberry Pi
- Persistent Ignition data in a Docker named volume mounted at `/usr/local/bin/ignition/data`
- HTTP on container port `8088`
- TLS is expected to be terminated by the existing Caddy instance
- Docker log rotation limited to 3 x 10 MB
- Version pinned to `8.3.9`

No separate database or other services are deployed.

## Why a named volume is used

Ignition ships initial files inside `/usr/local/bin/ignition/data`, including files required during first startup. Docker automatically copies those existing files into a newly created empty named volume.

Do not replace the named volume with an empty host bind mount for a fresh installation. A bind mount hides the files already present in the image and can cause startup errors such as a missing `gateway.xml_clean`.

The official Ignition Docker examples use a named volume on `/usr/local/bin/ignition/data` for persistent Gateway state.

## 1. Check available disk space

Before deploying, check the filesystem used by Docker:

```bash
DOCKER_ROOT="$(sudo docker info --format '{{.DockerRootDir}}')"
echo "$DOCKER_ROOT"
df -h "$DOCKER_ROOT"
sudo docker system df
```

The container image and the `ignition-data` volume are stored under Docker's data root. The published ARM64 image is large, so keep several GB free before the first pull and normal operation.

For detailed Docker usage:

```bash
sudo docker system df -v
```

Do not run `docker system prune -a` without reviewing what it will remove.

## 2. Create/update the stack manually in Portainer

The repository is only the source/reference for the stack definition. Portainer does **not** deploy directly from this repository.

In Portainer:

1. Go to **Stacks** -> **Add stack** (or open the existing `ignition` stack when updating it).
2. Select **Web editor**.
3. Copy the complete contents of `Ignition/docker-compose.yml` into the editor.
4. Add the required environment variables below.
5. Click **Deploy the stack** / **Update the stack**.

No Git repository deployment, webhooks, or automatic updates are required.

## 3. Required Portainer environment variables

Configure these in the Portainer Stack UI and do not commit their real values to Git:

```text
GATEWAY_ADMIN_PASSWORD=<choose-a-strong-password>
IGNITION_LICENSE_KEY=<your-Maker-license-key>
IGNITION_ACTIVATION_TOKEN=<your-Maker-activation-token>
```

Optional overrides:

```text
GATEWAY_ADMIN_USERNAME=admin
IGNITION_GATEWAY_NAME=home-automation
IGNITION_BIND_ADDRESS=0.0.0.0
IGNITION_HTTP_PORT=8088
TZ=Europe/Copenhagen
```

The `.env.example` file is documentation only.

## 4. Persistence

The stack defines:

```yaml
volumes:
  ignition-data:
```

and mounts it as:

```yaml
- ignition-data:/usr/local/bin/ignition/data
```

The volume persists independently of the container. Recreating or updating the container therefore retains Gateway configuration, projects and other persistent Ignition state as long as the volume is not deleted.

In a Portainer stack the actual Docker volume name may be prefixed with the stack/project name, for example `ignition_ignition-data`.

Do not select **Remove volumes** when removing/recreating the stack unless you intentionally want to delete the Gateway state.

## 5. Network exposure

Only Ignition HTTP port `8088` is published. Ignition HTTPS/8043 is intentionally not published because the existing Caddy instance should terminate HTTPS.

By default:

```text
0.0.0.0:8088 -> ignition:8088
```

Before adding Caddy, test directly:

```text
http://<RASPI-LAN-IP>:8088
```

## 6. Existing Caddy

No Caddy repository/configuration is changed here.

Add a site block manually to the existing Caddy configuration:

```caddyfile
ignition.<your-domain> {
    reverse_proxy <RASPI-LAN-IP>:8088
}
```

The stack enables:

```text
gateway.useProxyForwardedHeader=true
```

so Ignition can honor forwarded host/protocol information from Caddy. Caddy handles WebSocket upgrades automatically.

Create/update DNS for the chosen hostname and reload Caddy using the existing procedure.

## 7. First startup

On first deployment, watch the Ignition container logs in Portainer. The environment variables supply:

- EULA acceptance
- Maker edition selection
- initial Gateway administrator
- Maker license key
- Maker activation token

The Maker license is leased and therefore requires outbound Internet access from the Ignition container for activation/renewal.

When startup is complete, use either:

```text
http://<RASPI-LAN-IP>:8088
```

or, after Caddy/DNS are configured:

```text
https://ignition.<your-domain>
```

## 8. Upgrades

The image is deliberately pinned to:

```text
inductiveautomation/ignition:8.3.9
```

For a future upgrade, change the image tag in the repository, copy the updated YAML into Portainer's Web editor and manually update the stack. Back up the Ignition Gateway before changing versions.

## Files

```text
Ignition/
├── docker-compose.yml
├── .env.example
└── README.md
```
