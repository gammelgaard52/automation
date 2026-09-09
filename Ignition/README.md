# Ignition 8.3.9 Maker Edition

Minimal container deployment of Inductive Automation Ignition 8.3.9 Maker Edition for the home automation environment.

This setup is intended for **manual deployment using the Portainer Stack Web editor**, matching the other manually managed stacks. It does not contain CI/CD, webhooks, automatic stack updates, Caddy changes, or changes to any other repository.

## What is deployed

- Official image: `inductiveautomation/ignition:8.3.9`
- Maker Edition
- ARM64-compatible image for Raspberry Pi
- Persistent Ignition data at `/usr/local/bin/ignition/data`
- Configurable host path for persistent data
- HTTP on container port `8088`
- TLS is expected to be terminated by the existing Caddy instance
- Docker log rotation is limited to 3 x 10 MB to reduce disk growth
- Version is pinned to `8.3.9`; it will not automatically move to a newer Ignition release

No separate database or other services are deployed.

## 1. Check available disk space first

The Ignition 8.3.9 ARM64 image is large. Before deploying, check the filesystem used by Docker:

```bash
DOCKER_ROOT="$(sudo docker info --format '{{.DockerRootDir}}')"
echo "$DOCKER_ROOT"
df -h "$DOCKER_ROOT"
sudo docker system df
```

The published ARM64 image is roughly 2 GB compressed. Docker also needs space for unpacked layers and normal runtime growth. As a practical safety margin, have several GB free before the first pull; around 5-6 GB free is a sensible target if possible.

If space is tight, inspect usage before deleting anything:

```bash
sudo docker system df -v
```

Do not run `docker system prune -a` unless you have reviewed what it will remove.

The `IGNITION_DATA_PATH` setting controls only the persistent Gateway data. The container image itself is stored under Docker's data root. If the Raspberry Pi has an external SSD, point `IGNITION_DATA_PATH` at that SSD to prevent project/history/data growth from consuming the system disk.

Example:

```text
IGNITION_DATA_PATH=/mnt/ssd/ignition/data
```

Otherwise the default is:

```text
/opt/ignition/data
```

Create the selected directory on the Raspberry Pi before deployment:

```bash
sudo mkdir -p /opt/ignition/data
```

Use the external-disk path instead if applicable.

## 2. Create the stack manually in Portainer

The repository is only the source/reference for the stack definition. Portainer does **not** pull or deploy this repository.

In Portainer:

1. Go to **Stacks** -> **Add stack**.
2. Give the stack a name, for example:

   ```text
   ignition
   ```

3. Select **Web editor**.
4. Open `Ignition/docker-compose.yml` from this repository and copy the complete YAML into the Web editor.
5. Add the required Stack environment variables listed below under **Environment variables**.
6. Do not enable Git/repository deployment, webhooks, or automatic updates.
7. Click **Deploy the stack** when ready.

For future changes, update the stack YAML in this repository first, then manually copy the updated YAML into the existing Portainer stack Web editor and redeploy it.

## 3. Required Portainer environment variables

Set these in the Portainer Stack UI. Do **not** commit the real values to this repository.

### Required

```text
GATEWAY_ADMIN_PASSWORD=<choose-a-strong-password>
IGNITION_LICENSE_KEY=<your-Maker-license-key>
IGNITION_ACTIVATION_TOKEN=<your-Maker-activation-token>
```

### Optional

```text
GATEWAY_ADMIN_USERNAME=admin
IGNITION_GATEWAY_NAME=home-automation
IGNITION_BIND_ADDRESS=0.0.0.0
IGNITION_HTTP_PORT=8088
IGNITION_DATA_PATH=/opt/ignition/data
TZ=Europe/Copenhagen
```

If persistent data should live on an external disk, change only `IGNITION_DATA_PATH`, for example:

```text
IGNITION_DATA_PATH=/mnt/ssd/ignition/data
```

The `.env.example` file is documentation only. The actual values should be entered as Portainer Stack environment variables.

## 4. Network exposure

Only Ignition HTTP port `8088` is published. Ignition HTTPS/8043 is intentionally not published because the existing Caddy instance should terminate HTTPS.

By default the stack publishes:

```text
0.0.0.0:8088 -> ignition:8088
```

If desired, `IGNITION_BIND_ADDRESS` can be changed to the Raspberry Pi's LAN address so the service is not bound to every interface.

Before adding Caddy, test from a machine that can reach the Raspberry Pi:

```text
http://<RASPI-LAN-IP>:8088
```

## 5. Add the site manually to the existing Caddy configuration

No Caddy files are changed by this repository.

Add a site block equivalent to this to the existing Caddy configuration:

```caddyfile
ignition.<your-domain> {
    reverse_proxy <RASPI-LAN-IP>:8088
}
```

Replace:

- `ignition.<your-domain>` with the hostname you want to use.
- `<RASPI-LAN-IP>` with the Raspberry Pi address running Ignition.

The stack enables Ignition's `gateway.useProxyForwardedHeader=true` setting so Caddy's forwarded host/protocol information is honored.

Caddy's `reverse_proxy` handles WebSocket upgrades automatically, so no separate WebSocket block is required.

After editing Caddy, validate/reload it using the same procedure already used for the existing Caddy installation.

Also create/update the required DNS record so the chosen hostname resolves to the Caddy endpoint.

## 6. First startup

After deployment, watch the Ignition container logs in Portainer. The first startup can take longer than a normal restart because the image is pulled and the Gateway is commissioned.

The environment variables automatically supply:

- EULA acceptance
- Maker edition selection
- Initial Gateway administrator
- Maker license key
- Maker activation token

The Maker license is a leased license and therefore requires outbound Internet access from the Ignition container for license activation/renewal.

When the Gateway is available, access it either directly for initial troubleshooting:

```text
http://<RASPI-LAN-IP>:8088
```

or through Caddy after DNS and Caddy have been configured:

```text
https://ignition.<your-domain>
```

## 7. Persistence and upgrades

All persistent Gateway state is stored in:

```text
/usr/local/bin/ignition/data
```

and bind-mounted to the host path set in `IGNITION_DATA_PATH`.

Deleting/recreating the container therefore does not delete the Gateway configuration as long as the host data directory is retained.

The image is deliberately pinned to:

```text
inductiveautomation/ignition:8.3.9
```

A future upgrade should be an explicit repository change to the image tag followed by manually updating the YAML in Portainer's Web editor and redeploying the stack. Back up the Ignition Gateway before changing versions.

## Files

```text
Ignition/
├── docker-compose.yml
├── .env.example
└── README.md
```
