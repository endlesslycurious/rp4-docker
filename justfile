# Recipes for the Raspberry Pi 4 Docker host playbook.

# Show available recipes
default:
    @just --list

# Run the playbook against the Pi (pass extra flags via ARGS, e.g. -e "zot_mirror=$(cat .zot_mirror)")
run *ARGS:
    pipenv run ansible-playbook -i inventory.ini site.yml {{ARGS}}

# Check playbook syntax only
syntax:
    pipenv run ansible-playbook -i inventory.ini --syntax-check site.yml

# Lint the playbook
lint:
    pipenv run ansible-lint site.yml

# Run syntax check then lint
check: syntax lint
