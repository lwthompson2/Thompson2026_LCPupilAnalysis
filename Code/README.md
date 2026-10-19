LCPupil Joshi Analysis: DANDI-First Reproducibility

This repository reproduces the LC-pupil analyses and manuscript-style summary statistics from cleaned trial-separated session data.

Related publication:
https://elifesciences.org/reviewed-preprints/112525

Data source

Download Dandiset `002034` from DANDI version `0.261019.2146`, then place it as a local folder named `002034` at the repository root.

Dandiset page:
https://dandiarchive.org/dandiset/002034/0.261019.2146

From the repository root, run:

```bash
python3 -m pip install dandi
dandi download dandi://dandi/002034@0.261019.2146
```

Expected local layout:

```text
<repo_root>/002034/sub-Cicero/*.nwb
<repo_root>/002034/sub-Oz/*.nwb
```

If you use a different location, update `paths.nwb_root` in [Code/config_paths.m](config_paths.m).

Required tools

1. MATLAB R2023b (or compatible) with Statistics and Machine Learning Toolbox.
2. MatNWB installed in your MATLAB environment (on the MATLAB path).

Reproducing outputs from manuscript

1. Clone the repository.
2. Ensure the downloaded Dandiset is located at `<repo_root>/002034` (or change `paths.nwb_root` in [Code/config_paths.m](config_paths.m)).
3. In MATLAB, run:

```matlab
main;
```

Key outputs

1. [Code/Results/LC_data_raw.mat](Results/LC_data_raw.mat)
2. [Code/Results/LC_data_zscored.mat](Results/LC_data_zscored.mat)
3. [Code/Results/manuscript_stats_nwb.txt](Results/manuscript_stats_nwb.txt)



