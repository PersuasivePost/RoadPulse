"""Dataset assembly, grouped 80/10/10 split and torch Dataset for RoadPulse.

Labels: 0 = normal, 1 = pothole. Constants here are shared with convert.py so training
and the Core ML model use exactly the same preprocessing.
"""
import random
import re
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path

import torch
from PIL import Image
from torch.utils.data import Dataset
from torchvision import transforms as T

DATA = Path(__file__).parent / "data"
CLASSES = ["normal", "pothole"]
IMG_SIZE = 224

# Core ML ImageType can apply one scale and a per-channel bias, so the std is a single
# scalar (the mean of ImageNet's 0.229/0.224/0.225). Training uses the same maths.
NORM_MEAN = (0.485, 0.456, 0.406)
NORM_STD = 0.226


@dataclass(frozen=True)
class Sample:
    path: Path
    label: int
    source: str
    group: str  # samples sharing a group never straddle splits (augmented copies, etc.)


def _files(pattern: str):
    return sorted(p for p in DATA.glob(pattern) if p.suffix.lower() in (".jpg", ".jpeg", ".png"))


def collect() -> list[Sample]:
    samples: list[Sample] = []
    for p in _files("taroii/*/pothole/*"):
        samples.append(Sample(p, 1, "taroii", str(p)))
    for p in _files("taroii/*/no pothole/*"):
        samples.append(Sample(p, 0, "taroii", str(p)))
    for p in _files("arpit/datasets/*/none/*"):
        samples.append(Sample(p, 0, "arpit", str(p)))
    for sev in ("low", "medium", "severe"):
        for p in _files(f"arpit/datasets/*/{sev}/*"):
            samples.append(Sample(p, 1, "arpit", str(p)))
    for p in _files("pave/*/*"):
        samples.append(Sample(p, 0, "pave", str(p)))
    for p in _files("rupesh/*/images/*"):
        # Roboflow exports several augmented copies per photo: "img-585_jpg.rf.<hash>.jpg".
        samples.append(Sample(p, 1, "rupesh", re.sub(r"_jpg\.rf\..*", "", p.name)))
    return samples


def split(samples: list[Sample], seed: int = 42) -> dict[str, list[Sample]]:
    """80/10/10 by group, stratified per (source, label) so every split sees every source."""
    strata: dict[tuple, dict[str, list[Sample]]] = defaultdict(lambda: defaultdict(list))
    for s in samples:
        strata[(s.source, s.label)][s.group].append(s)
    rng = random.Random(seed)
    out: dict[str, list[Sample]] = {"train": [], "val": [], "test": []}
    for key in sorted(strata):
        groups = sorted(strata[key])
        rng.shuffle(groups)
        n = len(groups)
        n_val, n_test = max(1, round(n * 0.1)), max(1, round(n * 0.1))
        cuts = {"test": groups[:n_test], "val": groups[n_test:n_test + n_val], "train": groups[n_test + n_val:]}
        for name, gs in cuts.items():
            for g in gs:
                out[name].extend(strata[key][g])
    return out


def train_transform() -> T.Compose:
    # Grayscale/blur augmentation breaks two dataset shortcuts: the rupesh potholes are all
    # grayscale and the pavement patches are all low-resolution.
    return T.Compose([
        T.RandomResizedCrop(IMG_SIZE, scale=(0.5, 1.0), ratio=(0.75, 1.33)),
        T.RandomHorizontalFlip(),
        T.ColorJitter(0.3, 0.3, 0.3, 0.03),
        T.RandomGrayscale(0.5),
        T.RandomApply([T.GaussianBlur(5, (0.5, 2.0))], p=0.3),
        T.ToTensor(),
        T.Normalize(NORM_MEAN, (NORM_STD,) * 3),
    ])


def eval_transform() -> T.Compose:
    # Squash to 224x224 (no crop). In the app set VNCoreMLRequest.imageCropAndScaleOption = .scaleFill.
    return T.Compose([
        T.Resize((IMG_SIZE, IMG_SIZE)),
        T.ToTensor(),
        T.Normalize(NORM_MEAN, (NORM_STD,) * 3),
    ])


class RoadDataset(Dataset):
    """Images are decoded once and cached at <= 320 px so epochs are not disk bound."""

    def __init__(self, samples: list[Sample], transform: T.Compose):
        self.samples, self.transform = samples, transform
        self.images = [self._load(s.path) for s in samples]

    @staticmethod
    def _load(path: Path) -> Image.Image:
        img = Image.open(path).convert("RGB")
        img.thumbnail((320, 320))
        return img

    def __len__(self) -> int:
        return len(self.samples)

    def __getitem__(self, i: int):
        return self.transform(self.images[i]), self.samples[i].label


def class_weights(samples: list[Sample]) -> torch.Tensor:
    counts = torch.tensor([sum(s.label == c for s in samples) for c in range(len(CLASSES))], dtype=torch.float)
    return counts.sum() / (len(CLASSES) * counts)
