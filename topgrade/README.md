# Scripts for Topgrade

I like [**Topgrade**](https://github.com/topgrade-rs/topgrade) very much and use it for almost everything now.
Until some time ago, I used crates.io to install and run it. However, this had two major issues: A lot of dependencies and a good amount of CPU time required to compile all of it.

So I switched back to the compiled binary.

## What this does

1. Downloads Topgrade from Git
2. ~Unpacks it~ (gonna work on this later)
3. Moves the binary to `/usr/local/bin`
4. Creates a config file with containers and firmware disabled in `~/.config/topgrade.d/disabled.toml`

## deb-install-topgrade-glibc236.sh

Unfortunately, the currently compiled version of Topgrade demands [GLIBC_2.39](https://github.com/topgrade-rs/topgrade), which is not currently shipped on Debian installations (as well as a few other distros).

That's why this script downloads a fork compiled with GLIBC_2.36 from [SteveLauC] (https://github.com/SteveLauC/topgrade/)

This will most likely work on other Debian-based distros as well.
However, Ubuntu for example already ships with the latest GLIBC, so the official Topgrade build will be fine to use there.

## How to use

Run the script with something like:
`curl -fsSL "https://raw.githubusercontent.com/adibue/useful-scripts/refs/heads/main/topgrade/deb-install-topgrade-glibc236.sh" | sudo bash`

## Dependencies

- `wget`
- `sudo` (if not run as root)
