# Hardening de `sshd` — la guía corta

> El servidor SSH es la **puerta de entrada** de todo. Si la dejás floja, no importa
> el resto. Acá va lo mínimo que se pone en producción.

## ⚠️ Antes de tocar nada: las 3 reglas

1. **Dejá una sesión abierta.** Nunca cierres la terminal con la que estás conectado
   hasta haber probado la nueva config **desde otra terminal**.
2. **Validá antes de aplicar**: `sudo sshd -t`. Si hay un error de sintaxis, te lo dice
   **sin** reiniciar el servicio. Si reiniciás con la config rota, te quedás afuera.
3. **`reload` antes que `restart`.** `reload` releé la config sin cortar las sesiones
   que ya están abiertas.

```bash
sudo sshd -t                  # 1) ¿es válida?  (silencio = OK)
sudo systemctl reload ssh     # 2) aplicar      (sshd en Arch/Fedora)
# 3) probar en OTRA terminal antes de cerrar esta
```

## Dónde se escribe

No edites el archivo principal si tu distro trae `Include`. Dejá tu configuración
en un **drop-in**:

```bash
sudo install -d -m 755 /etc/ssh/sshd_config.d
sudoedit /etc/ssh/sshd_config.d/10-hardening.conf
```

> 🧠 **Ojo con el orden**: en `sshd_config` gana la **primera** aparición de cada
> directiva. Como el `Include` suele estar **arriba de todo**, lo que pongas en
> `sshd_config.d/` **pisa** al archivo principal. Y entre drop-ins, mandan por orden
> alfabético. Por eso se numeran (`10-`, `99-`).

## Las directivas que importan

| Directiva | Valor recomendado | Por qué |
|---|---|---|
| `PermitRootLogin` | `no` | Que nadie entre como root. Entrás como vos y escalás con `sudo` (así queda registrado **quién**). |
| `PubkeyAuthentication` | `yes` | Autenticación por clave, lo que queremos. |
| `PasswordAuthentication` | `no` | Sin contraseñas no hay fuerza bruta posible. **Probá tu clave antes de poner esto.** |
| `KbdInteractiveAuthentication` | `no` | Cierra la otra puerta por la que se cuela una contraseña. |
| `AllowUsers` / `AllowGroups` | `sre ulyses` / `sshusers` | Lista blanca: solo esa gente puede intentar entrar. |
| `MaxAuthTries` | `3` | Cuántos intentos por conexión antes de cortar. |
| `LoginGraceTime` | `20` | Segundos para autenticarse. Menos tiempo = menos conexiones colgadas. |
| `X11Forwarding` | `no` | Reenvío gráfico: en un servidor no se usa y suma superficie. |
| `AllowTcpForwarding` | `no` (si no usás túneles) | Los túneles atraviesan firewalls. Si no los necesitás, apagalos. |
| `ClientAliveInterval` | `300` | Detecta y limpia sesiones muertas. |
| `LogLevel` | `VERBOSE` | Registra la huella de la clave usada. Oro puro para investigar después. |

## Un drop-in de ejemplo

```
# /etc/ssh/sshd_config.d/10-hardening.conf
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no

AllowGroups sshusers
MaxAuthTries 3
LoginGraceTime 20

X11Forwarding no
ClientAliveInterval 300
ClientAliveCountMax 2
LogLevel VERBOSE
```

Después:

```bash
sudo sshd -t && sudo systemctl reload ssh
sudo sshd -T | grep -Ei 'permitrootlogin|passwordauthentication|maxauthtries'
```

`sshd -T` te muestra la config **efectiva**, ya resueltos los `Include` y los
`Match`. Es la forma honesta de saber qué quedó activo de verdad.

## ¿Y cambiar el puerto?

Podés (`Port 2222`), y el log te va a quedar mucho más limpio porque los bots
escanean el 22. Pero seamos honestos: **eso es seguridad por oscuridad**. Baja el
**ruido**, no el **riesgo**: un escaneo de puertos te encuentra igual en segundos.
Cambialo si querés, pero **no lo cuentes como una defensa**.

## `fail2ban` — el complemento

Lee el log de `sshd` y, cuando ve muchos fallos desde la misma IP, la bloquea en el
firewall por un rato.

```bash
# Debian/Ubuntu:  sudo apt install fail2ban
# Arch:           sudo pacman -S fail2ban
# Fedora:         sudo dnf install fail2ban

sudo systemctl enable --now fail2ban
sudo fail2ban-client status sshd
```

> Es un complemento, **no un reemplazo**. Con `PasswordAuthentication no` los bots ya
> no tienen nada que adivinar; `fail2ban` simplemente les corta el ruido antes.

## Lo que NO se hace

- ❌ Reiniciar `sshd` sin correr `sshd -t` primero.
- ❌ Cerrar tu única sesión sin haber probado la nueva config.
- ❌ Dejar `PermitRootLogin yes` "hasta que terminemos de migrar".
- ❌ Compartir una cuenta entre varias personas (se pierde el *quién hizo qué*).
- ❌ Copiar la clave **privada** al servidor. La que se copia es la `.pub`.
- ❌ Un drop-in "de prueba por 5 minutos" que nadie saca nunca.

## 🤖 Si le pedís la config a una IA

Las IAs todavía sugieren directivas **obsoletas** que hoy no hacen nada o directamente
**rompen** el arranque de `sshd`:

| Te lo van a sugerir | Estado real |
|---|---|
| `Protocol 2` | Eliminada hace años (SSHv1 ya no existe). |
| `UsePrivilegeSeparation yes` | Eliminada (hoy es siempre así). |
| `RSAAuthentication yes` | Eliminada (era de SSHv1). |
| `ChallengeResponseAuthentication` | Renombrada a `KbdInteractiveAuthentication`. |

Por eso el flujo es **siempre** el mismo: pedís → leés → `sshd -t` → probás en otra
terminal → recién ahí confiás. **Verificar antes de confiar.**
