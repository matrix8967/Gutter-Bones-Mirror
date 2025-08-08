Skeleton Scripts. Nowhere to go but up.

_Always_ lots left `todo`:

-   [x] Adjust .gitignore for to make sure secrets aren't committed.
-   [x] Less hardcoded variables.
-   [x] Suck less @ `ansible-vault`.
-   [ ] Create `roles`.
-   [ ] Finish converting scripts --> Ansible
-   [ ] Convert System Config Copy tasks --> [Templates](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/template_module.html)
-   [ ] SSH-2FA Auth
-   [ ] Create Role/Conf for `caddy.`
-   [ ] Automate `VPN` Setup / Connection(s) and Networking.
-   [ ] Add Fedora/RHEL `se-linux` / `firewall-cmd` + `sshd_conf` steps to the installation.

## Development

- Lint locally:
  - pipx install pre-commit && pre-commit install
  - pre-commit run --all-files

- Run Molecule locally (Docker required):
  - pipx install "molecule-plugins[docker]" molecule ansible pytest testinfra
  - molecule test -s default

- CI runs pre-commit hooks and Molecule tests on branches and MRs.

```
    ⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⣴⣶⣶⣿⣿⣿⣿⣶⣶⣦⣤⣀⠀⠀⠀⠀⠀⠀⠀⠀
    ⠀⠀⠀⠀⠀⢀⣴⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣦⡀⠀⠀⠀⠀⠀
    ⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⠀⠀⠀⠀
    ⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⡀⠀⠀
    ⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣇⠀⠀
    ⠀⢠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⢻⣿⣿⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀
    ⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⠿⠫⢀⣼⣿⣿⣇⠉⠻⢿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀
    ⠀⢸⣿⣿⣿⣿⣭⣉⣉⣁⣠⣴⣾⣿⣿⣿⣿⣷⣤⣠⢀⠉⣉⣾⣿⣿⣿⣿⡇⠀
    ⠀⠸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠇⠀
    ⠀⠀⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠩⠩⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠀⠀
    ⠀⠀⠘⢿⣿⣿⣿⣿⣿⣿⣿⣿⣧⣠⣠⣄⣠⣼⣿⣿⣿⣿⣿⣿⣿⣿⡿⠃⠀⠀
    ⠀⠀⠀⠀⠙⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠋⠀⠀⠀⠀
    ⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⡟⢻⣿⣿⣿⣿⡟⢻⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀
    ⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⡇⢸⣿⣿⣿⣿⡇⢸⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀
    ⠀⠀⠀⠀⠀⠀⠈⠿⣿⣿⡿⠃⠘⢿⣿⣿⡿⠃⠘⢿⣿⣿⠿⠁
```
