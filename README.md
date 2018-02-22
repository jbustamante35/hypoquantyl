# HypoQuantyl
Image analysis tool used for tracking localized growth of hypocotyls in a high-throughput manner. This program uses a machine learning algorithm to identify the hypocotyl and quantifies the rate of elongation at many different locations along the midline.

## Summary
A) What is this program for? <br />
B) How does this program work? <br />
C) Instructions for using HypoQuantyl can be found in [HOWTO.md](./HOWTO.md) <br />
    - Sample data can be found in [Sample Data](./SampleData) <br />

## Getting Started
### Dependencies
- Lowest usable MATLAB version
- Run scripts for toolbox dependencies




### Installation
- (to-do) Install program as Matlab executable <br />
- (to-do) Program runs on CyVerse <br />

## Version Information
02/06/2018 - HypoQuantyl Version 0.5


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
[ ] | Create accounts     | Univeristy Network, CyVerse, HTCondor
[ ] | Set up submit files | Holds MATLAB MCR, HypoQuantyl, Data, I-Commands
[ ] | Run Test Data       | Run HypoQuantyl on Sample data on cloud computing environment
