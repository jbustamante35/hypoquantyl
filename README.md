# HypoQuantyl
An image processing and analysis tool for automated, high-throughput
measurements of hypocotyl growth kinematics.
*[publication currently under review]*

#### Growth Kinematics
Growth kinematics describes the spatial distribution of growth along a surface.
[In plants](https://www.sciencedirect.com/science/article/abs/pii/0022519379900146), we measure the rate of elongation of cells along different
regions of the stem. [Historically](https://onlinelibrary.wiley.com/doi/abs/10.1111/j.1365-3040.1982.tb00934.x), this has been done using [external markers
along the length of the stem](https://onlinelibrary.wiley.com/doi/10.1111/j.1365-3040.1993.tb00891.x). **HypoQuantyl** performs this by tracking the
movement of many distinct texture patches along the midline of the hypocotyl
over time. These patches, or 'elements,' represent segments of the stem, and
their expansion over time allows the software to calculate the rate of growth,
expressed as the Relative Elemental Growth Rate (REGR).


#### Machine Learning-Based Segmentation
HypoQuantyl provides an automated and robust segmentation process for each
frame in a time series of images and is capable of handling multiple
well-separated seedlings per image. The machine learning-based segmentation
pipeline accurately generates contours of the upper hypocotyl, resolves
cotyledon overlap, and precisely identifies and splits the contour at the
hypocotyl-cotyledon junction. This pipeline is self-correcting, ensuring
strong results. From this contour it then generates a midline used to
compute the REGR.

#### High-Throughput Capabilities
The automated nature of the processing and segmentation pipeline allowed us
to deploy onto the distributed computing servers provided by
[HTCondor](https://htcondor.org/). Using their servers we have completed
high-throughput analyses consisting of over 23,000 individual images.

### Highlights:
- **Input Images:** High-resolution time-lapse images of plant hypocotyls.
- **Processing Pipeline:** Automated segmentation using machine learning,
  followed by quantitative growth analysis.
- **Segmentation Pipeline:** Automated segmentation using machine learning,
  followed by quantitative growth analysis.
- **REGR Measurements:** Relative Elemental Growth Rate (REGR), expressed
  as %/hour, providing detailed insight into growth kinematics.

### Authors
##### Main Author
**Julian Bustamante**, Cellular and Molecular Biology Program (<jbustamante@wisc.edu>) <br />
    University of Wisconsin - Madison <br />
    Department of Botany <br />

##### Contributing Author
**Nathan Miller**, Senior Scientist (<ndmill@gmail.com>) <br />
    University of Wisconsin - Madison <br />
    Department of Botany <br />

#### Acknowledgements
**Guosheng Wu**: Generated the original image dataset to train models <br />

### License
MIT license found in [LICENSE](./LICENSE) <br />

---

### Getting Started
To use **HypoQuantyl**, ensure that your system meets the following
requirements:

- [**MATLAB Version**](https://www.mathworks.com/support/requirements/previous-releases.html) \
The tool was developed from **MATLAB R2018a** up to **R2022b**. Earlier
or later versions may work but not guaranteed.

- **MATLAB Toolboxes:** \
[Image Processing Toolbox](https://www.mathworks.com/products/image-processing.html) \
[Statistics and Machine Learning Toolbox](https://www.mathworks.com/products/statistics.html) \
[Parallel Computing Toolbox](https://www.mathworks.com/products/parallel-computing.html) \

#### Installation
##### [To-Do: how to use after installation]

1. Clone this repository:
   ```bash
   git clone https://github.com/jbustamante35/hypoquantyl.git
    ```

2. Install required MATLAB addons:
    ```matlab
    matlab.addons.install('Image Processing Toolbox')
    matlab.addons.install('Statistics and Machine Learning Toolbox')
    matlab.addons.install('Parallel Computing Toolbox')
    ```
3. Add repository with subfolders to MATLAB path
    ```matlab
    % Go to hypoquantyl repository
    path_to_hypoquantyl = '%PATH_TO_HYPOQUANTYL%';
    addpath(genpath(fileparts(which(path_to_hypoquantyl))));

    % Remove .git subfolder from path
    path_to_git = fprintf('%s/.git', path_to_hypoquantyl);
    rmpath(genpath(fileparts(which(path_to_git))))
    ```

---

### Core Classes and Algorithms
###### [To-Do: summarize of processing/segmentation/analysis pipelines]
#### [Classes](./classes)
| Class            | Description                                             |
| ---              | ---                                                     |
| Experiment       | Loads and processes folders containing image stacks     |
| Curve            | Raw data of segmented hypocotyl contours                |
| HypocotylTrainer | Implements learning models for segmentation             |
| PcaJB            | Implements functions for PCA on segmentation data       |
| OutlineFixer     | Refinement and repair of ground truth segmentation data |

#### [Algorithms](./helpers)
| Algorithm             | Description                                               |
| ---                   | ---                                                       |
| FindHypocotyl         | Identifies region on a seedling containing the hypocotyl  |
| TrackHypocotyl        | Keeps track of hypocotyl during de-etiolation process     |
| FindGoodFrames        | Runs error-checking of each frame for each Seedling       |
| IntegrationAlgorithm  | Integration method for measuring growing Hypocotyl        |

#### [Distributed Computing Servers](./repos/htcondor)
| Step                | Description                                                   |
| ---                 | ---                                                           |
| Create accounts     | University Network, CyVerse, HTCondor                         |
| Set up submit files | Holds MATLAB MCR, HypoQuantyl, Data, I-Commands               |
| Run Test Data       | Run HypoQuantyl on Sample data on cloud computing environment |
