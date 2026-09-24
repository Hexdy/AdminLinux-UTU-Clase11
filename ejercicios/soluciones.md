# Soluciones — Clase 11

> Mirá esto **después** de intentarlo. La gracia no es tener el comando: es entender
> por qué ese y no otro.

## Cliente y claves

**1.**
```bash
ssh -p 2222 -i ~/.ssh/id_ed25519 ulyses@servidor.interno
```
`-p` minúscula en `ssh` (en `scp` es `-P`). `-i` elige la clave privada.

**2.**
```bash
ssh-keygen -lf ~/.ssh/id_ed25519.pub
```
Te da la **huella** (fingerprint). Sirve para comparar por un canal distinto (teléfono,
en persona) que la clave que tiene el servidor es la tuya y no la de un intruso. Lo mismo
que hace `ssh` con la huella del **host** la primera vez que te conectás.

**3.**
```bash
ssh-keygen -t ed25519 -C "ulyses@utu-2026"
```
ed25519 es más corta, más rápida y al menos tan segura como RSA de 4096 bits. RSA se
deja **solo** para equipos viejos que no entienden ed25519, y ahí sí con `-b 4096`.
Y **siempre con passphrase**: si te roban el archivo, sin la passphrase no les sirve.

**4.** `sshd` ignora las claves cuando los permisos están flojos (`StrictModes yes`), y
lo hace **en silencio**: por eso "cae" a pedirte contraseña. En el **servidor**:
```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

**5.**
```
Host prod
    HostName 10.0.0.5
    User ulyses
    Port 2222
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
```
Y ahora: `ssh prod`. `IdentitiesOnly yes` evita que el agente ofrezca todas tus claves
(si ofrece muchas, podés chocar con `MaxAuthTries` y que te rebote).

## Transferencia

**6.**
```bash
rsync -avz informes/ prod:/srv/backup/informes/
```
`-a` preserva permisos y tiempos, `-v` muestra qué hace, `-z` comprime en tránsito.
La barra final en el origen significa "el **contenido** de la carpeta".

**7.**
```bash
rsync -avzn informes/ prod:/srv/backup/informes/
```
`-n` (o `--dry-run`) te muestra qué haría **sin copiar nada**. Costumbre obligatoria
cuando encima vas a usar `--delete`.

**8.** `ssh -p 2222` (minúscula) vs `scp -P 2222` (mayúscula). `rsync` no tiene flag de
puerto propio: se lo pasás al transporte con `-e "ssh -p 2222"`.

## Log del servidor

**9.**
```bash
grep -c 'Accepted publickey' auth_ejemplo.log
```
Da **1** (la sesión de `ulyses`). Ojo: hay otra línea `Accepted password` — esa **no**
es por clave pública, y es justamente la que querríamos que no exista más.

**10.**
```bash
grep 'Failed password' auth_ejemplo.log | grep -oE 'from [0-9.]+' | awk '{print $2}' \
  | sort | uniq -c | sort -rn
```
`grep -oE` saca solo el pedacito `from <ip>`, así **no** dependés del número de campo
(que se corre cuando la línea dice `invalid user`). Ese es el punto del ejercicio.

**11.**
```bash
grep 'Invalid user' auth_ejemplo.log | awk '{print $5}' | sort -u
```
Te salen los usuarios que los bots probaron y **no existen** en el sistema. Un pico de
estos en tu log es la firma clásica de un escaneo automatizado.

## Configuración

**12.** Sí y sí, y está escrito con todas las letras:
```
PermitRootLogin yes
PasswordAuthentication yes
```
Las dos juntas son la peor combinación posible: `root` es un usuario que existe en
**todos** los Linux, así que al bot solo le falta adivinar la contraseña.

**13.** Cualquier par de estas (con su valor):

| Está así | Debería estar | Por qué |
|---|---|---|
| `PermitRootLogin yes` | `no` | Entrás como vos y escalás con `sudo`: queda registrado **quién**. |
| `PasswordAuthentication yes` | `no` | Sin contraseñas no hay fuerza bruta. Probá tu clave **antes**. |
| `MaxAuthTries 6` | `3` | Menos intentos por conexión. |
| `LoginGraceTime 120` | `20` | Menos tiempo colgado esperando que alguien se autentique. |
| `X11Forwarding yes` | `no` | En un servidor no se usa y suma superficie. |
| `ClientAliveInterval 0` | `300` | Limpia sesiones muertas. |

**14.** Porque en `sshd_config` gana la **primera** aparición de cada directiva. Si el
`Include` está arriba de todo, las líneas de `sshd_config.d/*.conf` se leen **antes** y
por lo tanto **pisan** a las del archivo principal (aunque abajo diga otra cosa). La
forma honesta de saber qué quedó activo es `sudo sshd -T`.

## Para pensar

**15.** Algo así: *"Cambiar el puerto baja muchísimo el **ruido** en el log, porque los
bots escanean el 22. Pero no baja el **riesgo**: un escaneo de puertos te encuentra
igual en segundos. Lo que sí baja el riesgo es apagar la autenticación por contraseña y
entrar solo con claves; si querés, hacemos las dos cosas, pero contemos solo la segunda
como defensa."* Eso es **seguridad por oscuridad**: sirve como capa extra, nunca como
la capa única.

**16.**
1. **No borres `known_hosts`.** El aviso está haciendo exactamente su trabajo.
2. **Preguntá** si reinstalaron, migraron o recrearon el servidor (o si cambió la IP y
   ahora te atiende otra máquina). Pedí la huella nueva por **otro canal** (mensaje,
   teléfono) y compará con la que te muestra el cliente.
3. Si es legítimo, sacá **solo esa** entrada y volvé a conectarte:
   ```bash
   ssh-keygen -R servidor.interno
   ```
   Si **no** podés confirmarlo, no te conectes: puede ser alguien en el medio
   (man-in-the-middle) haciéndose pasar por el servidor.
