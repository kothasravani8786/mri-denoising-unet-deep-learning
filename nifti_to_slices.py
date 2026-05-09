# nifti_to_slices.py
# This script reads all NIfTI (.nii/.nii.gz) files from the IXI dataset,
# rescales them, converts each volume into individual axial PNG slices,
# and finally generates a CSV file listing all slices produced.

import re, csv
from pathlib import Path
import numpy as np
import nibabel as nib
from PIL import Image

# Root folder where the IXI T2 NIfTI files are stored
ROOT = Path(r"C:\WorkSpace\external\FMI\IXI-T2")

# Folder containing clean NIfTI files (same as ROOT here)
CLEAN_NIFTI_DIR = ROOT

# Output folder where PNG slices will be saved
OUT_DIR = ROOT / "clean_slices"
OUT_DIR.mkdir(parents=True, exist_ok=True)

# Regular expression to extract subject ID, site, acquisition number, and sequence
pat = re.compile(r"^(IXI\d+)-([A-Za-z]+)-(\d+)-([A-Za-z0-9]+)\.nii(\.gz)?$")


def robust_rescale(vol):
    """
    Rescales a 3D MRI volume to the range [0, 1].

    This function finds the 1st and 99th percentile of finite values
    and uses that range to normalize the whole volume. This reduces
    the effect of extreme outliers.
    
    Parameter:
        vol (numpy.ndarray): 3D MRI volume.

    Returns:
        numpy.ndarray: rescaled volume in [0,1].
    """

    # Only look at real numeric values
    finite = np.isfinite(vol)

    # Get the lower and upper intensity percentiles
    lo, hi = np.percentile(vol[finite], [1, 99])

    # If something goes wrong, fall back to absolute min/max
    if hi <= lo:
        lo, hi = float(np.nanmin(vol)), float(np.nanmax(vol))

    # Clip and normalize the values to [0,1]
    return np.clip((vol - lo) / max(hi - lo, 1e-6), 0, 1)


def to_uint8(img01):
    """
    Converts a floating-point image in [0,1] to an 8-bit (0–255) image.
    This is needed because PNG saving requires uint8 format.

    Parameter:
        img01 (numpy.ndarray): image with values between 0 and 1.

    Returns:
        numpy.ndarray: uint8 image.
    """

    return (img01 * 255.0 + 0.5).astype(np.uint8)


def parse_name(p):
    """
    Extracts subject metadata from a NIfTI filename using a regex pattern.

    Parameter:
        p (Path): Path object pointing to a NIfTI file.

    Returns:
        dict or None: Returns subject info if the filename matches,
                      otherwise returns None.
    """

    m = pat.match(p.name)
    if not m:
        return None

    return dict(
        subj=m.group(1),
        site=m.group(2),
        acq=m.group(3),
        seq=m.group(4),
    )


def main():
    """
    Main function that:
      - scans through all NIfTI files,
      - loads each volume,
      - rescales it,
      - slices it along the axial direction,
      - saves each slice as PNG,
      - and finally builds a manifest CSV file listing all slices.
    """

    rows = []  # This will store info for manifest.csv

    # Loop through every .nii or .nii.gz file in the directory
    for nii in sorted(CLEAN_NIFTI_DIR.glob("*.nii*")):

        # Extract subject information from filename
        meta = parse_name(nii)
        if not meta:
            print(f"Skip (name mismatch): {nii.name}")
            continue

        # Load NIfTI file as a float32 array
        vol = nib.load(str(nii)).get_fdata(dtype=np.float32)

        # Normalize intensities
        vol = robust_rescale(vol)

        # Total number of slices along the axial (z) direction
        z = vol.shape[2]

        # Each subject gets their own folder
        subj_dir = OUT_DIR / meta["subj"]
        subj_dir.mkdir(parents=True, exist_ok=True)

        # Save each slice as a PNG image
        for k in range(z):
            sl = vol[:, :, k]
            png = subj_dir / f'{meta["subj"]}_axial_k{str(k).zfill(3)}.png'

            # Save slice as grayscale PNG
            Image.fromarray(to_uint8(sl)).save(png)

            # Store metadata for this slice
            rows.append({
                "subject": meta["subj"],
                "site": meta["site"],
                "seq": meta["seq"],
                "depth": z,
                "slice_k": k,
                "png_path": str(png),
                "nii_path": str(nii),
            })

        print(f"Wrote {z} slices for {nii.name}")

    # Create a manifest CSV listing all slices
    man = ROOT / "manifest.csv"
    with open(man, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=rows[0].keys())
        w.writeheader()
        w.writerows(rows)

    print(f"Manifest: {man} (rows={len(rows)})")


# Entry point of the script
if __name__ == "__main__":
    main()
