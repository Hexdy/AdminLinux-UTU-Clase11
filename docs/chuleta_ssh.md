# Chuleta — SSH

## Conectarse

```bash
ssh usuario@servidor              # lo básico
ssh -p 2222 usuario@servidor      # otro puerto (ojo: -p minúscula en ssh)
ssh -i ~/.ssh/id_ed25519 u@srv    # usar una clave puntual
ssh -v usuario@servidor           # modo charlatán: para cuando NO anda
ssh usuario@servidor 'uptime'     # correr un comando y salir
```

| Flag | Qué hace |
|---|---|
| `-p <puerto>` | Puerto del servidor (en `scp` es `-P` mayúscula, trampa clásica) |
| `-i <archivo>` | Qué clave privada usar |
| `-v` / `-vv` / `-vvv` | Más y más detalle del intento (debug) |
| `-N` | No abrir shell (para túneles) |
| `-f` | Mandarlo al fondo |

## Claves

```bash
ssh-keygen -t ed25519 -C "tu-comentario"   # generar el par (con passphrase, SIEMPRE)
ssh-copy-id usuario@servidor               # instalar tu clave pública allá
ssh-keygen -lf ~/.ssh/id_ed25519.pub       # ver la huella de tu clave
```

| Archivo | Qué es | Permiso |
|---|---|---|
| `~/.ssh` | la carpeta | `700` |
| `~/.ssh/id_ed25519` | tu clave **privada** (no sale de tu máquina, nunca) | `600` |
| `~/.ssh/id_ed25519.pub` | tu clave **pública** (esta sí se reparte) | `644` |
| `~/.ssh/authorized_keys` | claves públicas que pueden entrar **a esta cuenta** | `600` |
| `~/.ssh/known_hosts` | huellas de los servidores que ya visitaste | `644` |
| `~/.ssh/config` | tus atajos de conexión | `600` |

> ⚠️ Permisos flojos = `sshd` **ignora la clave en silencio** (`StrictModes yes`).
> Es la causa #1 de "me pide contraseña y no debería".

## Agente (para no escribir la passphrase 40 veces)

```bash
eval "$(ssh-agent -s)"     # arrancarlo (si tu escritorio no lo hizo ya)
ssh-add ~/.ssh/id_ed25519  # cargar la clave (te pide la passphrase UNA vez)
ssh-add -l                 # ver qué claves tiene cargadas
ssh-add -D                 # descargarlas todas
```

## `~/.ssh/config` (el que te cambia la vida)

```
Host prod
    HostName 10.0.0.5
    User ulyses
    Port 2222
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60
```

Y entonces: `ssh prod`. También funciona con `scp prod:/ruta .` y `rsync`.

## Mover archivos

| Necesito… | Comando |
|---|---|
| Copiar un archivo allá | `scp archivo.txt usuario@srv:/ruta/` |
| Traer un archivo | `scp usuario@srv:/ruta/archivo.txt .` |
| Carpeta entera | `scp -r carpeta/ usuario@srv:/ruta/` |
| Sesión interactiva | `sftp usuario@srv` → `ls`, `cd`, `get`, `put`, `bye` |
| **Lo que se usa hoy** | `rsync -avz carpeta/ usuario@srv:/ruta/` |
| Ensayo sin copiar nada | `rsync -avzn --delete origen/ destino/` |

> `scp` usa `-P` mayúscula para el puerto. `rsync` lo pasa así:
> `rsync -avz -e "ssh -p 2222" origen/ usuario@srv:/ruta/`

## El servidor

```bash
systemctl status ssh          # Debian/Ubuntu
systemctl status sshd         # Arch/Fedora
sudo sshd -t                  # ¿la config es válida?  ← ANTES de tocar nada
sudo sshd -T | grep -i puerto # ver la config EFECTIVA (ya resuelta)
sudo systemctl reload ssh     # aplicar sin cortar sesiones
journalctl -u ssh -n 50       # los últimos 50 renglones del log
ss -tlnp | grep :22           # ¿está escuchando?
```

> 🔴 **Regla de oro**: dejá **siempre** una sesión abierta mientras tocás la
> config. Probá la nueva en **otra terminal**. Si rompés algo con la vieja
> abierta, lo arreglás; si no, te quedaste afuera del servidor.

## Túneles

| Quiero… | Comando |
|---|---|
| Traer un puerto remoto a mi máquina | `ssh -L 5432:localhost:5432 usuario@srv -N` |
| Publicar un puerto mío en el server | `ssh -R 8080:localhost:3000 usuario@srv -N` |
| Proxy SOCKS para el navegador | `ssh -D 1080 usuario@srv -N` |

## Cuando cambia la huella del host

```
WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!
```

No borres `known_hosts` a lo bruto. Primero **preguntá si reinstalaron el server**.
Si es legítimo:

```bash
ssh-keygen -R servidor        # sacar SOLO esa entrada
```

## Errores típicos

- `Permission denied (publickey)` → tu clave no está en `authorized_keys` del server,
  o los permisos de `~/.ssh` están flojos.
- `Connection refused` → el servicio no corre o no escucha en ese puerto.
- `Connection timed out` → firewall o red (no llegás ni a saludar).
- `-p` en `ssh` pero `-P` en `scp`.
- `ssh.service` en Debian/Ubuntu, `sshd.service` en Arch/Fedora.
