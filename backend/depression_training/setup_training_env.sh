#!/usr/bin/env bash
# setup_training_env.sh
# Creates the depression training venv ON the 1TB drive and installs all requirements.
# Run this ONE TIME before training:
#   chmod +x setup_training_env.sh && ./setup_training_env.sh

set -e

VENV_PATH="/Volumes/1t storage/grad project/venv_depression"
VENV_PATH_SAFE="/Volumes/1t_storage_venv/venv_depression"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Depression Training Environment Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "► Creating virtual environment at:"
echo "  $VENV_PATH"
python3 -m venv "$VENV_PATH"

echo ""
echo "► Activating venv and upgrading pip..."
source "$VENV_PATH/bin/activate"
pip install --upgrade pip wheel setuptools

echo ""
echo "► Installing training requirements (this may take a few minutes)..."
pip install -r "$SCRIPT_DIR/requirements_train.txt"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✓ Setup complete!"
echo ""
echo "  To train, run:"
echo "    source \"$VENV_PATH/bin/activate\""
echo "    cd \"$SCRIPT_DIR\""
echo ""
echo "  TRAIN ORDER:"
echo "    python 2_train_audio.py    (fastest, ~3 min)"
echo "    python 3_train_visual.py   (medium,  ~10 min)"
echo "    python 1_train_text.py     (slowest, ~30 min, downloads DistilBERT)"
echo "    python 4_train_fusion.py   (after all 3 above are done)"
echo ""
echo "  All models saved to:"
echo "    /Volumes/1t storage/grad project/depression_training/trained_models/"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
