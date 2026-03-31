# PharmaSUG 2026 - Paper AS-359
## Beyond Imitation: Selecting Synthetic Data with Purpose and Precision

This repository contains helper programs forming the basis of the PharmaSUG 2026 paper AS-359: Beyond Imitation: Selecting Synthetic Data with Purpose and Precision.

This repository shall be expanded closer to the conference.  As PharmaSUG (May - June 2026) draws nearer, we shall receive a more concrete agenda and links to the paper when published, all of which shall be updated here.

## SAS Programs
### Example Programs to illustrate the approach followed

1. [Program 1](./Program1.sas): Simple example which balances all RACES in the DM dataset to be ~500 observations (changeable) each

2. [Program 2](./Program2.sas): Example with RACE balanced, and to enforce an average Age of 70 years (assuming the study tackles an older participation range) across all race groups

3. [Program 3](./Program3.sas): Example with RACE balanced, and to use a dataset with a distribution of collection prior to study record date (DMDY in the DM domain) set at 7 days.  Usually guided or suggested by study protocol criteria, this can be viewed as an efficiency exercise to help identify any poor data flow (**always relative to study design**) and may point to delayed subject registration, late demographic reconciliation or slow data capture.
