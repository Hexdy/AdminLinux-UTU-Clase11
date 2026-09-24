# AdminLinux · UTU · Clase 11 — SSH y administración remota

> Repo de la **Clase 11** de *Administración de Sistemas Linux* (UTU, 2026).
> Docente: **Ulyses García**. Repositorio **privado** de práctica.

Doble uso: 🤖 pegá `CONTEXTO_IA.md` en tu chatbot · 🧑‍💻 cloná y practicá SSH sobre
los archivos de `datos/`.

## 🏁 Empezá por acá (el reto de hoy)

**Cloná el repo apenas arranca la clase y empezá a resolverlo mientras escuchás.**
Llegás al final con medio reto hecho, como en un laburo real.

```
  1. Cloná          2. Resolvé mientras escuchás        3. Decísela al profe
  --------          ----------------------------        --------------------
  git clone  >>>    ansible-playbook armar_reto.yml >>>  verificás la 🏁 y se
  (fuera de Drive)  y sacás R1, R2 y R3                  la decís al profe
                                                         (NO hace falta PR)
```

**¿Qué es el reto de hoy?** Entrás de guardia. Un bastión comió escaneos toda la
noche y la configuración del servidor SSH no era la que el equipo creía. Con el log
del servicio y los dos archivos de config tenés que decir **a quién atacaron**,
**desde dónde** y **qué directiva quedó mal**. Con esas 3 respuestas armás la
bandera. Detalle en [`docs/reto_pull_request.md`](docs/reto_pull_request.md).

## 🚀 Arranque rápido

> 🔑 Cloná **fuera** de Google Drive / OneDrive. El sync corrompe `.git`.

```bash
git clone <url-de-este-repo> C:\src\AdminLinux-UTU-Clase11
cd C:\src\AdminLinux-UTU-Clase11/datos

# Tu primer análisis: ¿quién entró de verdad y quién se quedó afuera?
grep -c 'Accepted publickey' auth_ejemplo.log
grep 'Failed password' auth_ejemplo.log | grep -oE 'from [0-9.]+' | sort | uniq -c
```

## 🗂️ Qué hay acá

| Carpeta / archivo | Qué es |
|---|---|
| `CONTEXTO_IA.md` | **Pegá esto en tu chatbot** para que te asista con contexto. |
| `datos/auth_ejemplo.log` | Volcado corto de `journalctl -u ssh` para practicar. |
| `datos/sshd_config_ejemplo` | Un `sshd_config` flojo, para que lo endurezcas leyendo. |
| `datos/ssh_config_ejemplo` | Un `~/.ssh/config` de ejemplo (alias, `ProxyJump`). |
| `ejercicios/` | 16 ejercicios + soluciones explicadas. |
| `docs/chuleta_ssh.md` | La chuleta de la clase (comandos, permisos, túneles). |
| `docs/hardening_sshd.md` | Guía corta para endurecer el servidor. |
| `docs/reto_pull_request.md` | 🏁 El reto de la bandera, paso a paso. |
| `playbooks/` | 🏁 **El reto**: desplegás con Ansible (multi-distro) tu puesto de guardia y capturás la bandera. |

> 🔒 **Ningún archivo de este repo es una clave real.** Las claves que ves en los
> ejemplos están truncadas a propósito. Y los playbooks **no generan claves, no tocan
> tu `~/.ssh` ni levantan un `sshd`**: solo dejan archivos para leer.

## 🏁 El reto de la bandera (Ansible + SSH)

El plato fuerte vive en [`playbooks/`](playbooks/README.md). Es un **escenario real de
sysadmin**, no un ejercicio de juguete:

1. **Desplegás** tu puesto con Ansible: `ansible-playbook armar_reto.yml -l local`
   (instala el cliente OpenSSH y `gawk`, deja la evidencia del bastión y te genera una
   `MISION.txt` personalizada).
2. **Analizás** el log de `sshd` y la config real: usuario más atacado, IP con más
   fallos, y la directiva que quedó activa y no debería.
3. **Armás la bandera** `BANDERA{<usuario>-<ip>-<Directiva>}` y la **verificás** con
   `ansible-playbook comprobar_bandera.yml -e "bandera=BANDERA{...}"`.
4. **Se la decís al profe.** No hace falta Pull Request.

El **mismo** playbook corre en **Ubuntu, Arch y Fedora** (detecta la distro solo,
aunque el paquete se llame distinto en cada una).

> 🔒 La bandera no se guarda en texto plano: el repo solo tiene su **hash SHA-256**
> (igual que se guardan las contraseñas). *Security by design.*

## 🧵 Hilo del curso

En la **C7** aprendiste a mirar la red (`ip`, `ss`, `ping`). En la **C9** y la **C10**,
a manejar procesos y servicios (`systemctl`, `journalctl`). Hoy juntamos las tres:
`sshd` **es** un servicio que **escucha** en un puerto y **loguea** en journal. Lo que
cambia es que ahora la puerta da a Internet.

## 🎯 Los 5 pilares

Hoy pega fuerte **Security by Design** (claves en vez de contraseñas, menor privilegio,
hardening con validación previa) e **IA aplicada** (pedir una config endurecida y
**verificarla con `sshd -t`** antes de aplicarla). Y el reto de
[`playbooks/`](playbooks/README.md) suma **IaC + Ansible**: desplegás el entorno **como
código**, idempotente y multi-distro.

## ⚠️ Seguridad

- La clave **privada nunca sale de tu máquina**. La que se copia es la `.pub`.
- Passphrase **siempre**. Si te roban el archivo, sin passphrase no les sirve.
- `~/.ssh` en `700` y las claves privadas en `600`. Permisos flojos = `sshd` las ignora
  en silencio.
- Antes de recargar `sshd`: `sudo sshd -t`, y **dejá una sesión abierta** mientras
  probás desde otra terminal.

---

## ❓ Autoevaluación de la clase

> 5 preguntas para saber si **entendiste lo de hoy**. No hay soluciones — pensalas y, si
> te trabás, abrí la 💡 **Pista**.

### 1️⃣ Pública vs privada
¿Cuál de las dos claves del par se copia al servidor y cuál no sale nunca de tu máquina?
¿Por qué se puede repartir una sin riesgo?
<details><summary>💡 Pista</summary>

Pensalo como un candado abierto y su llave. El candado lo repartís a quien quiera
guardarte algo; la llave te la quedás. Con el candado nadie puede fabricar la llave.
</details>

### 2️⃣ El aviso que casi todos borran
Te salta `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!` en un servidor de siempre.
¿Qué te está diciendo el cliente y por qué borrar `known_hosts` es la peor reacción?
<details><summary>💡 Pista</summary>

El cliente compara la huella que te presenta el servidor con la que anotó la primera
vez. Si cambió, o reinstalaron la máquina… o hay alguien en el medio. Borrar el archivo
es apagar la alarma sin averiguar por qué sonó.
</details>

### 3️⃣ "Copié la clave y me sigue pidiendo contraseña"
Copiaste bien tu `.pub` a `authorized_keys` y el servidor igual te pide contraseña. ¿Cuál
es la causa más probable y cómo la verificás?
<details><summary>💡 Pista</summary>

`StrictModes yes` hace que `sshd` ignore las claves si los permisos están flojos, y lo
hace **en silencio**. Mirá la carpeta y el archivo: `700` y `600`. El log del servidor te
lo confirma.
</details>

### 4️⃣ Validar antes de aplicar
¿Qué hace `sshd -t` y por qué es obligatorio correrlo antes de recargar el servicio?
¿Qué otra precaución tomás en paralelo?
<details><summary>💡 Pista</summary>

Valida la sintaxis **sin** aplicar nada. Si reiniciás con la config rota, el servicio no
levanta y te quedás afuera del servidor. La otra precaución: nunca cierres la sesión con
la que estás conectado hasta probar la nueva en otra terminal.
</details>

### 5️⃣ Puerto raro ≠ seguridad
Tu jefe quiere mover SSH al 2222 "para que no nos ataquen". ¿Qué mejora eso realmente y
qué medida sí baja el riesgo?
<details><summary>💡 Pista</summary>

Baja el **ruido** (los bots escanean el 22), no el **riesgo**: un escaneo te encuentra
igual. Lo que baja el riesgo de verdad es sacar la autenticación por contraseña y entrar
solo con claves.
</details>

---

*Material docente. Elaborado con asistencia de IA y revisado por el docente.*
