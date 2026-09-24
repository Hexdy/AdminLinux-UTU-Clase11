# GitHub Copilot — instrucciones del repo

> Copilot lee este archivo automáticamente. Contexto completo en [`AGENTS.md`](../AGENTS.md).

Repo **educativo** de la Clase 11 de *Administración de Sistemas Linux* (UTU) —
tema **SSH y administración remota**. Quien te usa es un **estudiante principiante**;
ayudalo a **aprender**, no solo a que "ande".

Al sugerir código o comandos:

- Respondé en **español rioplatense**, didáctico.
- **Multi-distro**: la VM puede ser Debian/Ubuntu (`apt`, `ssh.service`,
  `openssh-client`), Arch (`pacman`, `sshd.service`, `openssh`) o Fedora (`dnf`,
  `sshd.service`, `openssh-clients`); las tres son válidas. En `playbooks/` el gestor lo
  elige `ansible_os_family`.
- **Security by design**: claves en vez de contraseñas, `PermitRootLogin no`, `~/.ssh`
  en `700` y privadas en `600`, passphrase siempre. Nunca `chmod 777`, contraseñas en
  texto plano ni claves privadas versionadas.
- **Verificar antes de aplicar**: cualquier cambio en `/etc/ssh/` pasa por
  `sudo sshd -t` y se aplica con `reload`, **con otra sesión abierta**.
- No sugieras directivas obsoletas (`Protocol 2`, `UsePrivilegeSeparation`,
  `RSAAuthentication`, `ChallengeResponseAuthentication`).
- Explicá qué hace cada comando antes de proponer que lo ejecute, y no des las
  respuestas del reto hechas.
