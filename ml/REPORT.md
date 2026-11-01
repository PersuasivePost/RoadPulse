# RoadPulse classifier report

**Test accuracy: 96.7%** on 211 held-out images (target ≥ 88%).

## Model
- MobileNetV3-Small (ImageNet weights), classifier head replaced with 2 outputs, full fine-tune.
- Classes: normal, pothole. No `crack` class: no suitable close-up crack dataset was found.
- Input 224×224 RGB, ImageNet mean (0.485, 0.456, 0.406), single std 0.226 (what Core ML's `ImageType` scale/bias can express). Use `imageCropAndScaleOption = .scaleFill` in Vision.
- 20 epochs, batch 64, AdamW lr 0.001, cosine schedule, AMP, class-weighted cross-entropy (label smoothing 0.05). Trained in 1.2 min on an RTX 3050 Ti. Best epoch picked on validation accuracy.

## Data (all public, downloaded by `ml/download_data.py`, no Kaggle key)
| Source (Hugging Face) | Used as | Images |
|---|---|---|
| taroii/pothole-detection | pothole / no pothole street photos | 437 |
| Arpitraj01/Pothole_classification (MIT) | low/medium/severe → pothole, none → normal | 386 |
| rupesh002/pothole-detection-dataset (MIT) | pothole (Roboflow, augmented copies grouped) | 715 |
| kauevestena/deep_pavements_surface_patches (MIT) | asphalt/concrete/paving/sett/cobblestone → normal | 600 |

Split 80/10/10 **by source photo** (augmented copies never straddle splits), stratified per source and class: train 1717, val 210, test 211.

## Confusion matrix (test; rows = actual, columns = predicted)
| | normal | pothole |
|---|---|---|
| **normal** | 83 | 1 |
| **pothole** | 6 | 121 |

| Class | Precision | Recall | Support |
|---|---|---|---|
| normal | 93.3% | 98.8% | 84 |
| pothole | 99.2% | 95.3% | 127 |

## Test accuracy by source and class
| Source / class | Correct | Total | Accuracy |
|---|---|---|---|
| arpit/normal | 5 | 5 | 100.0% |
| arpit/pothole | 34 | 34 | 100.0% |
| pave/normal | 59 | 60 | 98.3% |
| rupesh/pothole | 68 | 68 | 100.0% |
| taroii/normal | 19 | 19 | 100.0% |
| taroii/pothole | 19 | 25 | 76.0% |

## Caveats (read before trusting the headline number)
- Each source is skewed: `rupesh` is pothole-only and grayscale, `pave` is normal-only and low-resolution. A model can partly learn the *source*. Training uses random grayscale/blur to weaken those shortcuts, but the in-domain rows above (`taroii/*`, `arpit/*`) are the most honest signal.
- The datasets are small (about 2k images) and mostly European/Asian roads. Expect lower accuracy on Mumbai monsoon photos; check with real phone photos on the Mac visit.
- `normal` includes wide street scenes and flat pavement patches, not only close-ups.

## Training curve (val accuracy per epoch)
`0.93 0.97 0.93 0.91 0.94 0.97 0.97 0.95 0.98 0.98 0.98 0.98 0.98 0.98 0.98 0.98 0.98 0.98 0.98 0.98`
