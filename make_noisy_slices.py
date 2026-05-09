# make_noisy_slices.py
# This script takes the clean PNG slices generated earlier and adds Rician noise
# at different SNR levels (e.g., 30, 20, 15, 10). For each clean slice, the script:
#   1. Estimates the noise level (sigma) required to match the chosen SNR.
#   2. Adds Rician noise using two Gaussian noise components.
#   3. Saves the noisy slices in separate folders for each SNR level.
# The output is organized by subject and SNR setting, making it easy to use
# for training, validation, or comparison in MRI denoising experiments.

import os, re
from pathlib import Path
import numpy as np
from PIL import Image

# Base project directory
ROOT = Path(r"C:\WorkSpace\external\FMI\IXI-T2")

# Folder that contains clean PNG slices (output from previous script)
CLEAN_SLICES = ROOT / "clean_slices"

# Folder where noisy slices will be stored
NOISY_ROOT = ROOT / "noisy_slices"

# SNR values for which we want to generate noisy images
SNR_LEVELS = [30, 20, 15, 10]

# Fixed seed so noise generation is repeatable
SEED = 1234

# Pattern to recognize file names like: IXI123_axial_k012.png
subj_pat = re.compile(r"^(IXI\d+)_axial_k(\d+)\.png$")


def estimate_sigma_for_snr(img01, snr):
    """
    Estimate the noise standard deviation (sigma) needed to produce
    the desired SNR level for a given image.

    Parameters:
        img01 (numpy.ndarray): Image with pixel values between 0 and 1.
        snr  (int or float)  : Desired signal-to-noise ratio.

    Returns:
        float: Estimated sigma value to achieve the chosen SNR.
    """

    v = img01.astype(np.float32)

    # Find brighter pixels to represent the "signal" level.
    # If image has any positive pixels, take the top 50% percentile.
    if (v > 0).any():
        mask = v > np.percentile(v[v > 0], 50)
    else:
        # If everything is zero, just use the whole image
        mask = np.ones_like(v, bool)

    # Compute the average signal from the masked area
    mu = v[mask].mean() if mask.any() else v.mean()

    # Sigma = mean / SNR, fallback value used if mean is zero
    return float(mu / snr if mu > 0 else 0.05)


def add_rician(img01, sigma, rng):
    """
    Add Rician noise to an image.

    Parameters:
        img01 (numpy.ndarray): Input clean image in [0,1].
        sigma (float)        : Noise standard deviation.
        rng  (np.random.Generator): Random number generator.

    Returns:
        numpy.ndarray: Noisy image, clipped to [0,1].
    """

    # Generate two Gaussian noise components
    n1 = rng.normal(0.0, sigma, size=img01.shape).astype(np.float32)
    n2 = rng.normal(0.0, sigma, size=img01.shape).astype(np.float32)

    # Apply Rician noise formula
    out = np.sqrt((img01 + n1) ** 2 + n2 ** 2)

    # Keep values inside valid display range
    return np.clip(out, 0, 1)


def main():
    """
    This function loops through each subject folder,
    loads the clean PNG slices, estimates sigma for each chosen SNR level,
    adds Rician noise, and saves all noisy versions in organized folders.
    """

    rng = np.random.default_rng(SEED)

    # List all subject folders inside clean_slices
    subjects = sorted([d for d in CLEAN_SLICES.iterdir() if d.is_dir()])

    for sdir in subjects:
        # All PNG slices for the current subject
        pngs = sorted(sdir.glob("*.png"))
        if not pngs:
            continue

        # Create noisy images for every SNR level
        for snr in SNR_LEVELS:
            out_subj = NOISY_ROOT / f"rician_snr{snr}" / sdir.name
            out_subj.mkdir(parents=True, exist_ok=True)

            for p in pngs:
                # Load clean image and convert to float between 0 and 1
                img = np.array(Image.open(p)).astype(np.float32) / 255.0

                # Estimate sigma for this SNR
                sigma = estimate_sigma_for_snr(img, snr)

                # Apply Rician noise
                noisy = add_rician(img, sigma, rng)

                # Save noisy image as uint8 PNG
                Image.fromarray((noisy * 255 + 0.5).astype(np.uint8)).save(out_subj / p.name)

        print(f"Noisy slices written for {sdir.name}")

    print("Done.")


if __name__ == "__main__":
    main()
