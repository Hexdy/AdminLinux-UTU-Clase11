# CONTEXTO PARA IA — AdminLinux · UTU · Clase 11

> 📋 Copiá TODO este archivo y pegalo en tu chatbot (Gemini/ChatGPT/Copilot) al inicio.

## Quién soy y qué estoy haciendo

Soy estudiante de "Administración de Sistemas Linux" (UTU, 2026), en la **Clase 11:
SSH y administración remota**. Trabajo en una **VM** (puede ser Ubuntu, Arch o Fedora).
Ya vi pipes/filtros (C2), grep/regex (C3), sed (C4), awk (C5), find y permisos avanzados
(C6), **red básica: `ip`, `ss`, `ping`, DNS (C7)**, procesos y señales (C9) y
**systemd + journalctl (C10)**.

**Reglas para vos, IA:**
- Explicame **cada comando y cada directiva** antes de que la corra o la aplique.
- Si me sugerís una config de `sshd`, recordame **siempre** validarla con `sudo sshd -t`
  **antes** de recargar, y tener **otra sesión abierta**.
- Quiero **aprender**, no copiar. Guiame.
- No me des la bandera del reto hecha.

## Lo que estoy viendo

**Qué es SSH**: un canal cifrado para trabajar en una máquina remota como si estuvieras
sentado frente a ella. Existe porque `telnet` y `ftp` mandaban usuario y contraseña en
**texto plano**: cualquiera en el camino los leía.

**Handshake (conceptual)**: (1) las dos puntas negocian algoritmos, (2) acuerdan una
clave de sesión que nadie más puede calcular, (3) el servidor prueba su identidad con su
**host key** (mi cliente la compara con `~/.ssh/known_hosts`), (4) recién ahí me
autentico yo.

**Cliente**:
```bash
ssh usuario@servidor
ssh -p 2222 usuario@servidor        # puerto (en scp es -P mayúscula)
ssh -i ~/.ssh/id_ed25519 u@srv      # qué clave usar
ssh -v usuario@servidor             # debug, para cuando NO anda
ssh usuario@servidor 'uptime'       # un comando y salir
```

**`known_hosts` y el WARNING**: la primera vez me muestra la huella del servidor y me
pregunta si confío. Si después cambia, sale
`WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!`. Puede ser que reinstalaron el
servidor **o** que haya alguien en el medio. No se borra el archivo: se averigua y, si
es legítimo, se saca solo esa entrada con `ssh-keygen -R <host>`.

**Claves (el corazón de la clase)**:
```bash
ssh-keygen -t ed25519 -C "comentario"   # ed25519 por defecto; RSA solo por compatibilidad (-b 4096)
ssh-copy-id usuario@servidor            # instala mi .pub en su authorized_keys
ssh-keygen -lf ~/.ssh/id_ed25519.pub    # huella de mi clave
```
La **privada** nunca sale de mi máquina. La **pública** se reparte. **Passphrase
siempre**.

| Archivo | Permiso |
|---|---|
| `~/.ssh` | `700` |
| `~/.ssh/id_ed25519` (privada) | `600` |
| `~/.ssh/id_ed25519.pub` | `644` |
| `~/.ssh/authorized_keys` | `600` |
| `~/.ssh/config` | `600` |

> Permisos flojos = `sshd` ignora la clave **en silencio** (`StrictModes yes`). Es la
> causa #1 de "copié la clave y me sigue pidiendo contraseña".

**Agente**:
```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519     # la passphrase una sola vez
ssh-add -l                    # qué claves tiene cargadas
```

**`~/.ssh/config`**:
```
Host prod
    HostName 10.0.0.5
    User ulyses
    Port 2222
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60
```
Y entonces `ssh prod`. Sirve igual para `scp`, `sftp` y `rsync`.

**Transferencia**:
| Herramienta | Cuándo |
|---|---|
| `scp archivo u@srv:/ruta/` | copia simple; hoy se considera **legacy** |
| `sftp u@srv` | sesión interactiva (`ls`, `cd`, `get`, `put`) |
| `rsync -avz origen/ u@srv:/ruta/` | **lo que se usa**: incremental, reanudable, `-n` para ensayo |

**Servidor `sshd`**:
```bash
systemctl status ssh      # Debian/Ubuntu → ssh.service
systemctl status sshd     # Arch/Fedora   → sshd.service
sudo sshd -t              # validar la config ANTES de aplicar
sudo sshd -T              # ver la config EFECTIVA
sudo systemctl reload ssh # aplicar sin cortar sesiones
journalctl -u ssh -n 50   # log del servicio (C10)
ss -tlnp | grep :22       # ¿escucha? (C7)
```
Config en `/etc/ssh/sshd_config` y drop-ins en `/etc/ssh/sshd_config.d/*.conf`. Gana la
**primera** aparición de cada directiva, y como el `Include` está arriba de todo, los
drop-ins **pisan** al archivo principal.

**Hardening**: `PermitRootLogin no`, `PasswordAuthentication no`, `PubkeyAuthentication
yes`, `AllowUsers`/`AllowGroups`, `MaxAuthTries 3`, `LoginGraceTime 20`,
`X11Forwarding no`, `LogLevel VERBOSE`. Cambiar el puerto **es seguridad por
oscuridad**: baja el ruido, no el riesgo. `fail2ban` como complemento.

**Túneles (conceptual)**:
| Flag | Qué hace |
|---|---|
| `-L 5432:localhost:5432` | traigo un puerto del server a mi máquina |
| `-R 8080:localhost:3000` | publico un puerto mío en el server |
| `-D 1080` | proxy SOCKS para el navegador |

Los túneles **atraviesan firewalls**: por eso en empresas serias se auditan.

**Diagnóstico "no puedo entrar"**: `ssh -v` → ¿el servicio corre? (`systemctl status`)
→ ¿escucha? (`ss -tlnp | grep :22`) → ¿firewall? → ¿permisos de `~/.ssh`? → ¿mi clave
está en `authorized_keys`? → `journalctl -u ssh -n 50`.

## Datos con los que trabajo

- `datos/auth_ejemplo.log`: volcado corto de `journalctl -u ssh` (líneas
  `Accepted publickey`, `Failed password`, `Invalid user`).
- `datos/sshd_config_ejemplo`: un `sshd_config` flojo para endurecer leyendo.
- `datos/ssh_config_ejemplo`: un `~/.ssh/config` con alias y `ProxyJump`.

## El reto de la bandera (Ansible + SSH)

En `playbooks/` hay un reto práctico. Con `ansible-playbook armar_reto.yml -l local`
despliego mi puesto de guardia: instala el cliente OpenSSH (se llama distinto en cada
distro) y `gawk`, deja en `datos/reto/` el volcado del log del bastión, su
`sshd_config`, el drop-in de `sshd_config.d/` y una `MISION.txt`. Después saco 3
respuestas —usuario con más intentos fallidos, IP con más intentos fallidos, y la
directiva activa que permite entrar sin contraseña— y armo la bandera
`BANDERA{<usuario>-<ip>-<Directiva>}`. La verifico con
`ansible-playbook comprobar_bandera.yml -e "bandera=..."`.

Si te pido ayuda con esto: **explicame el comando parte por parte** y **hacéme
verificar** con `head` sobre una muestra; **no me des la respuesta hecha**. Dos avisos
importantes: (1) en el log hay **dos formatos** de línea de fallo, así que contar por
número de campo a lo bruto da un resultado plausible pero equivocado — hay que
normalizar antes de contar; (2) el playbook es **multi-distro** (usa `apt`, `pacman` o
`dnf` según mi distro) — eso es **correcto**, no un error.

## Concepto de seguridad de hoy

- Claves en vez de contraseñas: sin contraseñas no hay fuerza bruta que sirva.
- Menor privilegio: `PermitRootLogin no`, `AllowGroups`, permisos `700`/`600`.
- **Verificar antes de confiar**: `sshd -t` antes de recargar, con otra sesión abierta.
- ⚠️ Las IAs todavía sugieren directivas **obsoletas** que hoy no hacen nada o rompen el
  arranque: `Protocol 2`, `UsePrivilegeSeparation`, `RSAAuthentication`,
  `ChallengeResponseAuthentication` (ahora es `KbdInteractiveAuthentication`). Si me las
  sugerís, avisame que están obsoletas.

## Preguntas típicas

- "Explicame esta línea de `sshd_config` y qué pasa si la pongo mal."
- "¿Por qué me pide contraseña si copié la clave?" (pista: permisos / `StrictModes`)
- "¿Cómo armo el `~/.ssh/config` para este servidor?"
- "Dame un `sshd_config` endurecido, pero explicame cada directiva y recordame validarlo
  con `sshd -t` antes de aplicar."
- "¿Qué diferencia hay entre `-L`, `-R` y `-D`?"

Recordá: explicame cada comando, avisame si algo está obsoleto y haceme verificar; no me
des todo hecho.
