# Dockerized mini FDM

This container provides an HAProxy instance with Let's Encrypt certificates generated
at startup, as well as renewed (if necessary) once a week with an internal cron job. It calls Flux API every few munites and updates HAProxy server list for the provided flux `APP_NAME` and `APP_PORT`.

## Usage

### Pull from Github Packages:

```
docker pull alihmahdavi/flux-mini-fdm:latest
```

### Build from Dockerfile:

```
docker build -t flux-mini-fdm:latest .
```

### Run container:

Example of run command (replace APP_NAME, APP_PORT, DOMAIN, EMAIL values and volume paths with yours).
Important Note: Before running the container make sure you've set the DNS records pointing to your server.

```
docker run --name lb -d \
    -e APP_NAME=my-flux-app-name \
    -e APP_PORT=my-flux-app-port \
    -e DOMAIN=my.domain \
    -e EMAIL=my.email@my.domain \
    -e STAGING=false \
    -p 80:80 -p 443:443 -p 8080:8080 \
    alihmahdavi/flux-mini-fdm:latest
```

### Customizing Haproxy

    docker run [...] -v <override-conf-file>:/etc/haproxy/haproxy.cfg alihmahdavi/flux-mini-fdm:latest

Important Note: Use the provided haproxy config file in `conf` folder as the template.

### Renewal cron job

Once a week a cron job checks for expiring certificates with certbot agent and reload haproxy if a certificate is renewed. No container restart needed.


