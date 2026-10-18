# Recipes for the Raspberry Pi 4 Docker host playbook.

# Show available recipes
default:
    @just --list

# Run the playbook against the Pi. The playbook reads the git-ignored secrets
# (.tailscale_rp4.key, .zot_mirror) itself, so no arguments are needed here.
run:
    pipenv run ansible-playbook -i inventory.ini site.yml

# Check playbook syntax only
syntax:
    pipenv run ansible-playbook -i inventory.ini --syntax-check site.yml

# Lint the playbook
lint:
    pipenv run ansible-lint site.yml

# Run syntax check then lint
check: syntax lint
