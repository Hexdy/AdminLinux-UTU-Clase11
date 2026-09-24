# Playbooks de Ansible — AdminLinux Clase 11 (SSH + el reto de la bandera)

Un **escenario práctico de sysadmin**: desplegás un playbook de Ansible que te arma
el puesto de guardia (instala el cliente OpenSSH y `gawk`, deja la evidencia del
servidor, prepara la misión) y después, leyendo el **log de `sshd`** y su
**configuración**, sacás 3 respuestas. Con las 3 armás una **bandera** y la
verificás con otro playbook. Aprendés Ansible **haciendo**, y SSH resolviendo un
incidente real (no ejercicios de juguete).

> 🐧 Con una sola VM alcanza: todo corre contra `localhost` (grupo `[local]`).
> No es hacking: es el laburo normal de revisar por qué un bastión comió escaneos
> toda la noche y si la config estaba como creíamos.

> 🔒 **Lo que estos playbooks NO hacen, a propósito**: no generan claves, no tocan
> tu `~/.ssh`, no instalan ni arrancan `sshd`, no abren puertos. Solo dejan archivos
> para que los leas. Podés correrlos tranquilo en tu VM.

## Paso 0 — ¿Tenés todo? (te dice qué falta y cómo instalarlo)

```bash
cd playbooks
bash comprobar_requisitos.sh
```

Detecta tu distro y, si falta algo (Ansible, Python, cliente `ssh`, `gawk`), te da
el comando exacto para **apt**, **pacman** o **dnf**. De paso te mira los permisos
de `~/.ssh` (la causa #1 de "no me deja entrar").

## Paso 1 — Desplegá el reto (armá el puesto de guardia)

```bash
# Simular primero (no toca nada, buena costumbre):
ansible-playbook armar_reto.yml -l local --check --diff

# Aplicar de verdad (deja datos/reto/ listo):
ansible-playbook armar_reto.yml -l local
#   ↳ si al instalar los paquetes te pide contraseña de sudo, agregá  -K
```

Atajo que hace el preflight + el armado:

```bash
bash correr.sh
```

Esto deja tu misión en `../datos/reto/MISION.txt`. Leela:

```bash
cat ../datos/reto/MISION.txt
```

## Paso 2 — Sacá las 3 respuestas del incidente

Tu jefa te pide (todo sobre `datos/reto/`):

1. **R1** — contra **qué usuario** se hicieron más intentos **fallidos**.
2. **R2** — desde **qué IP** salieron más intentos **fallidos**.
3. **R3** — qué **directiva** de la config **que quedó activa** permite entrar
   **sin contraseña** (tal cual se escribe, con sus mayúsculas).

Armá la bandera con el formato exacto: `BANDERA{<usuario>-<ip>-<Directiva>}`.

> 💡 Los comandos exactos NO están acá a propósito: la idea es que los armes vos.
> Tenés todas las piezas entre esta clase y las 2–4 (pipes, `grep`, `awk`,
> `sort | uniq -c | sort -rn`).
>
> ⚠️ **Trampa a propósito**: los fallos aparecen en **dos formatos de línea**
> distintos. Contar por número de campo a lo bruto te da un número que *parece*
> bien y está **mal**. Normalizá el texto antes de contar y verificá con `head`.

## Paso 3 — Verificá tu bandera con Ansible

```bash
ansible-playbook comprobar_bandera.yml -e "bandera=BANDERA{...}"
```

- ✅ correcta → 🏁 trofeo.
- ❌ incorrecta → volvé a mirar cada respuesta.

El repo **no guarda la bandera en texto plano**: solo su huella **SHA-256** en
`secretos/bandera.sha256`. Es la misma idea con la que el servidor guarda las
contraseñas (nunca el secreto, solo su hash). **Security by design.**

## Paso 4 — Entregá

🏁 **Este reto NO se entrega por Pull Request.** Cuando `comprobar_bandera.yml` te
dé ✅, **decísela al profe** (en clase o por el canal del curso). Listo.

## Probá la idempotencia (lo más importante de Ansible)

Corré `armar_reto.yml` **dos veces seguidas**: la 1ª hace cambios (`changed`), la 2ª
deja todo en `ok` (ya estaba como debía). Ese es el corazón de IaC: describís el
**estado deseado**, no pasos sueltos.

## 🔀 Multi-distro: el mismo playbook en 3 familias

| | Debian / Ubuntu | Arch | Fedora / RHEL |
|---|---|---|---|
| Gestor | `apt` | `pacman` | `dnf` |
| Cliente SSH | `openssh-client` | `openssh` | `openssh-clients` |
| Servidor SSH | `openssh-server` | `openssh` | `openssh-server` |
| Unit del server | `ssh.service` | `sshd.service` | `sshd.service` |
| Detección | `ansible_os_family == 'Debian'` | `'Archlinux'` | `'RedHat'` |

Acá se ve lindo el problema real: el paquete **no se llama igual** en las tres. El
playbook lo resuelve con un **mapa de variables** indexado por `ansible_os_family` y
el módulo genérico `package`, que elige el gestor por vos. Además la instalación va
dentro de un **`block`/`rescue`**: si no podés escalar a root, no se rompe nada —
te avisa y sigue.

## Qué hay acá

| Archivo | Qué es |
|---|---|
| `armar_reto.yml` | Despliega el puesto: paquetes + evidencia + misión (tri-distro, idempotente). |
| `comprobar_bandera.yml` | Verifica tu bandera por hash (sin exponer el secreto). |
| `comprobar_requisitos.sh` | Preflight: detecta tu distro y te dice qué instalar. |
| `correr.sh` | Atajo: preflight + arma el reto. |
| `templates/mision.txt.j2` | Plantilla Jinja de la misión (se personaliza con tus facts). |
| `reto/auth_reto.log` | Volcado de `journalctl -u ssh` de la noche del incidente. |
| `reto/sshd_config_reto` | El `/etc/ssh/sshd_config` del servidor. |
| `reto/99-lab_reto.conf` | El drop-in de `sshd_config.d/` que "iba a ser por 5 minutos". |
| `reto/nota_equipo.txt` | Nota del equipo (se deja en 0600). |
| `secretos/bandera.sha256` | Solo la **huella** de la bandera (no el secreto). |
| `inventory.ini` / `ansible.cfg` | Qué máquinas administra Ansible + config local. |

## ⚠️ Seguridad

- Ningún playbook usa `chmod 777`, contraseñas en texto plano ni secretos versionados.
- `host_key_checking = True` en `ansible.cfg`: si cambia la clave del host, **queremos**
  que se queje. Justo el tema de la clase.
- La nota con valor queda en **0600** (menor privilegio) por diseño.
- La bandera se guarda como **hash**, no en claro.
- Simulá (`--check --diff`) antes de aplicar algo que no conozcas.
