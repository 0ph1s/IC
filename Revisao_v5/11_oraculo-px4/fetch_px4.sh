#!/usr/bin/env bash
# Baixa, de github.com/PX4/PX4-Autopilot, SÓ os arquivos de que o oráculo precisa (checkout esparso e raso do
# commit fixado abaixo): o failsafe, os cabeçalhos de plataforma e três .msg. Não baixa o repositório inteiro.
# Uso: bash fetch_px4.sh <pasta de destino>      (a pasta não é versionada; padrão: ./px4_src)
# Rede: precisa de acesso a github.com. O PX4 é BSD-3-Clause (LICENSE vem junto).
set -eu
PX4_COMMIT=4e44c822c9018120508bce6d8ad349f0775586a1
DEST="${1:-px4_src}"
export MSYS_NO_PATHCONV=1   # Git Bash no Windows converteria os padrões que começam com '/'
mkdir -p "$DEST"
cd "$DEST"
[ -d .git ] || git init -q .
git remote get-url origin > /dev/null 2>&1 || git remote add origin https://github.com/PX4/PX4-Autopilot.git
git sparse-checkout init --no-cone
git sparse-checkout set \
  '/LICENSE' \
  '/src/modules/commander/failsafe/' \
  '/src/modules/commander/ModeUtil/' \
  '/src/modules/commander/px4_custom_mode.h' \
  '/src/lib/circuit_breaker/' \
  '/src/include/containers/' \
  '/src/drivers/drv_hrt.h' \
  '/platforms/common/include/' \
  '/platforms/common/module_params.cpp' \
  '/msg/FailsafeFlags.msg' \
  '/msg/versioned/BatteryStatus.msg' \
  '/msg/versioned/VehicleStatus.msg'
git fetch -q --depth 1 --filter=blob:none origin "$PX4_COMMIT"
git checkout -q FETCH_HEAD
echo "PX4 em $(git rev-parse HEAD)"
# Conferência dos arquivos que o oráculo compila: os hashes devem ser os registrados em README.md
git hash-object src/modules/commander/failsafe/failsafe.cpp src/modules/commander/failsafe/framework.cpp \
  src/modules/commander/failsafe/failsafe.h src/modules/commander/failsafe/framework.h \
  src/modules/commander/failsafe/failsafe_test.cpp
