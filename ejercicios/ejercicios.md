# Ejercicios — Clase 11

Practicá sobre `datos/`. Las soluciones están en `soluciones.md`, pero **intentá
primero**. Cuando dudes de un campo, verificá con `head`.

> 🔒 **Nada de lo de acá toca tu `~/.ssh` real ni levanta un servidor.** Los ejercicios
> de config se resuelven **leyendo** los archivos de ejemplo. Si querés probar de
> verdad, hacelo en tu VM y con una segunda sesión abierta.

## Cliente y claves

1. Escribí el comando para entrar a `servidor.interno` como `ulyses` por el puerto
   `2222`, usando la clave `~/.ssh/id_ed25519`.
2. ¿Qué comando te muestra **la huella** de tu clave pública? ¿Para qué te sirve
   compararla con la que te pasa el administrador del servidor?
3. Generá (en papel, no lo corras todavía) el comando para crear un par **ed25519**
   con el comentario `ulyses@utu-2026`. ¿Por qué ed25519 y no RSA?
4. Tenés `~/.ssh` en `755` y `authorized_keys` en `644`. El servidor te pide contraseña
   aunque copiaste bien la clave. ¿Qué pasó y con qué dos comandos lo arreglás?
5. Escribí el bloque de `~/.ssh/config` que convierte
   `ssh -p 2222 -i ~/.ssh/id_ed25519 ulyses@10.0.0.5` en `ssh prod`.

## Transferencia

6. Copiá la carpeta `informes/` a `/srv/backup/` del servidor `prod`, pero con la
   herramienta que **sólo manda lo que cambió** y se puede reanudar.
7. Escribí el mismo comando anterior en modo **ensayo**, para ver qué haría sin copiar
   nada.
8. ¿Cuál es la diferencia de mayúscula entre `ssh` y `scp` cuando indicás el puerto?

## Log del servidor (`datos/auth_ejemplo.log`)

9. Contá cuántas **conexiones aceptadas por clave pública** hay en el log.
10. Sacá el **top de IPs** con más intentos fallidos de contraseña, ordenado de mayor
    a menor.
11. Mostrá qué **usuarios** fueron probados por atacantes (los que el servidor marca
    como usuario inválido), sin repetidos.

## Configuración (`datos/sshd_config_ejemplo`)

12. Leyendo el archivo: ¿se puede entrar como root? ¿se puede entrar con contraseña?
    Citá la línea exacta que lo dice.
13. Encontrá **dos** directivas que endurecerías y escribí el valor que les pondrías.
14. Este archivo **no** tiene `Include`. Si le agregaras
    `Include /etc/ssh/sshd_config.d/*.conf` arriba de todo, explicá en una frase por
    qué eso cambia quién "gana" cuando la misma directiva aparece en los dos archivos.

## Para pensar (seguridad)

15. Tu jefe te pide "cambiar SSH al puerto 2222 para que no nos ataquen más". ¿Qué le
    contestás? Dale una respuesta honesta de dos frases: qué mejora eso realmente y qué
    medida sí baja el riesgo.
16. Te conectás a un servidor de siempre y te salta
    `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!`. Escribí los **tres pasos** que
    hacés antes de tocar `known_hosts`.

> 🤖 Si te trabás, pedile a la IA que te explique el comando **parte por parte** y
> verificá con una muestra chica antes de confiar en el resultado. Si te sugiere una
> config de `sshd`, pasala por `sudo sshd -t` **antes** de aplicarla — y con otra
> sesión abierta.
