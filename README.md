# HypoQuantyl
Image analysis tool used for tracking localized growth of hypocotyls using high-throughput cloud computing. This program uses a variety of machine learning algorithms and neural networks to identify the shape of a hypocotyl, form a midline, and quantify localized rates of elongation at many different locations along that midline.

## Summary [re-iterate above description and expand on use, novelty, and similar software]
A) What is this program for? <br />
Learning algorithms: predict contour, predict ending of midline <br />
Image analysis: select points along seedling <br />
Quantification: Localized measurements of midline, model growth of growing seedlings <br />
Miscellaneous features: late-decision segmentation for error checking, ease of loading data <br />
Output Data: models full developmental process of a growing, de-etiolating hypocotyl <br />

B) How does this program work? <br />
User stores time-lapse image stacks of a single type in individual folders <br />
A full experiment is a set of individual image stacks in a parent folder <br />
Multiple experiments can be loaded as well <br />

C) Instructions for using HypoQuantyl can be found in [HOWTO.md](./HOWTO.md) <br />
    - Sample data can be found in [Sample Data](./SampleData) <br />

## Getting Started
### Dependencies
- Lowest usable MATLAB version
- Run scripts for toolbox dependencies (like from QuantDRaCALA)
- Maybe something about CyVerse if necessary?


### Installation
- (to-do) Install program as Matlab executable <br />
- (to-do) Program runs on CyVerse <br />

## Version Information
02/06/2018 - HypoQuantyl Version 0.5
06/24/2018 - HypoQuantyl Version 0.7

## Authors
### Main Author
**Julian Bustamante**, Cellular and Molecular Biology Program (<jbustamante@wisc.edu>) <br />
    University of Wisconsin - Madison <br />
    Department of Botany <br />

### Contributing Author
**Nathan Miller**, Senior Scientist (<ndmill@gmail.com>) <br />
    University of Wisconsin - Madison <br />
    Department of Botany <br />

## License
MIT license found in [LICENSE](./LICENSE) <br />

## Acknowledgements
- TBD

## To-Do:

### Main Classes
[ ] | Class | Description
--- | --- | ---
[ ] | HypoQuantyl | Initializes program and loads Experiment folders
[ ] | Experiment  | Loads folders containing multiple image stacks
[ ] | Genotype    | Loads image stacks containing growing seedlings
[ ] | Seedling    | Represents a single seedling throughout a time-lapse
[ ] | Hypocotyl   | Represents the hypocotyl portion of a single seedlings
[ ] | CircuitJB   | Main contour of a hypocotyl, segmented by anchor points
[ ] | Route       | Individual segments around a hypocotyl's contour

### Algorithms
[ ] | Algorithm | Description
--- | --- | ---
[ ] | FindHypocotyl        | Identifies region on a seedling containing the hypocotyl
[ ] | TrackHypocotyl       | Keeps track of hypocotyl during de-etiolation process
[ ] | FindGoodFrames       | Runs error-checking of each frame for each Seedling
[ ] | IntegrationAlgorithm | Integration method for measuring growing Hypocotyl

### Implementing to Cyber Infrastructure
[ ] | Infrastructure | Description
--- | --- | ---
[ ] | Create accounts     | University Network, CyVerse, HTCondor
[ ] | Set up submit files | Holds MATLAB MCR, HypoQuantyl, Data, I-Commands
[ ] | Run Test Data       | Run HypoQuantyl on Sample data on cloud computing environment
