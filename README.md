
# HypoQuantyl
An image processing and analysis tool for automated, high-throughput measurements of hypocotyl growth kinematics. [*Publication currently under review*]

---

## Growth Kinematics
Growth kinematics describes the spatial distribution of growth along a surface.
In plants, this refers to the rate of elongation of cells along different regions of the stem. Historically, this has been measured using external markers along the stem's length.
**HypoQuantyl** achieves this by tracking distinct texture patches along the midline of the hypocotyl over time. These patches, or 'elements,' represent stem segments, and their expansion allows the software to calculate growth rates expressed as the Relative Elemental Growth Rate (REGR).

---

## Machine Learning-Based Segmentation
HypoQuantyl provides an automated and robust segmentation process for each frame in a time series of images and is capable of handling multiple well-separated seedlings per image.
The machine learning-based segmentation pipeline generates contours of the upper hypocotyl, resolves cotyledon overlap, and identifies and splits the contour at the hypocotyl-cotyledon junction.
The system is self-correcting, ensuring reliable results. From the contour, it generates a midline used to compute REGR.

---

## High-Throughput Capabilities
The automated nature of the processing and segmentation pipeline allows deployment on distributed computing servers provided by [HTCondor](https://htcondor.org/). Using these servers, we have analyzed over 23,000 individual images in a high-throughput manner.

---

## Pipeline Overview:
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

2. **Image Processing**:
   - Grayscale thresholding and basic object detection prepare the seedlings
     for segmentation.
   - Hypocotyls are isolated and split into upper and lower regions. \**

3. **Segmentation Pipeline**:
   - **S-Phase**: A 'seeding' phase where a convolutional neural network (CNN)
     initializes the grayscale image with reference frames.
   - **C-Cycle**: A recursive feed-forward neural network loop that predicts
     'Contour' points based on the S-Phase reference frames and image data.
   - **R-Cycle**: A refinement loop that evaluates the output through a
     minimization function. The 'grade' is the probability that the output is
     within bounds of the ground truth dataset. If the threshold isn't met,
     the process is retried with adjustments.

4. **REGR Measurements**:
   - Calculates the Relative Elemental Growth Rate (REGR), expressed as %/hour, to provide insight into growth kinematics.

\* *20 pixels is the threshold used for our purposes, but the actual limit may be higher.* </br>
\** *The segmentation pipeline processes only the upper region; lower regions are segmented using basic grayscale thresholding.*

---

## Authors
**Julian Bustamante**, Cellular and Molecular Biology Program (<jbustamante@wisc.edu>)
University of Wisconsin - Madison, Department of Botany

**Nathan Miller**, Senior Scientist (<ndmill@gmail.com>)
University of Wisconsin - Madison, Department of Botany

---

## Acknowledgements
**Guosheng Wu**: Generated the original image dataset used to train early machine learning models.

---

## License
MIT license can be found in the [LICENSE](./LICENSE) file.

---

## Getting Started
To use **HypoQuantyl**, ensure your system meets the following requirements:

- **MATLAB Version**:
  This tool was developed for MATLAB R2018a to R2022b. Other versions may work but are not guaranteed.

- **Required MATLAB Toolboxes**:
  - [Image Processing Toolbox](https://www.mathworks.com/products/image-processing.html)
  - [Statistics and Machine Learning Toolbox](https://www.mathworks.com/products/statistics.html)
  - [Parallel Computing Toolbox](https://www.mathworks.com/products/parallel-computing.html)

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/jbustamante35/hypoquantyl.git
   ```

2. Install the required MATLAB toolboxes:
   ```matlab
   matlab.addons.install('Image Processing Toolbox')
   matlab.addons.install('Statistics and Machine Learning Toolbox')
   matlab.addons.install('Parallel Computing Toolbox')
   ```

3. Add the repository to the MATLAB path:
   ```matlab
   path_to_hypoquantyl = '%PATH_TO_HYPOQUANTYL%';
   addpath(genpath(fileparts(which(path_to_hypoquantyl))));

   % Remove .git folder from the path
   rmpath(genpath([path_to_hypoquantyl, '/.git']));
   ```

---

## Core Classes and Algorithms
### Classes
| Class                | Description                                              |
| ----------------     | ----------------------------------------------------     |
| **Experiment**       | Loads and processes folders containing image stacks      |
| **Curve**            | Raw data of segmented hypocotyl contours                 |
| **HypocotylTrainer** | Implements machine learning models for segmentation      |
| **PcaJB**            | Principal Component Analysis (PCA) for segmentation data |
| **OutlineFixer**     | Refinement and repair of ground truth segmentation data  |

### Algorithms [to-do]
| Algorithm                | Description                                                    |
| --------------------     | ------------------------------------------------               |
| **FindHypocotyl**        | Identifies the region of the seedling containing the hypocotyl |
| **TrackHypocotyl**       | Tracks the hypocotyl during de-etiolation                      |
| **FindGoodFrames**       | Runs error-checking for each frame of each seedling            |
| **IntegrationAlgorithm** | Measures growth of the hypocotyl through integration           |

---

## Distributed Computing Servers [to-do]
### Steps
| Step                    | Description                                                        |
| --------------------    | -------------------------------------------------                  |
| **Create accounts**     | Set up accounts for University Network, CyVerse, and HTCondor      |
| **Set up submit files** | Prepare MATLAB MCR, HypoQuantyl, data, and I-Commands              |
| **Run Test Data**       | Test HypoQuantyl on sample data using cloud computing environments |


