Denoising MRI Scans Using a Deep Learning Approach - Code Execution Instructions.

Overview:
This project performs MRI denoising using a combination of Python and MATLAB.
Python is used to extract 2D slices from MRI volumes, add noise, and prepare dataset splits.
MATLAB is used to train a U-Net model, evaluate it, and run a GUI for visual testing.
The goal is to remove noise from MRI slices while preserving all the information.
Dataset Source:
The dataset used in this project is the publicly available IXI Brain Development Dataset, specifically the (IXI-T2) MRI scans – which we used.

Dataset download link:
https://brain-development.org/ixi-dataset/
After downloading the NIfTI (.nii or .nii.gz) files, place them inside the folder:
MedIm2025_Sravani_Dayana/MedIm2025_Code_Sravani_Dayana /IXI-T2/

Project Structure:
MedIm2025_Sravani_Dayana/
│
├── MedIm2025_Report_Sravani_Dayana.docx
│
├── MedIm2025_Code_Sravani_Dayana/
│   ├── IXI-T2/                                  # contains original NIfTI MRI dataset (Submitted EMPTY)
│   │     ├── clean_slices/                 (auto-created)
│   │     ├── noisy_slices/                 (auto-created)
│   │     └── splits_slices/                 (auto-created)
│   │
│   ├── nifti_to_slices.py                 # Converts 3D NIfTI MRI scans into 2D clean slices.
│   ├── make_noisy_slices.py         # Adds synthetic Rician noise to clean MRI slices.
│   ├── SPLIT.py            		    # Automatically generates train/validation/test split lists.
│   │
│   ├── train_unet2d_full_slices.m # Trains the U-Net model using the noisy/clean pairs.
│   ├── validation.m                       # Computes quality metrics (PSNR, SSIM, MSE, MAE) on test images.
│   ├── mri_denoise_gui_v2.m      # GUI for inference
│   │
│   ├──Artifacts/                            # Sample output images
│   │      ├── sample_clean.png
│   │      ├── sample_noisy.png
│   │      ├── sample_denoised.png
│   │      └── gui_screenshot.png
│   │
│   └──   ProjectFunctions/               # MATLAB helper functions
│             ├── buildPairsForAllSNR.m
│             ├── computeMetrics.m
│             ├── getCleanPathFromNoisy.m
│             ├── preprocessMiniBatch.m
│             └── readSliceAsSingle.m
│   
├── README.docx
│
└── MedIm2025_presentation_Sravani_Dayana.pptx
When the Python scripts are run, the following folders will be generated inside IXI-T2/:
IXI-T2/  
├── clean_slices/                   # Contains extracted 2D MRI slices
├── noisy_slices/                  # Contains noisy versions of the slices
└── splits_slices/                  # Contains train.txt, val.txt, and test.txt
Requirements: 
Python Requirements
Required libraries:
•	numpy
•	nibabel
•	matplotlib
•	scikit-image
•	opencv-python
run: ` pip install numpy nibabel matplotlib scikit-image opencv-python` to install required packages.
MATLAB Requirements
MATLAB must have the following toolboxes installed:
•	Deep Learning Toolbox
•	Image Processing Toolbox


Execution Steps
STEP 1 – Convert NIfTI to Clean 2D Slices
Run the following command:
`python nifti_to_slices.py`
This script reads each NIfTI file in IXI-T2/ and generates clean 2D slices.
The output will be saved in:
IXI-T2/clean_slices/<SubjectName>/<SubjectName>_axial_kXXX.png
Example: “IXI-T2/clean_slices/IXI002/IXI002_axial_k001.png”

STEP 2 – Add Noise to Slices
Run the following command:
`python make_noisy_slices.py`
This script creates noisy versions of the clean slices at different noise levels.
The following folders will be created:
•	IXI-T2/noisy_slices/rician_snr10/
•	IXI-T2/noisy_slices/rician_snr15/
•	IXI-T2/noisy_slices/rician_snr20/
•	IXI-T2/noisy_slices/rician_snr30/

STEP 3 – Create training, validation, and testing splits
Run the following command:
`python SPLIT.py`
This script creates three text files:
•	train.txt
•	val.txt
•	test.txt
These are saved under ‘IXI-T2/splits_slices/’ and MATLAB uses these lists during training.

MATLAB Pipeline
Make sure MATLAB’s working directory is set to the MedIm2025_Sravani_Dayana/ MedIm2025_Code_Sravani_Dayana/ folder.

STEP 4 – Train the U‑Net Model
Run the following command:
`train_unet2d_full_slices`
This script trains the U-Net using the noisy images as input and the clean images as labels. At the end of training, a model file will be created: “unet2d_denoise.mat”

STEP 5 – Validate the Model
Run the following command:
`validation`
This evaluates the denoising performance and shows metrics such as MSE, MAE, PSNR, and SSIM. Results are shown before and after denoising for comparison.

STEP 6 – Run the GUI
Run the following command:
`mri_denoise_gui_v2`
The GUI allows you to load noisy images, run the U-Net model to denoise it and compare noisy, denoised, and clean images. It also view quantitative metrics and saves images or reports generated.

Authors
Sravani Kotha – MSc Computer Science 
University of Houston

Dataset Source: https://brain-development.org/ixi-dataset/
http://biomedic.doc.ic.ac.uk/brain-development/downloads/IXI/IXI-T2.tar
