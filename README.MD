# Docker + Dozzle on Raspberry Pi 4

This repo will set up and configure a [Raspberry Pi 4](https://www.raspberrypi.com/products/raspberry-pi-4-model-b/) (4 GB) as a Docker host, with [Docker Compose](https://docs.docker.com/compose/) for deployments and [Dozzle](https://dozzle.dev) as a live container log dashboard.
- Basic security: password login disabled, [UFW](https://help.ubuntu.com/community/UFW) firewall and [Fail2Ban](https://github.com/fail2ban/fail2ban) login guard.
- Updates: security + stable updates applied automatically.
- Instructions assume your using a Mac with [HomeBrew](https://brew.sh) installed.

## Image Creation

### Requirements
1. Micro SD card, I used a 32 GB USH 1 card.
2. Offical raspberry pi imager: `brew install raspberry-pi-imager`.
3. SSH public key e.g `id_rsa.pub` in `~/.ssh` folder.

### Imaging configuration
1. Launch the imager app.
2. Select `Raspberry Pi OS Lite (64-bit)` as the OS.
3. Select your MicroSD card as the storage.
4. Click the gear icon for Advanced Settings:
 - Enable SSH (use public key only).
 - Paste in your public key if it doesn't auto-populate.
 - Set the hostname, I used `RP4.local`.
 - Set username and password, I used `daniel` as username and a temp password.
 5. Click *Write* to flash the image.
 6. Remove MicroSD on completion.

 ## First boot
 1. Insert MicroSD into Raspberry Pi and attach power.
 2. Ping the hostname until it responds e.g. `ping RP4.local`.
 3. Once it responds try to ssh into it `ssh daniel@RP4.local`.
 4. `exit` from SSH session.

 ## Ansible setup
 1. Install Python 3.13 e.g. `brew install python@3.13`.
 2. Install PipEnv via Pip3 e.g. `pip install pipenv`.
 3. Run `pipenv sync` command to setup Ansible, if you want ansible-lint too run with `-d` or `--dev` option.
 4. Run `pipenv shell` command to enter managed shell with ansible in path.
 5. Test ansible can connect with `ansible all -i inventory.ini -m ping`.

 ## Running the Playbook.
 1. Run `just run` (or `just` for the recipe list) and wait for it to complete. The playbook itself reads the git-ignored secrets — `.tailscale_rp4.key` and `.zot_mirror` — from the repo root on the control node, so `just run` takes no arguments and nothing sensitive touches the command line or shell history. Only the files that exist are used; omit either to skip that optional step.
     - Without `just`, the equivalent is `ansible-playbook -i inventory.ini site.yml`.
 2. Test Dozzle by opening `RP4.local` (port 80) in a web browser to view container logs.

 ## CLI tooling (mise + personal configs)
 The playbook provisions command-line tools from the personal [configs](https://github.com/endlesslycurious/configs) repo rather than installing them individually via apt:
 - It clones the repo to `~/configs` (as the login user, with submodules) and runs its `setup.sh`, which installs [mise](https://mise.jdx.dev), symlinks config files into `~/.config`, and runs `mise bootstrap` to install the declared CLI tools (`btop`, `fzf`, `ripgrep`, `tealdeer`, `eza`, `bat`, `fd`, `just`, `yq`, and more).
 - mise installs these to `~/.local/bin` and activates shims on the login shell's `PATH`, so they shadow any system copies.
 - `git`, `ca-certificates`, `curl`, and `gnupg` remain apt-installed as bootstrap prerequisites (they are needed before mise exists and are also declared in mise's `[bootstrap.packages]`); `rsync` is apt-installed as it isn't provided by mise.
 - To update the tools later, run `./update.sh` inside `~/configs` (`mise self-update && mise upgrade && mise bootstrap packages upgrade`). Re-running the playbook also pulls the latest repo and re-runs `setup.sh`.

 ## Memory stats in Dozzle (Raspberry Pi only)
 By default the Raspberry Pi kernel boots with its memory cgroup **disabled** (the device tree passes `cgroup_disable=memory` to save overhead on low-RAM boards). Without it, the Docker API reports no per-container memory, so Dozzle's memory graph stays empty (the same reason `docker stats` shows `0`).
 The playbook fixes this automatically: it appends `cgroup_enable=memory` to the single-line `cmdline.txt` and **reboots the Pi once** to apply it (the flag must come *after* the DTB args, which appending guarantees). After that first reboot the memory controller is live and Dozzle shows memory for every container.
 Notes:
 - This is just accounting here — it only starts *enforcing* limits if you later set `mem_limit` on a container. No container limits are set, so there is no new kill/OOM behaviour.
 - The Dozzle FAQ's advice (`/boot/cmdline.txt` plus `cgroup_enable=cpuset cgroup_memory=1`) is dated; on current Bookworm/Trixie the file is `/boot/firmware/cmdline.txt` and `cgroup_enable=memory` alone is enough. Revert by removing the token from `cmdline.txt` and rebooting.
 - Verify after a run: `cat /sys/fs/cgroup/cgroup.controllers` lists `memory`, and `docker info` no longer prints `WARNING: No memory limit support`.

 ## Tailscale (optional remote access)
 1. Install the client on your Mac: `brew install tailscale` and sign in to your tailnet.
 2. Create an auth key in the Tailscale admin console and save it to `.tailscale_rp4.key` (git-ignored).
 3. Run the playbook with the key (see above), or on the Pi run `sudo tailscale up`.
  4. Reach services over the tailnet using the Pi's Tailscale name/IP, e.g. `http://rp4`.

  ## Zot pull-through cache (optional registry mirror)
  1. Run a [Zot](https://zot.dev) instance and note its address as `host:port` (no scheme), e.g. `zot.rp4.ts.net:5000`.
  2. Save that value to `.zot_mirror` (git-ignored).
  3. Run the playbook with it (see above). This adds `registry-mirrors: ["http://<host:port>"]` to `/etc/docker/daemon.json`.
  4. Because the cache serves plain HTTP, the same `daemon_extra` also registers it under `insecure-registries`; without that, Docker fails TLS on the mirror and silently falls back to Docker Hub. If you put TLS on Zot, use an `https://` value here instead and drop the `insecure-registries` entry.

   You should now be good to go!
