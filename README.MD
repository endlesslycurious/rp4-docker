# Docker + Dozzle on Raspberry Pi 4

This repo will set up and configure a [Raspberry Pi 4](https://www.raspberrypi.com/products/raspberry-pi-4-model-b/) as a Docker host, with [Docker Compose](https://docs.docker.com/compose/) for deployments and [Dozzle](https://dozzle.dev) as a live container log dashboard.
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
 1. Run the command `ansible-playbook -i inventory.ini site.yml` and wait for it to complete.
    - To also join the Pi to your Tailscale tailnet, pass an auth key (kept out of the repo):
      `ansible-playbook -i inventory.ini site.yml -e "tailscale_auth_key=$(cat .tailscale_rp4.key)"`.
 2. Test Dozzle by opening `RP4.local` (port 80) in a web browser to view container logs.

 ## Tailscale (optional remote access)
 1. Install the client on your Mac: `brew install tailscale` and sign in to your tailnet.
 2. Create an auth key in the Tailscale admin console and save it to `.tailscale_rp4.key` (git-ignored).
 3. Run the playbook with the key (see above), or on the Pi run `sudo tailscale up`.
 4. Reach services over the tailnet using the Pi's Tailscale name/IP, e.g. `http://rp4`.

  You should now be good to go!
