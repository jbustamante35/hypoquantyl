# HypoQuantyl
An image processing and analysis tool for automated, high-throughput
measurements of hypocotyl growth kinematics. [*Publication currently under
review*]

#### Growth Kinematics
Growth kinematics describes the spatial distribution of growth along a surface.
In plants, this refers to the rate of elongation of cells along different
regions of the stem. Historically, this has been measured using external
markers along the stem's length. **HypoQuantyl** achieves this by tracking
distinct texture patches along the midline of the hypocotyl over time. These
patches, or 'elements,' represent stem segments, and their expansion allows
the software to calculate growth rates expressed as the Relative Elemental
Growth Rate (REGR).

#### Machine Learning-Based Segmentation
HypoQuantyl provides an automated and robust segmentation process for each
frame in a time series of images and is capable of handling multiple well-
separated seedlings per image. The machine learning-based segmentation pipeline
generates contours of the upper hypocotyl, resolves cotyledon overlap, and
identifies and splits the contour at the hypocotyl-cotyledon junction. The
system is self-correcting, ensuring reliable results. From the contour, it
generates a midline used to compute REGR.

#### High-Throughput Capabilities
The automated nature of the processing and segmentation pipeline allows
deployment on distributed computing servers provided by
[HTCondor](https://htcondor.org/). Using these servers, we have analyzed over
23,000 individual images in a high-throughput manner.

---

#### Pipeline Overview:
1. **Input**: High-resolution time-lapse image sequence of *A. thaliana*
   hypocotyls.
   - Image resolution must clearly capture natural textures along the
     seedling.
   - Growth between frames should not exceed 20 pixels for accurate tracking.\*
   - **Filename convention**: *condition_genotype_tframe.TIF*
     **Example**: `blue_cry1_t020.TIF` refers to the 20th frame of a *cry1*
     mutant under blue light conditions.
   - **Directory structure**:
     - `condition/genotype/image stacks/image frames/`
     **Example**:
     - `conditions/dark/genotypes/cry1/image stacks/001_dark_cry1/image
       frames/dark_cry1_t001.TIF`

2. **Image Processing**: Grayscale thresholding and basic object detection to
prepare the seedlings for segmentation.
   - Hypocotyls are isolated and split into upper and lower regions. \**

4. **Segmentation Pipeline**: A 3-stage machine learning pipeline generates the
   midline used to measure growth kinematics.
   - **S-Phase**: A 'seeding' phase where a convolutional neural network (CNN)
     initializes the grayscale image with reference frames.
   - **C-Cycle**: A recursive feed-forward neural network loop that predicts
     'Contour' points based on the S-Phase reference frames and image data.
   - **R-Cycle**: A refinement loop that evaluates the output through a
     minimization function. The 'grade' is the probability that the output is
     within bounds of the ground truth dataset. If the threshold isn't met,
     the process is retried with adjustments.

6. **REGR Measurements**: Calculates the Relative Elemental Growth Rate (REGR) -
   - Expressed as a %/hour to describe how 'elements' moved away from the top
     or apex of the seedling.

\* *20 pixels is the threshold used for our purposes, but the actual limit may be higher.* </br>
\** *The segmentation pipeline processes only the upper region; lower regions are segmented using basic grayscale thresholding.*

---

#### Authors
**Julian Bustamante**, Graduate Researcher in Cellular and Molecular Biology
(<jbustamante@wisc.edu>) \\
University of Wisconsin - Madison, Department of Botany

**Nathan Miller**, Senior Scientist (<ndmill@gmail.com>) \\
University of Wisconsin - Madison, Department of Botany

#### Acknowledgements
**Guosheng Wu**: Generated the original image dataset used to train early
machine learning models.

#### License
MIT license can be found in the [LICENSE](./LICENSE) file.

---

#### Getting Started
To use **HypoQuantyl**, ensure your system meets the following requirements:

- **MATLAB Version**:
  This tool was developed for MATLAB R2018a to R2022b. Other versions may
  work but are not guaranteed.

- **Required MATLAB Toolboxes**:
  - [Curve Fitting Toolbox](https://www.mathworks.com/products/curvefitting.html)
  - [Global Optimization Toolbox](https://www.mathworks.com/products/global-optimization.html)
  - [Image Processing Toolbox](https://www.mathworks.com/products/image-processing.html)
  - [Mapping Toolbox](https://www.mathworks.com/products/mapping.html)
  - [Parallel Computing Toolbox](https://www.mathworks.com/products/parallel-computing.html)
  - [Sensor Fusion and Tracking Toolbox](https://www.mathworks.com/products/sensor-fusion-and-tracking.html)
  - [Signal Processing Toolbox](https://www.mathworks.com/products/signal.html)
  - [Statistics and Machine Learning Toolbox](https://www.mathworks.com/products/statistics.html)
  - [Symbolic Math Toolbox](https://www.mathworks.com/products/symbolic.html)
  - [Wavelet Toolbox](https://www.mathworks.com/products/wavelet.html)

- Clone the repository:
   ```bash
   git clone https://github.com/jbustamante35/hypoquantyl.git
   ```

- Install the required MATLAB toolboxes listed above. Check using the
  following command in the Matlab console:
   ```matlab
   matlab.addons.installedAddons;
   ```

### Running HypoQuantyl
1. Add this repository to your MATLAB path (**NOTE!** make sure to remove the
   .git subfolder to avoid a messy path)

2. Download example image stacks in our lab's [Google Drive folder](https://drive.google.com/drive/folders/1FcC6anjcwPGbj-CnBY_zGDb0h_jTO3DV?usp=sharing).
     - Image data are time-lapse image stacks of the following:
        - Single *cry1* mutant seedling grown in darkness *[91 MB]*
        - Five *wt* seedlings grown in blue light after 2 hrs in darkness *[20 MB]*

4. Download the **HQ.mat** dataset containing neural net models, PCA
   eigenvectors, helper function handles, and constants required to run this
   program *[62 MB]*.

5. Open [*hypoquantyl_script.m*](./hypoquantyl_script.m) in the matlab editor to set input parameters,
   point to image stack folder, and set output destination folder.

6. Run HypoQuantyl.m [to-do]



