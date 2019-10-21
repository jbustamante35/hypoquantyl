# Synthetic Data
This directory contains the scripts needed to generate synthetic hypocotyls to
inflate the training data set. The general mechanism for how it works is that
it searches the existing training set for subsets of contours that have a
specified shape and size, such that the base of the sub-contour (or segment) is
anchored near the base of the contour (i.e. has no base). Segments that meet
this criteria are stored in a _Curve Bank_ that we can draw from to generate
the inflated training set.

## Replacing Hypocotyl Sections
You can replace parts of a hypocotyl by selecting the section to cut off, and
replacing that section with a segment from the _Curve Bank_.


## Cleanup and Refactoring
As of 10.18.2019, I have not yet finished cleaning up and refactoring these
scripts. They still need quite a bit of tweaking to get it working the way we
want, and so I haven't gotten around to going through them and re-writing them
in my style.

