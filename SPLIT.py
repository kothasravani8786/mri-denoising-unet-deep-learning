# SPLIT.py
# This script splits the clean PNG slices into training, validation, and test sets.
# The split is done at the SUBJECT level (not slice level) so that all slices
# from the same subject stay together and do not leak across splits.
# The script creates three text files (train.txt, val.txt, test.txt)
# listing the full paths of the slices in each split.

import random
from pathlib import Path

# Base folder where the cleaned and sliced PNG images are stored
ROOT = Path(r"C:\WorkSpace\external\FMI\IXI-T2")

# Folder that contains subject-wise folders of clean PNG slices
CLEAN_SLICES = ROOT / "clean_slices"

# Output folder where the split text files will be written
SPLITS_DIR = ROOT / "splits_slices"

# Ratios for train, validation, and test splits
RATIOS = (0.8, 0.1, 0.1)

# Seed for reproducibility so the split is always the same
SEED = 42


def main():
    """
    Main function to perform subject-level splitting of dataset.

    Steps:
      1. Get a list of all subject directories.
      2. Shuffle them randomly using a fixed seed.
      3. Split them according to RATIOS.
      4. For each split, gather all PNG files and save their paths into a .txt file.
    """

    # Get list of subject folders (each folder contains slices for one subject)
    subs = sorted([d for d in CLEAN_SLICES.iterdir() if d.is_dir()])

    # Shuffle subjects to avoid any ordering bias
    random.seed(SEED)
    random.shuffle(subs)

    # Compute number of subjects per split
    n = len(subs)
    n_tr = int(n * RATIOS[0])
    n_va = int(n * RATIOS[1])

    # Assign subjects to train, val, and test groups
    tr = subs[:n_tr]
    va = subs[n_tr:n_tr + n_va]
    te = subs[n_tr + n_va:]

    # Ensure output directory exists
    SPLITS_DIR.mkdir(parents=True, exist_ok=True)

    # Write file lists for each split
    for name, group in [("train.txt", tr), ("val.txt", va), ("test.txt", te)]:
        paths = []

        # Gather all PNG slice paths for each subject in the group
        for sd in group:
            paths += [str(p) for p in sorted(sd.glob("*.png"))]

        # Write paths into a text file (one path per line)
        with open(SPLITS_DIR / name, "w") as f:
            f.write("\n".join(paths))

        print(name, len(paths), "slices")


if __name__ == "__main__":
    main()
