# matlab
MATLAB scripts and functions

Installation:

1) Log into a GPU node on the Maxwell cluster

2) Download latest MATLAB files from Github: 
    git clone https://github.com/moosmann/matlab.git

3) cd matlab

4) Start MATLAB with './startmatlab.sh', see below.



How to start a reconstruction:

1) chmod +x startmatlab.sh

2) ./startmatlab.sh
    This sets environment variables in order to use a local installation of 
    the ASTRA toolbox, starts MATLAB, and sets the search path (this 
    overwrites local user settings, for details see 'startup.m'_)

3) Open 'p05_reco' in MATLAB located at './matlab/experiments/p05/', eg 
    type 'edit p05_reco' in MATLAB's command line

4) Check and modify reconstruction parameters, at least 'scan_path'

5) Start reconstruction by one of the following:
    - Type 'p05_reco' in MATLAB's command line
    - Click 'RUN' button in editor tab
    - Type 'F5' key when focus is in the 'p05_reco' file    -


How to set up automized reconstruction loop:

1) Make a copy of 'p05_reco_template.m', open the copy, and follow the 
    instructions within the help.

2) Adjust default parameter section: modify, delete, or copy parameter 
    from 'p05_reco'

3) Add data or parameter sets and run file.



