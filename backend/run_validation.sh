#!/bin/bash
# Quick script to run model training and comparison

echo "=========================================="
echo "🎓 FYP Model Training & Comparison"
echo "=========================================="
echo ""

cd "$(dirname "$0")"

# Activate virtual environment
if [ -f "../venv/bin/activate" ]; then
    source "../venv/bin/activate"
else
    echo "⚠️  Virtual environment not found"
    exit 1
fi

echo "Step 1: Training custom model..."
python train_model.py
echo ""

echo "Step 2: Comparing AI vs Custom Model..."
python compare_models.py
echo ""

echo "✅ Complete! Check these files:"
echo "   - custom_model.pkl (trained model)"
echo "   - comparison_results.json (detailed results)"
echo "   - ../MODEL_COMPARISON_REPORT.md (documentation)"
echo ""
echo "📊 To view results:"
echo "   cat comparison_results.json | python -m json.tool"
