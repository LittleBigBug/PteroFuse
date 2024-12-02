# PteroFuse

File de-duplication, tiered git-based game server management for [Pterodactyl](https://pterodactyl.io)

## Features

- De-duplicated base server installs
  - Have more than one of the same kind of game server?
    PteroFuse can install the base game server once and apply modifications (like the server's respective configurations)
    on a per-server basis, saving storage\
- Git-based management
  - Track and backup your configuration files in a git repository
  - Easily deploy configuration or addon changes en-mass to multiple servers at once
- "Layered" fused file system
  - Using [unionfs-fuse](https://github.com/rpodgorny/unionfs-fuse), PteroFuse merges several folders into one virtual folder. (/home/container)
    - Changes/writes to the /home/container folder will be written to a top-level layer unique for each individual server. 
  - Can use multiple git repositories too
  - Example:
    - Base Counter-Strike: Source server install from SteamCMD
    - git repository with base configs for surf servers
    - git repository with extra configs for different sub-variations of surf servers

## Installation

Before you get started, you'll need:

- [Pterodactyl](https://pterodactyl.io/project/introduction.html) installed with [blueprint](https://blueprint.rip)
  (Check out: [Docker](https://github.com/BlueprintFramework/docker))
- [PteroFuse wings fork](https://github.com/LittleBigBug/ptero-wings) installed

First, download the latest release from [releases](https://github.com/LittleBigBug/PteroFuse/releases) tab.

Upload `pterofuse.blueprint` to your panel's `blueprint_extensions` folder. Then run:

```sh
blueprint -i pterofuse
```

In your admin panel within Pterodactyl, import all the desired PteroFuse game eggs `pterofuse-*-egg.json`

You're done! PteroFuse is installed and ready to go.