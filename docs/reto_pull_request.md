# Reto de la semana — Clase 11 🏁 (la bandera)

Cerramos SSH como en un trabajo real: **desplegás el entorno con Ansible**, analizás
el incidente de un bastión con lo de esta clase, capturás la **bandera** y
**se la decís al profe**.

> 🐧 No es hacking: es el laburo de un sysadmin de guardia (leer el log del servicio,
> mirar la configuración real, entender qué pasó). La bandera es la **recompensa**
> por hacerlo bien.

> 🏁 **Este reto NO se entrega por Pull Request.** No tenés que subir nada al repo:
> cuando tengas la bandera verificada, **se la decís al profe** (en clase o por el
> canal del curso). Eso es todo.

> 🔒 Los playbooks **no generan claves, no tocan tu `~/.ssh` y no levantan `sshd`**.
> Solo dejan archivos para que los leas. Corrélos tranquilo.

## Pasos

1. **Cloná fuera de Drive**:
   ```bash
   git clone <url> C:\src\AdminLinux-UTU-Clase11
   cd C:\src\AdminLinux-UTU-Clase11\playbooks
   ```
2. **Desplegá el puesto de guardia con Ansible** (idempotente; simulá primero):
   ```bash
   ansible-playbook armar_reto.yml -l local --check --diff
   ansible-playbook armar_reto.yml -l local
   ```
   Esto instala el cliente OpenSSH + `gawk`, crea `datos/reto/` y te deja tu
   `MISION.txt`. Corré el playbook **dos veces**: la 2ª da `ok` (idempotencia).
3. **Leé la misión y la nota del equipo**:
   ```bash
   cat ../datos/reto/MISION.txt
   cat ../datos/reto/nota_equipo.txt
   ```
   > ⚠️ La nota tiene un dato **falso** a propósito. Un compañero te va a decir "de
   > memoria" cuál era la bandera. **No le creas**: contó mal. Sacá vos los números.
4. **Resolvé las 3 respuestas** sobre `datos/reto/`:
   - **R1** — el **usuario** con más intentos **fallidos** de contraseña.
   - **R2** — la **IP** desde la que salieron más intentos **fallidos**.
   - **R3** — la **directiva** que quedó activa y permite entrar **sin contraseña**
     (tal cual se escribe, respetando mayúsculas).
5. **Armá la bandera** con el formato exacto y **verificala** con Ansible:
   ```bash
   ansible-playbook comprobar_bandera.yml -e "bandera=BANDERA{<usuario>-<ip>-<Directiva>}"
   ```
   Tiene que dar **✅ BANDERA CORRECTA**.
6. **Decile la bandera al profe** — en clase o por el canal del curso. Con eso el reto
   queda entregado. **No hace falta subir nada al repo** ni abrir un Pull Request.

## Las dos trampas (avisadas)

- **Formatos de línea distintos.** Los fallos de contraseña aparecen de dos maneras:
  una para usuarios que existen y otra para usuarios inventados. El **número de campo**
  no cae en el mismo lugar en las dos. Si contás por posición a lo bruto, te sale un
  resultado plausible y **equivocado**. Normalizá el texto antes de contar.
- **Quién gana en `sshd_config`.** Manda la **primera** aparición de cada directiva, y
  el `Include` está arriba de todo. Preguntate qué archivo gana **de verdad** antes de
  responder R3. Si podés, comprobalo con `sudo sshd -T` en un servidor tuyo.

## Cómo se evalúa (autoevaluación)

- [ ] Desplegaste con `armar_reto.yml` y lo corriste **2 veces** (la 2ª da `ok` → idempotente).
- [ ] **R1** cuenta intentos **fallidos** (no los aceptados) y contempla **los dos formatos** de línea.
- [ ] **R2** sale del **mismo** tipo de línea que R1.
- [ ] **R3** es la directiva que **realmente** quedó activa, no la del archivo principal.
- [ ] No le creíste a la nota del equipo sin verificar.
- [ ] `comprobar_bandera.yml` te dio la bandera **correcta** (✅).
- [ ] Le **dijiste la bandera al profe** (en clase o por el canal del curso).

> 🔒 El repo no guarda la bandera en claro, solo su **hash SHA-256**. Así se guardan las
> contraseñas de verdad: nunca el secreto, solo su huella.

> 🤖 Si le pedís el comando a la IA, revisá que el campo que cuenta sea el correcto y
> probalo con `head` sobre una muestra antes de confiar en el número final. Lo mismo que
> hacés con `sshd -t` antes de aplicar una config: **verificar antes de confiar**.
