# AI Models Directory

## Required Model File

Place your YOLOv8 segmentation model in this directory:

**File:** `yolov8s-seg.tflite`

## Where to Get the Model

### Option 1: Official Ultralytics Export

1. Install Ultralytics:
   ```bash
   pip install ultralytics
   ```

2. Export YOLOv8-seg to TFLite:
   ```python
   from ultralytics import YOLO
   
   # Load model
   model = YOLO('yolov8s-seg.pt')
   
   # Export to TFLite
   model.export(format='tflite', imgsz=640)
   ```

3. The exported file will be named `yolov8s-seg_saved_model/yolov8s-seg_float32.tflite`

4. Rename it to `yolov8s-seg.tflite` and place it here.

### Option 2: Pre-converted Model

Download pre-converted TFLite models from:
- Ultralytics GitHub: https://github.com/ultralytics/assets/releases
- Look for YOLOv8-seg TFLite models

### Option 3: Custom Training

Train your own model on construction/demolition-specific dataset:

```python
from ultralytics import YOLO

# Train on custom dataset
model = YOLO('yolov8s-seg.pt')
model.train(data='construction.yaml', epochs=100)

# Export to TFLite
model.export(format='tflite', imgsz=640)
```

## Model Specifications

**Expected Model:**
- Type: YOLOv8 Segmentation (instance segmentation)
- Variant: Small (yolov8s-seg) or Nano (yolov8n-seg)
- Input Size: 640x640x3
- Format: TensorFlow Lite (.tflite)
- Quantization: Float32 (recommended) or Float16

**Supported Variants:**
- `yolov8n-seg.tflite` - Nano (faster, less accurate)
- `yolov8s-seg.tflite` - Small (balanced) ⭐ Recommended
- `yolov8m-seg.tflite` - Medium (slower, more accurate)
- `yolov8l-seg.tflite` - Large (much slower)
- `yolov8x-seg.tflite` - Extra Large (very slow)

## Model Size Reference

| Variant | Size    | Speed      | Accuracy |
|---------|---------|------------|----------|
| Nano    | ~7 MB   | Very Fast  | Good     |
| Small   | ~25 MB  | Fast       | Better   | ⭐
| Medium  | ~52 MB  | Moderate   | High     |
| Large   | ~90 MB  | Slow       | Higher   |
| XLarge  | ~140 MB | Very Slow  | Highest  |

## Important Notes

⚠️ **The model file is NOT included in the repository due to size constraints.**

⚠️ **You must download or export the model yourself and place it here.**

⚠️ **The app will not function without this model file.**

## Verification

After adding the model, verify it's correctly placed:

```bash
ls -lh assets/ai/yolov8s-seg.tflite
```

Expected output:
```
-rw-r--r-- 1 user user 25M Jan 01 12:00 yolov8s-seg.tflite
```

## License

YOLOv8 models are licensed under AGPL-3.0:
https://github.com/ultralytics/ultralytics/blob/main/LICENSE

For commercial use, you may need a commercial license from Ultralytics:
https://ultralytics.com/license
