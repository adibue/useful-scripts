# !WIP! Plex Library Scanner trigger !WIP!

# UNFINISHED BUSINESS. GUARANTEED TO FAIL!

The [Plex Library Scanner](https://support.plex.tv/articles/201242707-plex-media-scanner-via-command-line/) used to be able to scan for new files by launching it through a CLI.

Unfortunately, this approach is deprecated. Instead, Plex suggests to use [URL Commands](https://support.plex.tv/articles/201638786-plex-media-server-url-commands/) for this purpose.

So what about creating a script asking for essential information, like server url, access token and so on, stores these in a config file for repeated use and creates an easy way to trigger a library scan with just one simple command?

## Wanna do's

- Shell script (bash)
- Swift CLI tool
- Apple Shortcuts tool

## Dependencies

- `curl`

## References

- [Plex Media Server URL Commands](https://support.plex.tv/articles/201638786-plex-media-server-url-commands/)
