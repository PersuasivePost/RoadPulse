"""Fine-tune MobileNetV3-Small to classify road photos as normal / pothole.

    source venv/bin/activate
    python ml/download_data.py     # once
    python ml/train.py             # trains, saves ml/checkpoints/best.pt, writes ml/REPORT.md
"""
import argparse
import json
import time
from collections import defaultdict
from pathlib import Path

import numpy as np
import torch
import torch.nn as nn
from torch.utils.data import DataLoader
from torchvision.models import MobileNet_V3_Small_Weights, mobilenet_v3_small

from dataset import (CLASSES, NORM_MEAN, NORM_STD, RoadDataset, class_weights, collect,
                     eval_transform, split, train_transform)

HERE = Path(__file__).parent
CKPT = HERE / "checkpoints" / "best.pt"


def build_model() -> nn.Module:
    model = mobilenet_v3_small(weights=MobileNet_V3_Small_Weights.IMAGENET1K_V1)
    model.classifier[3] = nn.Linear(model.classifier[3].in_features, len(CLASSES))
    return model


@torch.no_grad()
def predict(model, loader, device):
    model.eval()
    logits, labels = [], []
    for x, y in loader:
        with torch.autocast(device_type=device.type, enabled=device.type == "cuda"):
            logits.append(model(x.to(device)).float().cpu())
        labels.append(y)
    return torch.cat(logits), torch.cat(labels)


def metrics(logits, labels, loss_fn):
    preds = logits.argmax(1)
    return (preds == labels).float().mean().item(), loss_fn(logits, labels).item()


def evaluate_test(model, test_ds, device) -> dict:
    loader = DataLoader(test_ds, batch_size=64, num_workers=2)
    logits, labels = predict(model, loader, device)
    preds = logits.argmax(1).numpy()
    y = labels.numpy()
    n = len(CLASSES)
    cm = np.zeros((n, n), dtype=int)
    for t, p in zip(y, preds):
        cm[t, p] += 1
    per_class = {}
    for c, name in enumerate(CLASSES):
        tp = cm[c, c]
        per_class[name] = {"precision": tp / max(cm[:, c].sum(), 1), "recall": tp / max(cm[c].sum(), 1),
                           "support": int(cm[c].sum())}
    by_source = defaultdict(lambda: [0, 0])
    for s, t, p in zip(test_ds.samples, y, preds):
        by_source[(s.source, CLASSES[s.label])][0] += int(t == p)
        by_source[(s.source, CLASSES[s.label])][1] += 1
    return {"accuracy": float((preds == y).mean()), "confusion": cm.tolist(), "per_class": per_class,
            "by_source": {f"{k[0]}/{k[1]}": v for k, v in sorted(by_source.items())}}


def write_report(res: dict, sizes: dict, counts: dict, args, history: list, train_secs: float) -> None:
    cm = res["confusion"]
    lines = [
        "# RoadPulse classifier report", "",
        f"**Test accuracy: {res['accuracy']:.1%}** on {sum(sizes['test'].values())} held-out images "
        f"(target ≥ 88%).", "",
        "## Model",
        "- MobileNetV3-Small (ImageNet weights), classifier head replaced with 2 outputs, full fine-tune.",
        f"- Classes: {', '.join(CLASSES)}. No `crack` class: no suitable close-up crack dataset was found.",
        f"- Input 224×224 RGB, ImageNet mean {NORM_MEAN}, single std {NORM_STD} (what Core ML's "
        "`ImageType` scale/bias can express). Use `imageCropAndScaleOption = .scaleFill` in Vision.",
        f"- {args.epochs} epochs, batch {args.batch}, AdamW lr {args.lr}, cosine schedule, AMP, "
        f"class-weighted cross-entropy (label smoothing 0.05). Trained in {train_secs / 60:.1f} min on an "
        "RTX 3050 Ti. Best epoch picked on validation accuracy.", "",
        "## Data (all public, downloaded by `ml/download_data.py`, no Kaggle key)",
        "| Source (Hugging Face) | Used as | Images |", "|---|---|---|",
        "| taroii/pothole-detection | pothole / no pothole street photos | " + str(counts["taroii"]) + " |",
        "| Arpitraj01/Pothole_classification (MIT) | low/medium/severe → pothole, none → normal | "
        + str(counts["arpit"]) + " |",
        "| rupesh002/pothole-detection-dataset (MIT) | pothole (Roboflow, augmented copies grouped) | "
        + str(counts["rupesh"]) + " |",
        "| kauevestena/deep_pavements_surface_patches (MIT) | asphalt/concrete/paving/sett/cobblestone → normal | "
        + str(counts["pave"]) + " |", "",
        f"Split 80/10/10 **by source photo** (augmented copies never straddle splits), stratified per "
        f"source and class: train {sum(sizes['train'].values())}, val {sum(sizes['val'].values())}, "
        f"test {sum(sizes['test'].values())}.", "",
        "## Confusion matrix (test; rows = actual, columns = predicted)",
        "| | " + " | ".join(CLASSES) + " |", "|---|" + "---|" * len(CLASSES),
    ]
    for i, name in enumerate(CLASSES):
        lines.append(f"| **{name}** | " + " | ".join(str(v) for v in cm[i]) + " |")
    lines += ["", "| Class | Precision | Recall | Support |", "|---|---|---|---|"]
    for name, m in res["per_class"].items():
        lines.append(f"| {name} | {m['precision']:.1%} | {m['recall']:.1%} | {m['support']} |")
    lines += ["", "## Test accuracy by source and class",
              "| Source / class | Correct | Total | Accuracy |", "|---|---|---|---|"]
    for k, (ok, n) in res["by_source"].items():
        lines.append(f"| {k} | {ok} | {n} | {ok / n:.1%} |")
    lines += [
        "", "## Caveats (read before trusting the headline number)",
        "- Each source is skewed: `rupesh` is pothole-only and grayscale, `pave` is normal-only and "
        "low-resolution. A model can partly learn the *source*. Training uses random grayscale/blur "
        "to weaken those shortcuts, but the in-domain rows above (`taroii/*`, `arpit/*`) are the "
        "most honest signal.",
        "- The datasets are small (about 2k images) and mostly European/Asian roads. Expect lower accuracy "
        "on Mumbai monsoon photos; check with real phone photos on the Mac visit.",
        "- `normal` includes wide street scenes and flat pavement patches, not only close-ups.",
        "", "## Training curve (val accuracy per epoch)",
        "`" + " ".join(f"{h['val_acc']:.2f}" for h in history) + "`", "",
    ]
    (HERE / "REPORT.md").write_text("\n".join(lines))


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--epochs", type=int, default=20)
    ap.add_argument("--batch", type=int, default=64)
    ap.add_argument("--lr", type=float, default=1e-3)
    ap.add_argument("--seed", type=int, default=42)
    args = ap.parse_args()
    torch.manual_seed(args.seed)
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

    samples = collect()
    parts = split(samples, args.seed)
    counts = {s: sum(x.source == s for x in samples) for s in ("taroii", "arpit", "rupesh", "pave")}
    sizes = {k: {c: sum(x.label == i for x in v) for i, c in enumerate(CLASSES)} for k, v in parts.items()}
    print("images per source", counts, "| split sizes", sizes)

    train_ds = RoadDataset(parts["train"], train_transform())
    val_ds = RoadDataset(parts["val"], eval_transform())
    test_ds = RoadDataset(parts["test"], eval_transform())
    train_loader = DataLoader(train_ds, batch_size=args.batch, shuffle=True, num_workers=4, drop_last=True)
    val_loader = DataLoader(val_ds, batch_size=64, num_workers=2)

    model = build_model().to(device)
    loss_fn = nn.CrossEntropyLoss(weight=class_weights(parts["train"]).to(device), label_smoothing=0.05)
    plain_loss = nn.CrossEntropyLoss()
    opt = torch.optim.AdamW(model.parameters(), lr=args.lr, weight_decay=1e-2)
    steps = args.epochs * len(train_loader)
    sched = torch.optim.lr_scheduler.OneCycleLR(opt, max_lr=args.lr, total_steps=steps, pct_start=0.15)
    scaler = torch.amp.GradScaler(enabled=device.type == "cuda")

    best, history, t0 = (-1.0, 9e9), [], time.time()
    CKPT.parent.mkdir(exist_ok=True)
    for epoch in range(1, args.epochs + 1):
        model.train()
        running = 0.0
        for x, y in train_loader:
            x, y = x.to(device), y.to(device)
            opt.zero_grad(set_to_none=True)
            with torch.autocast(device_type=device.type, enabled=device.type == "cuda"):
                loss = loss_fn(model(x), y)
            scaler.scale(loss).backward()
            scaler.step(opt)
            scaler.update()
            sched.step()
            running += loss.item()
        logits, labels = predict(model, val_loader, device)
        val_acc, val_loss = metrics(logits, labels, plain_loss)
        history.append({"epoch": epoch, "train_loss": running / len(train_loader), "val_acc": val_acc})
        print(f"epoch {epoch:2d} train_loss {running / len(train_loader):.4f} val_acc {val_acc:.4f} val_loss {val_loss:.4f}")
        if (val_acc, -val_loss) > (best[0], -best[1]):
            best = (val_acc, val_loss)
            torch.save({"model": model.state_dict(), "classes": CLASSES}, CKPT)

    model.load_state_dict(torch.load(CKPT, map_location=device)["model"])
    res = evaluate_test(model, test_ds, device)
    print(json.dumps(res, indent=2))
    write_report(res, sizes, counts, args, history, time.time() - t0)
    print(f"test accuracy {res['accuracy']:.4f} -> ml/REPORT.md")


if __name__ == "__main__":
    main()
