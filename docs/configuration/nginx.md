# Nginx Configuration

Dokku uses nginx as its server for routing requests to specific applications. By default, access and error logs are written for each app to `/var/log/nginx/${APP}-access.log` and `/var/log/nginx/${APP}-error.log` respectively

```
nginx:access-logs <app> [-t]             # Show the nginx access logs for an application (-t follows)
nginx:error-logs <app> [-t]              # Show the nginx error logs for an application (-t follows)
nginx:report [<app>] [<flag>]            # Displays a nginx report for one or more apps
nginx:set <app> <property> (<value>)     # Set or clear an nginx property for an app
nginx:show-config <app>                  # Display app nginx config
nginx:validate-config [<app>] [--clean]  # Validates and optionally cleans up invalid nginx configurations
```

## Usage

### Request Proxying

By default, the `web` process is the only process proxied by the nginx proxy implementation. Proxying to other process types may be handled by a custom `nginx.conf.sigil` file, as generally described [below](/docs/configuration/nginx.md#customizing-the-nginx-configuration)

Nginx will proxy the requests in a [round-robin balancing fashion](http://nginx.org/en/docs/http/ngx_http_upstream_module.html#upstream) to the different deployed (scaled) containers running the `web` proctype. This way, the host's resources can be fully leveraged for single-threaded applications (e.g. `dokku ps:scale node-js-app web=4` on a 4-core machine)

### Binding to specific addresses

> New as of 0.19.2

By default, nginx will listen to all interfaces (`[::]` for IPv6, `0.0.0.0` for IPv4) when proxying requests to applications. This may be changed using the `bind-address-ipv4` and `bind-address-ipv6` properties. This is useful in cases where the proxying should be internal to a network or if there are multiple network interfaces that should respond with different content.

```shell
dokku nginx:set node-js-app bind-address-ipv4 127.0.0.1
dokku nginx:set node-js-app bind-address-ipv6 ::1
```

This may be reverted by setting an empty bind address.

```shell
dokku nginx:set node-js-app bind-address-ipv4
dokku nginx:set node-js-app bind-address-ipv6
```

> Warning: Validation is not performed on either value.

Users with apps that contain a custom `nginx.conf.sigil` file will need to modify the files to respect the new `NGINX_BIND_ADDRESS_IPV4` and `NGINX_BIND_ADDRESS_IPV6` variables.

### HSTS Header

> New as of 0.20.0

If SSL certificates are present, HSTS will be automatically enabled. It can be toggled via `nginx:set`:

```shell
dokku nginx:set node-js-app hsts true
dokku nginx:set node-js-app hsts false
```

The following options are also available via the `nginx:set` command:

- `hsts` (type: boolean, default: `true`): Enables or disables HSTS for your application.
- `hsts-include-subdomains` (type: boolean, default: `true`): Tells the browser that the HSTS policy also applies to all subdomains of the current domain.
- `hsts-max-age` (type: integer, default: `15724800`): Time in seconds to cache HSTS configuration.
- `hsts-preload` (type: boolean, default: `false`): Tells most major web browsers to include the domain in their HSTS preload lists.

Beware that if you enable the header and a subsequent deploy of your application results in an HTTP deploy (for whatever reason), the way the header works means that a browser will not attempt to request the HTTP version of your site if the HTTPS version fails until the max-age is reached.

### Checking access logs

You may check nginx access logs via the `nginx:access-logs` command. This assumes that app access logs are being stored in `/var/log/nginx/$APP-access.log`, as is the default in the generated `nginx.conf`.

```shell
dokku nginx:access-logs node-js-app
```

You may also follow the logs by specifying the `-t` flag.

```shell
dokku nginx:access-logs node-js-app -t
```

### Checking error logs

You may check nginx error logs via the `nginx:access-logs` command. This assumes that app error logs are being stored in `/var/log/nginx/$APP-error.log`, as is the default in the generated `nginx.conf`.

```shell
dokku nginx:error-logs node-js-app
```

You may also follow the logs by specifying the `-t` flag.

```shell
dokku nginx:error-logs node-js-app -t
```

### Changing log path

> New as of 0.20.1

The path to where log files are stored can be changed by calling the `nginx:set` command with the following options:

- `access-log-path` (type: string, default: `${NGINX_LOG_ROOT}/${APP}-access.log`): Log path for nginx access logs
- `error-log-path` (type: string, default: `${NGINX_LOG_ROOT}/${APP}-error.log`): Log path for nginx error logs

The defaults should not be changed without verifying that the paths will be writeable by nginx. However, this setting is useful for enabling or disabling logging by setting the values to `off`.

```shell
dokku nginx:set node-js-app access-log-path off
dokku nginx:set node-js-app error-log-path off
```

The default value may be set by passing an empty value for the option:

```shell
dokku nginx:set node-js-app access-log-path
dokku nginx:set node-js-app error-log-path
```

In all cases, the nginx config must be regenerated after setting the above values.

### Changing log format

> New as of 0.22.0

The format of the access log can be changed by calling the `nginx:set` command as follows:

```shell
dokku nginx:set node-js-app access-log-format custom
```

### Specifying a read timeout

> New as of 0.21.0

When proxying requests to your applications, it may be useful to specify a proxy read timeout. This can be done via the `nginx:set` command as follows:

```shell
dokku nginx:set node-js-app proxy-read-timeout 120s
```

The default value is `60s`, and all numeric values _must_ have a trailing time value specified (`s` for seconds, `m` for minutes).

The default value may be set by passing an empty value for the option:

```shell
dokku nginx:set node-js-app proxy-read-timeout
```

In all cases, the nginx config must be regenerated after setting the above value.

### Specifying a custom client_max_body_size

> New as of 0.23.0

Users can override the default `client_max_body_size` value - which limits file uploads - via `nginx:set`. Changing this value will only apply to every `server` stanza of the default `nginx.conf.sigil`; users of custom `nginx.conf.sigil` files must update their templates to support the new value.

```shell
dokku nginx:set node-js-app client-max-body-size 50m
```

The default value is empty string, which will result in nginx falling back to any configured, higher-level defaults (or `1m` if unconfigued. all numeric values _must_ have a trailing time value specified (`k` for kilobytes, `m` for megabytes).

The default value may be set by passing an empty value for the option:

```shell
dokku nginx:set node-js-app client-max-body-size
```

In all cases, the nginx config must be regenerated after setting the above value.

Changing this value when using the php buildpack (or any other buildpack that uses an intermediary server) will require changing the value in the server config shipped with that buildpack. Consult your buildpack documentation for further details.

### Showing the nginx config

For debugging purposes, it may be useful to show the nginx config. This can be achieved via the `nginx:show-config` command.

```shell
dokku nginx:show-config node-js-app
```

### Validating nginx configs

It may be desired to validate an nginx config outside of the deployment process. To do so, run the `nginx:validate-config` command. With no arguments, this will validate all app nginx configs, one at a time. A minimal wrapper nginx config is generated for each app's nginx config, upon which `nginx -t` will be run.

```shell
dokku nginx:validate-config
```

As app nginx configs are actually executed within a shared context, it is possible for an individual config to be invalid when being validated standalone but _also_ be valid within the global server context. As such, the exit code for the `nginx:validate-config` command is the exit code of `nginx -t` against the server's real nginx config.

The `nginx:validate-config` command also takes an optional `--clean` flag. If specified, invalid nginx configs will be removed.

> Warning: Invalid app nginx config's will be removed _even if_ the config is valid in the global server context.

```shell
dokku nginx:validate-config --clean
```

The `--clean` flag may also be specified for a given app:

```shell
dokku nginx:validate-config node-js-app --clean
```

### Customizing the nginx configuration

> New as of 0.5.0

Dokku uses a templating library by the name of [sigil](https://github.com/gliderlabs/sigil) to generate nginx configuration for each app. You may also provide a custom template for your application as follows:

- Copy the following example template to a file named `nginx.conf.sigil` and either:
  - If using a buildpack application, you __must__ check it into the root of your app repo.
  - If using a dockerfile or docker image for deploys, either:
    - If `WORKDIR` is specified, add the file to the `WORKDIR` specified in the last Dockerfile stage  (example: `WORKDIR /app` and `ADD nginx.conf.sigil /app`).
    - If no `WORKDIR` is specified, add the file to the root (`/`) of the docker image (example: `ADD nginx.conf.sigil /`).

> When using a custom `nginx.conf.sigil` file, depending upon your application configuration, you *may* be exposing the file externally. As this file is extracted before the container is run, you can, safely delete it in a custom `entrypoint.sh` configured in a Dockerfile `ENTRYPOINT`.

> The default template is available [here](https://github.com/dokku/dokku/blob/master/plugins/nginx-vhosts/templates/nginx.conf.sigil), and can be used as a guide for your own, custom `nginx.conf.sigil` file. Please refer to the appropriate template file version for your Dokku version.

While enabled by default, using a custom nginx config can be disabled via `nginx:set`. This may be useful in cases where you do not want to allow users to override any higher-level customization of app nginx config.

```shell
# enable fetching custom config (default)
dokku nginx:set node-js-app disable-custom-config false

# disable fetching custom config
dokku nginx:set node-js-app disable-custom-config true
```

Unsetting this value is the same as enabling custom nginx config usage.


#### Available template variables

```
{{ .APP }}                          Application name
{{ .APP_SSL_PATH }}                 Path to SSL certificate and key
{{ .DOKKU_ROOT }}                   Global Dokku root directory (ex: app dir would be `{{ .DOKKU_ROOT }}/{{ .APP }}`)
{{ .PROXY_PORT }}                   Non-SSL nginx listener port (same as `DOKKU_PROXY_PORT` config var)
{{ .PROXY_SSL_PORT }}               SSL nginx listener port (same as `DOKKU_PROXY_SSL_PORT` config var)
{{ .NOSSL_SERVER_NAME }}            List of non-SSL VHOSTS
{{ .PROXY_PORT_MAP }}               List of port mappings (same as `DOKKU_PROXY_PORT_MAP` config var)
{{ .PROXY_UPSTREAM_PORTS }}         List of configured upstream ports (derived from `DOKKU_PROXY_PORT_MAP` config var)
{{ .RAW_TCP_PORTS }}                List of exposed tcp ports as defined by Dockerfile `EXPOSE` directive (**Dockerfile apps only**)
{{ .SSL_INUSE }}                    Boolean set when an app is SSL-enabled
{{ .SSL_SERVER_NAME }}              List of SSL VHOSTS
```

Finally, each process type has it's network listeners - a list of IP:PORT pairs for the respective app containers - exposed via an `.DOKKU_APP_${PROCESS_TYPE}_LISTENERS` variable - the `PROCESS_TYPE` will be upper-cased with hyphens transformed into underscores. Users can use the new variables to expose non-web processes via the nginx proxy.

> Note: Application config variables are available for use in custom templates. To do so, use the form of `{{ var "FOO" }}` to access a variable named `FOO`.

#### Customizing via configuration files included by the default templates

The default nginx.conf template will include everything from your apps `nginx.conf.d/` subdirectory in the main `server {}` block (see above):

```
include {{ .DOKKU_ROOT }}/{{ .APP }}/nginx.conf.d/*.conf;
```

That means you can put additional configuration in separate files. To increase the client request header timeout, the following can be performed:

```shell
mkdir /home/dokku/node-js-app/nginx.conf.d/
echo 'client_header_timeout 50s;' > /home/dokku/node-js-app/nginx.conf.d/timeout.conf
chown dokku:dokku /home/dokku/node-js-app/nginx.conf.d/upload.conf
service nginx reload
```

The example above uses additional configuration files directly on the Dokku host. Unlike the `nginx.conf.sigil` file, these additional files will not be copied over from your application repo, and thus need to be placed in the `/home/dokku/node-js-app/nginx.conf.d/` directory manually.

For PHP Buildpack users, you will also need to provide a `Procfile` and an accompanying `nginx.conf` file to customize the nginx config *within* the container. The following are example contents for your `Procfile`

    web: vendor/bin/heroku-php-nginx -C nginx.conf -i php.ini php/

Your `nginx.conf` file - not to be confused with Dokku's `nginx.conf.sigil` - would also need to be configured as shown in this example:

    client_header_timeout 50s;
    location / {
        index index.php;
        try_files $uri $uri/ /index.php$is_args$args;
    }

Please adjust the `Procfile` and `nginx.conf` file as appropriate.

### Custom Error Pages

By default, Dokku provides custom error pages for the following three categories of errors:

- 4xx: For all non-404 errors with a 4xx response code.
- 404: For "404 Not Found" errors.
- 5xx: For all 5xx error responses

These are provided as an alternative to the generic Nginx error page, are shared for _all_ applications, and their contents are located on disk at `/var/lib/dokku/data/nginx-vhosts/dokku-errors`. To customize them for a specific app, create a custom `nginx.conf.sigil` as described above and change the paths to point elsewhere.

### Default site

By default, Dokku will route any received request with an unknown HOST header value to the lexicographically first site in the nginx config stack. If this is not the desired behavior, you may want to add the following configuration to the global nginx configuration.

Create the file at `/etc/nginx/conf.d/00-default-vhost.conf`:

```nginx
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;
    access_log off;
    return 410;
}

# To handle HTTPS requests, you can uncomment the following section.
#
# Please note that in order to let this work as expected, you need a valid
# SSL certificate for any domains being served. Browsers will show SSL
# errors in all other cases.
#
# Note that the key and certificate files in the below example need to
# be copied into /etc/nginx/ssl/ folder.
#
# server {
#     listen 443 ssl;
#     listen [::]:443 ssl;
#     server_name _;
#     ssl_certificate /etc/nginx/ssl/cert.crt;
#     ssl_certificate_key /etc/nginx/ssl/cert.key;
#     access_log off;
#     return 410;
# }
```

Make sure to reload nginx after creating this file by running `service nginx reload`.

This will catch all unknown HOST header values and return a `410 Gone` response. You can replace the `return 410;` with `return 444;` which will cause nginx to not respond to requests that do not match known domains (connection refused).

The configuration file must be loaded before `/etc/nginx/conf.d/dokku.conf`, so it can not be arranged as a vhost in `/etc/nginx/sites-enabled` that is only processed afterwards.

Alternatively, you may push an app to your Dokku host with a name like "00-default". As long as it lists first in `ls /home/dokku/*/nginx.conf | head`, it will be used as the default nginx vhost.

## Other

### Domains plugin

See the [domain configuration documentation](/docs/configuration/domains.md) for more information on how to configure domains for your app.

### Customizing hostnames

See the [customizing hostnames documentation](/docs/configuration/domains.md#customizing-hostnames) for more information on how to configure domains for your app.

### Disabling VHOSTS

See the [disabling vhosts documentation](/docs/configuration/domains.md#disabling-vhosts) for more information on how to disable domain usage for your app.

### Running behind a load balancer

See the [load balancer documentation](/docs/configuration/ssl.md#running-behind-a-load-balancer) for more information on how to configure your nginx config for running behind a network load balancer.

### SSL Configuration

See the [ssl documentation](/docs/configuration/ssl.md) for more information on how to configure SSL certificates for your application.

### Disabling Nginx

See the [proxy documentation](/docs/advanced-usage/proxy-management.md) for more information on how to disable nginx as the proxy implementation for your app.

### Managing Proxy Port mappings

See the [proxy documentation](/docs/advanced-usage/proxy-management.md#proxy-port-mapping) for more information on how to manage ports proxied for your app.

### Regenerating nginx config

See the [proxy documentation](/docs/advanced-usage/proxy-management.md#regenerating-proxy-config) for more information on how to rebuild the nginx proxy configuration for your app.
