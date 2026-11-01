"""Download the four public Hugging Face datasets used to train RoadPulse's classifier.

No Kaggle credentials are needed. Everything lands in ml/data/ (git-ignored).
Re-running skips files that already exist.

    python ml/download_data.py
"""
import json
import urllib.parse
import urllib.request
import zipfile
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

DATA = Path(__file__).parent / "data"
HF = "https://huggingface.co"
IMAGE_EXT = (".jpg", ".jpeg", ".png")

# (repo, local folder, only fetch paths starting with these prefixes or None for all)
IMAGEFOLDER_SOURCES = [
    ("taroii/pothole-detection", "taroii", None),
    ("Arpitraj01/Pothole_classification", "arpit", None),
    ("kauevestena/deep_pavements_surface_patches", "pave",
     ("asphalt/", "concrete/", "concrete plates/", "paving stones/", "sett/", "cobblestone/")),
]
RUPESH_ZIP = f"{HF}/datasets/rupesh002/pothole-detection-dataset/resolve/main/pothole_dataset.zip"


def fetch(repo: str, path: str, out: Path) -> None:
    if out.exists():
        return
    out.parent.mkdir(parents=True, exist_ok=True)
    urllib.request.urlretrieve(f"{HF}/datasets/{repo}/resolve/main/{urllib.parse.quote(path)}", out)


def download_imagefolder(repo: str, folder: str, prefixes) -> None:
    info = json.load(urllib.request.urlopen(f"{HF}/api/datasets/{repo}"))
    files = [s["rfilename"] for s in info["siblings"] if s["rfilename"].lower().endswith(IMAGE_EXT)]
    if prefixes:
        files = [f for f in files if f.startswith(prefixes)]
    with ThreadPoolExecutor(8) as pool:
        list(pool.map(lambda f: fetch(repo, f, DATA / folder / f), files))
    print(f"{repo}: {len(files)} images -> {DATA / folder}")


def download_rupesh() -> None:
    target = DATA / "rupesh"
    if target.exists():
        return
    zip_path = DATA / "rupesh.zip"
    urllib.request.urlretrieve(RUPESH_ZIP, zip_path)
    with zipfile.ZipFile(zip_path) as z:
        z.extractall(DATA / "_rupesh_tmp")
    (next((DATA / "_rupesh_tmp").iterdir())).rename(target)
    (DATA / "_rupesh_tmp").rmdir()
    zip_path.unlink()
    print(f"rupesh002/pothole-detection-dataset -> {target}")


if __name__ == "__main__":
    for repo, folder, prefixes in IMAGEFOLDER_SOURCES:
        download_imagefolder(repo, folder, prefixes)
    download_rupesh()
