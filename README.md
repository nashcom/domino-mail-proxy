# Domino Mail Proxy Server

The Domino Mail Proxy Server provides dispatching and failover functionality for SMTP, POP3 and IMAP. 
The container image is self contained. It just requires mounts a corporate certificate (or operates with it's own MicroCA).

Options available

- SMTP port 25 with STARTTLS
- SMTP port 465 with TLS
- IMAP port 993 with TLS
- POP3 port 995 with TLS

The NGINX server only supports encryption for the front end channel and is offloading TLS.
The back-end channel must be secured via private network, firewalls and if needed VPN.


See [Configuring NGINX as a Mail Proxy Server](https://docs.nginx.com/nginx/admin-guide/mail-proxy/mail-proxy/) for details.
[Module ngx_mail_ssl_module](http://nginx.org/en/docs/mail/ngx_mail_ssl_module.html) provides detailed information about configuration options.


## Technology used

The server is based on an [Alpine](https://alpinelinux.org/) container running [NGINX](https://nginx.org/).


## How to build the Container Image

Run the following command to build the image

```
./build.sh
```

The resulting image is called **nashcom/dommailproxy:latest** by default

## dommailproxy- Domino Proxy Server Control Script

The **dommailproxy** is a script to provide a single entrypoint for start, stop and maintain the container.

The script can be installed via `./dommailproxy install`

Once configured the server can be started via

```
dommailproxy start
```


### Additional Commands

```
Usage: dommailproxy [Options]

start      start the container
stop       stop the container
bash       start a bash in the container with the standard 'nginx' user
bash root  start a bash with root
rm         remove the container (even when running)

log        show the NGINX server log (container output)
cfg        edit configuration
info       show information about the configuration
```


## Configuration

### Mount points

The following two mount points are supported by the image.
Using a log volume is optional.
The configuraiton can be always re-build from the provided default template nginx.conf file.
But if custom configurations and to preserve certificates, a volume is required.

To simplfy the configuration only the names of the volume has to be specified.
The managenment script automatically turns it into the right volume mounts.


| Volume/Mount       | Description                                                | Inside container            |
| :----------------- | :--------------------------------------------------------- | :-------------------------- |
| CFG_VOL            | Configuration directory for nginx.conf and certs           | /nginx-cfg                  |
| LOG_VOL            | Log directory                                              | /nginx-log                  |


### Configuration settings

The following configuration is used to configure the container itself.

| Setting            | Description                                                | Default                     |
| :----------------- | :--------------------------------------------------------- | :-------------------------- |
| CONTAINER_HOSTNAME | Container Host name                                        | If no host name is specified Linux hostname is used |
| CONTAINER_NAME     | Container name                                             | dommailproxy                |
| CONTAINER_IMAGE    | Container image name. Should not be needed to changed      | nashcom/dommailproxy:latest |
| CONTAINER_NETWORK_NAME | Container network name. By default the container uses the host mode to have access to request IP addresses | host |
| USE_DOCKER         | Override container environment to use Docker if also Podman is installed | Use Podman if installed |


### Container environment settings

The following settings are available to configure functionality of the NGINX Mail Proxy.
Variables are added to an "environment" file and used at container run.

The configuraiton of an NGINX server is generally configured via **/nginx-cfg/nginx.conf**.
A NGINX configuration file itself can't use parameter variables.
Therfore the container image uses a nginx.conf template configuration which is turned into a static **nginx.conf** file to launch NGINX.


| Setting           | Description                                                | Possible values           |
| :---------------- | :--------------------------------------------------------- | :------------------------ |
| MAIL_SERVER_NAME  |  Mail server name used   for ehlo/helo etc.                |                           |
| AUTH_SERVER_NAME  |  Server DNS name for AUTH_HTTP                             |                           |
| AUTH_SERVER_PORT  |  Port for AUTH_HTTP                                        |                           |
| AUTH_URL          |  URL for AUTH_HTTP                                         |                           |
| SECRET_KEY        |  Secret key for AUTH_HTTP                                  |                           |
| SMTP_AUTH         |  Plain SMTP authentication options                         | login plain cram-md5 none |
| SMTP_TLS_AUTH     |  TLS/SSL SMTP authentication options                       | login plain cram-md5 none |
| POP3_TLS_AUTH     |  TLS/SSL POP3 authentication options                       | plain apop cram-md5       |
| IMAP_TLS_AUTH     |  TLS/SSL IMAP authentication options                       | login plain cram-md5      |
| NGINX_LOG_LEVEL   |  NGINX server log level                                    | See list below            |


### NGINX Log Levels

- **debug**  - Useful debugging information to help determine where the problem lies
- **info**   - Informational messages that aren't necessary to read but may be good to know
- **notice** - Something normal happened that is worth noting
- **warn**   - Something unexpected happened, however is not a cause for concern
- **error**  - Something was unsuccessful
- **crit**   - There are problems that need to be critically addressed
- **alert**  - Prompt action is required
- **emerg**  - The system is in an unusable state and requires immediate attention


## TLS/SSL Certificate

The server can use a PEM based certificate and key specified in the configuration volume.
If not certificate is specified the server generates it's own MicroCA and a TLS certificate for the server.
The MicroCA is just a key file and a certificate stored in the configuraiton.
It is only intended for certificate operations for this server.
The root is generated for 10 years. Each certificate is valid for 365 days.

The certificate of the server should be a corporate or official certifiate which needs to be added to the configuration directory.

- custom_key.pem
- custom_cert.pem

If not certificate is specified, a certificate vaild for 365 days is created on every server start.
Information about all certificates is displayed at startup of the server.
The CA root certificate is stored in ca_cert.pem, which is displayed at startup in PEM format if present.


