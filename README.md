# github-app-auth-buildkite-plugin

Combines a Git credential helper with a separate helper agent to allow Buildkite agents securely authorize Github repository access.

## Example

Add the following to your `pipeline.yml`:

```yml
steps:
  - command: ls
    plugins:
      - jamestelfer/github-app-auth#v0.1.0:
          vendor-url: "https://your-vendor-agent"
          audience: "github-app-auth:your-buildkite-organization"
```

## Configuration

### `vendor-url` (Required, string)

The URL of the helper agent that vends a token for a pipeline. This is a
separate (as yet unreleased) agent that is accessible to your Buildkite agents.

### `audience` (string)

**Default:** `github-app-auth:default`

The value of the `aud` claim of the OIDC JWT that will be sent to the helper
agent. This must correlate with the value configured in the vendor agent
settings.

A recommendation: `github-app-auth:your-github-organization`. This is specific
to the purpose of the token, and also scoped to the GitHub organization that
tokens will be vended for. The agent's GitHub app is configured for a particular
GitHub organization/user, so if you have multiple organizations, multiple agents
will need to be running.

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
