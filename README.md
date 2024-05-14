# github-app-auth-buildkite-plugin

Combines a Git credential helper with a [`chinmina-bridge` helper
agent][chinmina-bridge] to allow Buildkite agents securely authorize Github
repository access.

The plugin contains a Git credential helper, enabled for the current step via an
`environment` hook.

The credential helper calls `chinmina-bridge` when credentials for a GitHub
repository are requested, supplying the result to Git in its expected format.

> [!IMPORTANT]
>
> In order for this plugin to work for a whole pipeline, it must be enabled on
> every step. **This includes any steps configured in the [pipeline
> configuration](https://buildkite.com/docs/pipelines/defining-steps).**
>
> Alternatively, the plugin may be enabled globally by the agent: see
> instructions below.

## Example

Add the following to your `pipeline.yml`:

```yml
steps:
  - command: ls
    plugins:
      - jamestelfer/github-app-auth#v1.0.2:
          vendor-url: "https://chinmina-bridge-url"
          audience: "github-app-auth:your-github-organization"
```

## Configuration

### `vendor-url` (Required, string)

The URL of the [`chinmina-bridge`][chinmina-bridge] helper agent that vends a
token for a pipeline. This is a separate HTTP service that must accessible to
your Buildkite agents.

### `audience` (string)

**Default:** `github-app-auth:default`

The value of the `aud` claim of the OIDC JWT that will be sent to
[`chinmina-bridge`][chinmina-bridge]. This must correlate with the value
configured in the `chinmina-bridge` settings.

A recommendation: `github-app-auth:your-github-organization`. This is specific
to the purpose of the token, and also scoped to the GitHub organization that
tokens will be vended for. `chinmina-bridge`'s GitHub app is configured for a
particular GitHub organization/user, so if you have multiple organizations,
multiple agents will need to be running.

## Global agent configuration

In order to enable the plugin automatically, consider changing the Buildkite
agent configuration such that the plugin is installed and enabled by default.

> [!NOTE]
>
> Credential helpers are only used by Git for HTTP, not for SSH. This
> configuration does not change behaviour for SSH connections.

One way to do this is to clone the plugin when the agent is bootstrapped, then
call the plugin's environment hook directly from the agent's environment hook.

The two scripts below accomplish this:

### Agent `bootstrap` hook additions

```bash
#!/usr/bin/env bash

echo "installing Github credential plugin"

plugin_repo="https://github.com/jamestelfer/github-app-auth-buildkite-plugin.git"
plugin_version="v1.0.1"
plugin_dir="/buildkite/plugins/github-app-auth-buildkite-plugin"

[[ -d "${plugin_dir}" ]] && rm -rf "${plugin_dir}"

GIT_CONFIG_COUNT=1 \
GIT_CONFIG_KEY_0=advice.detachedHead \
GIT_CONFIG_VALUE_0=false \
  git clone --depth 1 --single-branch --no-tags \
    --branch "${plugin_version}" -- \
    "${plugin_repo}" "${plugin_dir}"
```

### Agent `environment` hook additions

```bash
#
# executing this script from your infrastructure's environment agent hook will
# configure Github App Auth for every build
#
# Changing the parameters supplied will be necessary to ensure that agents can
# connect to the service and include the correct audience.
#
BUILDKITE_PLUGIN_GITHUB_APP_AUTH_VENDOR_URL="https://chinmina-bridge-url" \
BUILDKITE_PLUGIN_GITHUB_APP_AUTH_AUDIENCE="github-app-auth:your-github-org" \
    source /buildkite/plugins/github-app-auth-buildkite-plugin/hooks/environment
```

## Developing

To run the tests:

```shell
docker-compose run --rm tests
```

## Contributing

1. Fork the repo
2. Make the changes
3. Run the tests
4. Commit and push your changes
5. Send a pull request


[chinmina-bridge]: https://github.com/jamestelfer/chinmina-bridge
