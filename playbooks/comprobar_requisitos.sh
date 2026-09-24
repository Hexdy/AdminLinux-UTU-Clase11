#!/usr/bin/env bash
# comprobar_requisitos.sh — ¿tenés todo para armar el reto con Ansible?
#
# Detecta tu distribución (Debian/Ubuntu, Arch, Fedora/RHEL) y, si algo falta,
# te dice el comando EXACTO para instalarlo. No instala nada por vos: solo
# comprueba y te guía (vos leés y corrés el comando con criterio).
#
# Uso:   bash comprobar_requisitos.sh
set -u

echo "=== Comprobando requisitos para el reto de Ansible + SSH ==="

# --- 1) Detectar el gestor de paquetes de tu distro ----------------------
# Ojo: el cliente OpenSSH se llama DISTINTO en cada familia.
if command -v apt-get >/dev/null 2>&1; then
  GESTOR="apt"
  INSTALAR="sudo apt update && sudo apt install -y"
  PKG_SSH="openssh-client"
elif command -v pacman >/dev/null 2>&1; then
  GESTOR="pacman"
  INSTALAR="sudo pacman -Sy --needed"
  PKG_SSH="openssh"
elif command -v dnf >/dev/null 2>&1; then
  GESTOR="dnf"
  INSTALAR="sudo dnf install -y"
  PKG_SSH="openssh-clients"
else
  GESTOR="desconocido"
  INSTALAR=""
  PKG_SSH="openssh"
fi
echo "Distro / gestor de paquetes detectado: ${GESTOR}  (cliente SSH: ${PKG_SSH})"
echo

# --- 2) Comprobar cada herramienta requerida -----------------------------
faltan=0

# $1 = comando a buscar, $2 = paquete a instalar si falta
comprobar() {
  local cmd="$1" pkg="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "  [OK]    ${cmd}  ->  $("$cmd" --version 2>&1 | head -n1)"
  else
    echo "  [FALTA] ${cmd}"
    if [ "$GESTOR" != "desconocido" ]; then
      echo "          instalalo con:  ${INSTALAR} ${pkg}"
    else
      echo "          gestor no reconocido; instalá '${pkg}' con el gestor de tu distro."
    fi
    faltan=$((faltan + 1))
  fi
}

comprobar ansible-playbook ansible
comprobar python3 python3
# El cliente ssh y gawk los instala el propio playbook (armar_reto.yml), pero
# si querés adelantarte, acá te dice el nombre correcto para TU distro.
comprobar ssh "$PKG_SSH"
comprobar gawk gawk

# --- 3) Chequeo extra: permisos de tu ~/.ssh (la causa #1 de "no me deja") --
echo
if [ -d "$HOME/.ssh" ]; then
  PERM_DIR="$(stat -c '%a' "$HOME/.ssh" 2>/dev/null || echo '?')"
  echo "  [INFO]  ~/.ssh existe y está en ${PERM_DIR}  (debería ser 700)"
  if [ "$PERM_DIR" != "700" ] && [ "$PERM_DIR" != "?" ]; then
    echo "          arreglalo con:  chmod 700 ~/.ssh"
  fi
else
  echo "  [INFO]  todavía no tenés ~/.ssh (normal si nunca generaste una clave)"
fi

# --- 4) Resumen ----------------------------------------------------------
echo
if [ "$faltan" -eq 0 ]; then
  echo "=== Todo listo. Armá el reto: ==="
  echo "    ansible-playbook armar_reto.yml -l local --check --diff   # simular"
  echo "    ansible-playbook armar_reto.yml -l local                  # aplicar"
  exit 0
else
  echo "=== Faltan ${faltan} requisito(s). Instalalos (arriba te digo cómo) y volvé a correr este script. ==="
  echo "    (Nota: el cliente ssh y 'gawk' también los instala el playbook armar_reto.yml por vos.)"
  exit 1
fi
