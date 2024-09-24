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

### Pipeline Overview:
1) **Input**: High-resolution time-lapse image sequence of *A. thaliana*
    hypocotyls *[see example image below]*
   - Image resolution should be high enough such that natural texture along the
     seedling are clearly visible
   - Observed growth between frames should not exceed >20 pixels to ensure
     accurate tracking*
   - Filename convention is *condition*_*genotype*_t*frame*.TIF </br>
     **e.g.** </br>
     > *blue_cry1_t020.TIF* </br>

     references the 20th frame of a *cry1* mutant under
     blue light conditions
   - Directory structure is a directory tree containing inner subfolders
     organized as so: </br>
     > &rarr; *condition* </br>
     >>  &rarr; *genotype* </br>
     >>>  &rarr; *image stacks* </br>
     >>>>  &rarr; *image frames* </br>

     **e.g.** </br>
     > &rarr; [conditions] </br>
       *dark* </br>
     >> &rarr; [genotypes]</br>
        *cry1* </br>
     >>> &rarr; [image stacks] </br>
         *001_dark_cry1* </br>
     >>>> &rarr; [image frames] </br>
          *dark_cry1_t001.TIF* </br>
          *dark_cry1_t002.TIF* </br>
          *dark_cry1_t003.TIF* </br>

2) **Image Processing:** Grayscale thresholding and basic object
    detection organizes and prepares seedlings for segmentation
   - Hypocotyls are isolated and split into upper and lower regions

3) **Segmentation Pipeline:** Automated self-correcting segmentation method
    that implements a two-part machine learning algorithm to generate a contour and
    its midline from the upper region hypocotyl images.**
   - **Part 1** of ML segmentation 'seeds' the image with reference points for </br>
     **Part 2**, which identifies contour points </br>
   - The quality of the output from **Part 2** is evaluated by a grading
     function. If the grade does not meet a threshold, it is piped back into
     the segmentation pipeline to retry with adjusted parameters and
     re-evaluated. This repeats until the quality threshold is met or after a
     set number of retries.

4) **REGR Measurements:** Quantitative analysis Relative Elemental Growth Rate (REGR), expressed
as %/hour, providing detailed insight into growth kinematics.

<p style="font-size: 12px;"><em>
* 20 pixels was the threshold for our purposes, but the actual limit is*
*likely much larger* </br>
** The Segmentation Pipeline is only done on upper region images; lower
*regions are segmented using basic grayscale thresholding.
</em></p>

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
**Guosheng Wu**: Generated the original image dataset to train early machine
learning models <br />

### License
MIT license found in [LICENSE](./LICENSE) <br />

---

### Getting Started
To use **HypoQuantyl**, ensure that your system meets the following
requirements:

- [**MATLAB Version**](https://www.mathworks.com/support/requirements/previous-releases.html) \
This tool was developed from **MATLAB R2018a** up to **R2022b**. Earlier
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
