#!/usr/bin/env bash
# 镜像环境补丁：修 venv 搬移残留路径 + LIBERO 与 mujoco 3.x 的兼容问题。
# 幂等，可重复执行。用法：bash scripts/patch_env.sh [venv 路径]
set -euo pipefail

VENV="${1:-/opt/xbotics/handbook-venv}"
SP="$VENV/lib/python3.12/site-packages"
export PATH="$VENV/bin:$PATH"

# 1) venv activate 脚本里搬移前的旧 VIRTUAL_ENV 路径
echo "[1/4] 修 activate 脚本旧路径"
for f in "$VENV/bin/activate" "$VENV/bin/activate.csh" "$VENV/bin/activate.fish" "$VENV/bin/activate.nu" "$VENV/bin/activate.bat"; do
  [ -f "$f" ] && sed -i 's#/root/gpufree-data/Xbotics-Embodied-AI-Handbook/code/.venv#'"$VENV"'#g' "$f"
done

# 2) robosuite 的 mj_fullM 用旧 mujoco 2.x 签名，mujoco 3.x 改成了 (m, d, dst)
echo "[2/4] 补丁 robosuite mj_fullM"
python - "$SP/robosuite/controllers/base_controller.py" <<'PY'
import sys
p = sys.argv[1]
old = "mujoco.mj_fullM(self.sim.model._model, mass_matrix, self.sim.data.qM)"
new = "mujoco.mj_fullM(self.sim.model._model, self.sim.data._data, mass_matrix)"
s = open(p).read()
if new in s:
    print("  已打过，跳过")
elif old in s:
    open(p, "w").write(s.replace(old, new))
    print("  已补丁")
else:
    print("  未找到目标行，跳过")
PY

# 3) LIBERO 依赖（hf-egl-probe 编译失败，只用于 LIBERO 自带 EGL 渲染，
#    lerobot 走 mujoco 离屏渲染用不到，故 --no-deps 绕过）
echo "[3/4] 装 LIBERO"
if ! python -c "import libero" 2>/dev/null; then
  pip install -q "bddl==1.0.1" "robomimic==0.2.0" "hf-libero==0.1.3" --no-deps
fi

# 4) libero 资产路径缓存（写成当前 venv 内的 libero 位置）
echo "[4/4] 生成 libero 配置"
mkdir -p ~/.libero
cat > ~/.libero/config.yaml <<EOF
assets: $SP/libero/libero/./assets
bddl_files: $SP/libero/libero/./bddl_files
benchmark_root: $SP/libero/libero
datasets: $SP/libero/libero/../datasets
init_states: $SP/libero/libero/./init_files
EOF

echo "补丁完成"
