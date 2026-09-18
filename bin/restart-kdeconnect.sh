#!/usr/bin/env bash
set -euo pipefail

readonly daemon_name=kdeconnectd
readonly shutdown_timeout=10
readonly startup_timeout=15

command -v kdeconnect-cli >/dev/null 2>&1 || {
  echo 'Erro: kdeconnect-cli não está instalado.' >&2
  exit 1
}

mapfile -t old_pids < <(pgrep -x "$daemon_name" || true)

if ((${#old_pids[@]})); then
  printf 'Encerrando KDE Connect (PID(s): %s)...\n' "${old_pids[*]}"
  for pid in "${old_pids[@]}"; do
    kill -TERM "$pid" 2>/dev/null || true
  done

  for ((attempt = 0; attempt < shutdown_timeout * 10; attempt++)); do
    still_running=false
    for pid in "${old_pids[@]}"; do
      if kill -0 "$pid" 2>/dev/null; then
        still_running=true
        break
      fi
    done
    [[ "$still_running" == false ]] && break
    sleep 0.1
  done

  if [[ "$still_running" == true ]]; then
    echo 'Erro: o daemon antigo não encerrou após 10 segundos; nenhuma nova instância foi iniciada.' >&2
    exit 1
  fi
else
  echo 'KDE Connect não estava em execução.'
fi

echo 'Iniciando KDE Connect...'
# This D-Bus call starts kdeconnectd without changing pairings or configuration.
timeout "${startup_timeout}s" kdeconnect-cli --refresh >/dev/null 2>&1 || true

for ((attempt = 0; attempt < startup_timeout * 10; attempt++)); do
  mapfile -t new_pids < <(pgrep -x "$daemon_name" || true)
  ((${#new_pids[@]})) && break
  sleep 0.1
done

if ((${#new_pids[@]} == 0)); then
  echo 'Erro: o KDE Connect não iniciou.' >&2
  exit 1
fi

if ((${#new_pids[@]} > 1)); then
  printf 'Aviso: foram encontradas múltiplas instâncias (PID(s): %s).\n' "${new_pids[*]}" >&2
  exit 1
fi

printf 'KDE Connect reiniciado (PID %s).\n' "${new_pids[0]}"
timeout 10s kdeconnect-cli --list-devices || {
  echo 'Aviso: o daemon iniciou, mas a consulta de dispositivos não respondeu.' >&2
  exit 1
}
