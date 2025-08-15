# Scripts for Topgrade

I like [**Topgrade**](https://github.com/topgrade-rs/topgrade) very much and use it for almost everything now.
Until some time ago, I used crates.io to install and run it. However, this had two major issues: A lot of dependencies and a good amount of CPU time required to compile all of it.

So I switched back to the compiled binary.

## What this does

1. Downloads Topgrade from Git
2. Unpacks it
3. Moves the binary to `/usr/local/bin`
4. Creates a config file with containers and firmware disabled in `~/.config/topgrade.d/disabled.toml`

## How to use

Run the script with something like:
`curl -fsSL "https://abu.li/tg-deb" | sudo bash`

## Dependencies

- `curl`
- `wget`
- `sudo` (if not run as root)
