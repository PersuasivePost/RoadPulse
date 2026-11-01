"""Convert ml/checkpoints/best.pt to RoadPulse/Resources/RoadClassifier.mlpackage.

    source venv/bin/activate
    python ml/convert.py

Xcode compiles the package and generates a `RoadClassifier` Swift class. Vision usage:
VNCoreMLModel(for: RoadClassifier(configuration:).model) with
request.imageCropAndScaleOption = .scaleFill (matches training: images are squashed to 224x224).
"""
from pathlib import Path

import coremltools as ct
import torch
import torch.nn as nn

from dataset import CLASSES, IMG_SIZE, NORM_MEAN, NORM_STD
from train import CKPT, build_model

OUT = Path(__file__).parent.parent / "RoadPulse" / "Resources" / "RoadClassifier.mlpackage"


class Probabilities(nn.Module):
    """Wraps the network so Core ML's classifier output receives softmax probabilities."""

    def __init__(self, net: nn.Module):
        super().__init__()
        self.net = net

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return torch.softmax(self.net(x), dim=1)


def main() -> None:
    ckpt = torch.load(CKPT, map_location="cpu")
    assert ckpt["classes"] == CLASSES, "checkpoint classes differ from dataset.CLASSES"
    net = build_model()
    net.load_state_dict(ckpt["model"])
    model = Probabilities(net).eval()
    traced = torch.jit.trace(model, torch.rand(1, 3, IMG_SIZE, IMG_SIZE))

    # Core ML feeds pixels 0-255; y = pixel * scale + bias must equal (pixel/255 - mean) / std.
    scale = 1.0 / (255.0 * NORM_STD)
    bias = [-m / NORM_STD for m in NORM_MEAN]
    mlmodel = ct.convert(
        traced,
        inputs=[ct.ImageType(name="image", shape=(1, 3, IMG_SIZE, IMG_SIZE),
                             scale=scale, bias=bias, color_layout=ct.colorlayout.RGB)],
        classifier_config=ct.ClassifierConfig(CLASSES),
        convert_to="mlprogram",
        minimum_deployment_target=ct.target.iOS17,
        compute_precision=ct.precision.FLOAT16,
    )
    mlmodel.author = "persuasivepost"
    mlmodel.license = "MIT"
    mlmodel.short_description = "RoadPulse road photo classifier: normal vs pothole (MobileNetV3-Small, 224x224)."
    mlmodel.version = "1.0"
    mlmodel.input_description["image"] = "Road photo, 224x224 RGB (squash, do not crop)."
    OUT.parent.mkdir(parents=True, exist_ok=True)
    mlmodel.save(str(OUT))
    print(f"saved {OUT}")


if __name__ == "__main__":
    main()
