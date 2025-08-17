#!/bin/bash -i

## MARK: Bootstrapping
# Source config library
source "./libs/config.shlib";
printf -- "%s\n" "$(config_get PLEX_SERVER_URL)";
printf -- "%s\n" "$(config_get PLEX_SERVER_PORT)";
printf -- "%s\n" "$(config_get PLEX_TOKEN)";