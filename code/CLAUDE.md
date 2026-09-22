# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`code/` is the runnable demo-code tree for the **Xbotics 具身智能教程 (21 讲)** — a systems-focused embodied-AI / robotics course. It is **not a Python package** (`pyproject.toml` has `package = false`) and is never installed; it is a set of lecture demos that all share **one uv-managed environment** rooted at `code/`.

The repo root (`../`) also holds `docs/` (the lecture texts), `hardware/`, `assets/`, `meta/`, `templates/`. Course prose lives in `docs/`, not here. This file covers `code/` only.

## Environment (uv, not pip)

- One unified uv environment at `code/`. **Always `uv sync`; never `pip install`.** Python pinned to 3.12.x (`.python-version` = `3.12.11`; `requires-python = ">=3.12,<3.13"`).
- Three **mutually exclusive** extras — pick one per machine (declared `conflicts` in `pyproject.toml`):

  ```bash
  cd code
  uv sync --extra gpu_x86                 # x86 GPU workstation (CUDA 12.8): all VLA + RL train/infer/demo
  uv sync --extra nogpu_x86               # x86 CPU: SO-101 teleop data collection + ACT ONNX/BPU export
  uv sync --extra rdk_s100 --no-editable  # D-Robotics RDK S100/S600 board (aarch64): SO-101 data collection
  ```

- `lerobot` is installed from a maintained fork via `[tool.uv.sources]`: `github.com/Xbotics-Embodied-AI-club/lerobot`, branch `main` (baseline v0.5.1) plus four extra commits — `groot` fix, `vla0_smol`, `openvla`, `so101_sim` eval. The SO-101 simulator is a **separate repo** (`Xbotics-SO101-Sim`), pulled in as the fork's core dependency (`import so101_sim`). To change the simulator, edit that repo — this one keeps no copy.

## Environment variables

Copy the templates and fill values; code reads these vars directly with no defaults:

```bash
cp .env.example .env                 # HF_TOKEN / HUGGING_FACE_HUB_TOKEN / WANDB_API_KEY / DATASETS_ROOT
cp .envrc.example .envrc && direnv allow
```

- `DATASETS_ROOT` — root for all datasets / model artifacts (default `./datasets`, gitignored).
- `HF_HOME = $DATASETS_ROOT/hfcache`, `HF_LEROBOT_HOME = $HF_HOME/lerobot` (derived in `.envrc`).

## Tests

Smoke tests live in `tests/` (no CI runs them — the only workflow is a manual docs→GitHub Pages publish):

```bash
python -m pytest tests/test_cartpole_smoke.py -v   # CPU-only; rl/3_offpolicy components
python -m pytest tests/test_so101_kit_smoke.py -v  # requires CUDA (ManiSkill GPU backend)
python -m pytest tests/test_so101_sim_smoke.py -v  # requires CUDA
```

Tests import lecture modules by file path (`importlib.util.spec_from_file_location`), not via package import.

## Layout

- `vla/` — lectures 8–12 (VLA). `rl/` — lectures 14–16. Both are organized into topic groups with dual numbering `<group>_<order>_<name>` (e.g. `1_policy_rollout/1_2_pi0_libero_rollout`). The lecture→group mapping is maintained **only** in `vla/README.md` and `rl/README.md` tables — never in directory names.
- `platform/` — shared infra, not course demos: `rdk/` (RDK board BPU deploy for ACT) and `so101_real/` (USB camera/serial binding to fixed device names).
- `lectureNN/` (01–07, 17–21) — **not part of the uv environment.** Each keeps its own `requirements.txt` + `hardware/` / `simulation/` split; the `simulation/` path must run without hardware.
- `assets/` — URDFs / CAD (`KIT_v1_urdf_clean`, `objects`).
- `tests/` — smoke tests.

## Conventions

- Dual-numbered module dirs **only ever add** new numbers; never renumber (gaps are kept, e.g. `vla/`'s `2_1` is deliberately absent).
- Lecture-facing entrypoints ship as matching `.py` + a Chinese-sectioned `.ipynb` (same content) for in-class walkthrough.
- Large artifacts (checkpoints, datasets, pretrained models) are **not committed** — they land under `DATASETS_ROOT/models/trained/` etc.
- Demo code is written for classroom reading: constants inlined near use, top-to-bottom in teaching order, no CLI-arg layers. Match that style when adding code.
- Modules reference group-shared data by relative path (`../data/...`) so a whole group dir stays portable.
- Three distinct tracks, don't conflate them (see `platform/so101_real/README.md`): `so101_sim` (ManiSkill3 simulation), `platform/so101_real/` (real-device binding), `platform/rdk/` (BPU board deploy).
- `scratch/` is a gitignored task-local workspace; never commit it, and anything a regression gate depends on must be versioned under e.g. `tests/data/`, not left in `scratch/`.
