function MakeParFileForAPS(StartEndVoxels,NumOfFirstAndLastProjection,EffectivePixelSize,AngleBetweenProjections,ParentPath,DataSet,TomosForRotAxis,InputFolderPrefix)
% Make par files for all data set contained in IntParentPath/data/. Rotation
% axis is computed automatically using quali images and image correlation.
% The volume to reconstruct can be set as an cell array defining start and
% end voxels.
%
% StartEndVoxels: scalar (0=default), or 2x3-vector defining the volume to be
% reconstructed: [[START_VOXEL];[END_VOXEL]]. If 0 the whole volume(s) will
% be reconstructed.
% NumOfFirstAndLastProjection: 1x2-vector, number of the first and the last
% projection that are used for tomographic reconstruction.
% EffectivePixelSize: effective pixel size of the projections given in
% microns.
% IntParentPath: path to the parent folder containing the subfolders where the
% raw data, the flat-and-dark-field corrected intensities (int), the
% retrieved phases (phase), and the tomographic projections (vol) are
% stored.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Default arguments
if nargin < 1
    % For new data sets use StartEndVoxels = 0.
    StartEndVoxels = -1;
end
if nargin < 2
    % [FirstProjectionToUse LastProjectionToUse NumberOfProjectionsOverFullAngle]
    NumOfFirstAndLastProjection = [1 1200];
end
if nargin < 3
    EffectivePixelSize = 2.2;
end
if nargin < 4
    AngleBetweenProjections = 180/1200;
end
if nargin < 5
    % String: trailing seperator ('/') not needed. Parent path containing
    % the subfolder where the intensity images are found over which will be
    % looped over. By default only subfolder starting with tomo are used. 
   ParentPath = '/mnt/tomoraid-LSDF/tomo/APS_2BM_LifeCellImaging_GUP28266/lifecellimaging/test';
end
if nargin < 6
      DataSet = 'wildtype_30keV_10min_deadtime_25tomo_stage11p0_upwards_620mm_015ms';  
end
if nargin < 7
    TomosForRotAxis = [1 2 4 6 7 8 9 11 12];
end
if nargin < 8
    % 0 (default), or string: part of prefix of data folder names. If set 0
    % the prefix is assumed to be the same as that of 'IntParentPath'.
    InputFolderPrefix = 'tomo';
end
if nargin < 11
    PreProcessingFolder = 'int_filtLineSectionMedWidthH063V001_noCropping';
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ParentPath(end) ~= '/'
    ParentPath = [ParentPath '/'];
end
IntParentPath = [ParentPath 'int/' DataSet];
if IntParentPath(end) == '/'
    IntParentPath = IntParentPath(1:end-1);
end
%% Number of first and last projections of the tomograms
NUM_FIRST_IMAGE = NumOfFirstAndLastProjection(1,1);
NUM_LAST_IMAGE  = NumOfFirstAndLastProjection(1,2);
ANGLE_BETWEEN_PROJECTIONS = AngleBetweenProjections;
% Pixel size.
IMAGE_PIXEL_SIZE = EffectivePixelSize;
%% Read folder names of all tomo sets.
% Check path string ending.
if IntParentPath(end) == '/'
    IntParentPath = IntParentPath(1:end-1);
end
if InputFolderPrefix == 0
    TomoFolderNames      = dir([IntParentPath '/tomo*']);
    TomoFolderNames(1:2) = [];
else
    TomoFolderNames = dir([IntParentPath '/' InputFolderPrefix '*']);
end
% Get parent path.
[ParentPath DataSetName] = fileparts(IntParentPath);
IntParentPath    = [IntParentPath '/'];
ParentPath       = fileparts(ParentPath);
%% Folder names of different phase retrieval methods.
PhasePath  = [ParentPath '/phase/' DataSetName];
PhasePath  = [PhasePath '/'];
PhaseSubDirNames = dir([PhasePath '*alpha*']);
NumPhaseSubFolders = numel(PhaseSubDirNames);
%% Output path.
OutputPath = [ParentPath '/vol/' DataSetName];
OutputPath = [OutputPath '/'];
%warning('off','MATLAB:MKDIR:DirectoryExists');
if ~exist(OutputPath,'dir')
    mkdir(OutputPath);
end
%% Volume to reconstruct.
% If StartVoxel is zero, the whole volume will be reconstructed.
if StartEndVoxels < 0
    StartEndVoxels = ReadCroprangeTomo(OutputPath);
end
if StartEndVoxels(1) > 0
    START_VOXEL_1 = StartEndVoxels(1,1);
    START_VOXEL_2 = StartEndVoxels(1,2);
    START_VOXEL_3 = StartEndVoxels(1,3);
    END_VOXEL_1   = StartEndVoxels(2,1);
    END_VOXEL_2   = StartEndVoxels(2,2);
    END_VOXEL_3   = StartEndVoxels(2,3);  
end
%% Volume to reconstruct.
% If StartVoxel is zero, the whole volume will be reconstructed.
if StartEndVoxels < 0
    StartEndVoxels = ReadCroprangeTomo(OutputPath);
end
if StartEndVoxels(1) > 0
    START_VOXEL_1 = StartEndVoxels(1,1);
    START_VOXEL_2 = StartEndVoxels(1,2);
    START_VOXEL_3 = StartEndVoxels(1,3);
    END_VOXEL_1   = StartEndVoxels(2,1);
    END_VOXEL_2   = StartEndVoxels(2,2);
    END_VOXEL_3   = StartEndVoxels(2,3);  
end
% Total number of tomograms.
NumTomos = numel(TomoFolderNames);
if TomosForRotAxis == 0
    TomosForRotAxis = 1:NumTomos;
end
NumTomosForRotAxis = numel(TomosForRotAxis);
fprintf('\nPAR FILE CREATION FOR PyHST\n')
fprintf('DATA SET: %s\n',DataSetName)
fprintf('OUTPUT PATH: %s\n',OutputPath)
fprintf('DETERMINE AXIS OF ROTATION USING %u DATA SETS: %s\n',NumTomosForRotAxis,mat2str(TomosForRotAxis))
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Loop over intensity tomograms and determine Axis of Rotation.
RotAxisPos = zeros(NumTomosForRotAxis,1);
for tomoNum = 1:NumTomosForRotAxis
    fprintf(' Tomo scan number: %2u.',tomoNum)
    FILE_PREFIX = sprintf('%s%s/int_',IntParentPath,TomoFolderNames(TomosForRotAxis(tomoNum)).name);
    im1         = pmedfread(sprintf('%s%04u.edf',FILE_PREFIX,NUM_FIRST_IMAGE))';
    im2         = fliplr(pmedfread(sprintf('%s%04u.edf',FILE_PREFIX,NUM_LAST_IMAGE))');
    out         = ImageCorrelation(im1,im2,0,0);
    RotAxisPos(tomoNum)  = out.VerticalRotationAxisPosition;
    %% Image dimensions.
    [PixelsVer PixelsHor] = size(im1);
    fprintf('Rot. axis pos.: %f.',RotAxisPos(tomoNum))
    fprintf('Horz. center pos.: %g.',PixelsHor/2)
    fprintf('Dim. of proj.: [ver x hor] = [%u %u].\n',PixelsVer,PixelsHor)
end
RotAxisPos = mean(RotAxisPos(:));
fprintf('MEAN POSITION OF ROTATION AXIS: %f\n',RotAxisPos)
%% Volume to reconstruct.
% If StartVoxel is zero, the whole volume will be reconstructed.
if StartEndVoxels(1) == 0
    START_VOXEL_1 = 1;
    START_VOXEL_2 = 1;
    START_VOXEL_3 = 1;
    END_VOXEL_1   = PixelsHor;
    END_VOXEL_2   = PixelsHor;
    END_VOXEL_3   = PixelsVer;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PAR FILE FOR INTENSITY DATA.
NumIntSets = 0;
for tomoNum = 1:NumTomos
    NumIntSets = NumIntSets + 1;
    %% Set input file prefixes and output file name.
    FILE_PREFIX = sprintf('%s%s/int_',IntParentPath,TomoFolderNames(tomoNum).name);
    OUTPUT_FILE = sprintf('%sint_%s.vol',OutputPath,TomoFolderNames(tomoNum).name);
    %% Open .par file.
    ParFileName = sprintf('%s.par',OUTPUT_FILE);
    fid = fopen(ParFileName,'wt');
    %% Write into .par file.
    fprintf(fid, ...
        ['# HST_SLAVE PARAMETER FILE\n' ...
        '# This parameter file was created automatically by Matlab script ''MakeParFile''\n' ...
        '\n' ...
        'RECONSTRUCT_FROM_SINOGRAMS = NO\n'...
        '\n'...
        '# Parameters defining the projection file series\n' ...
        'FILE_PREFIX = ' FILE_PREFIX '\n' ...
        'NUM_FIRST_IMAGE = ' num2str(NUM_FIRST_IMAGE,'%i') ' # No. of first projection file\n' ...
        'NUM_LAST_IMAGE  = ' num2str(NUM_LAST_IMAGE,'%i') ' # No. of last projection file\n' ...
        'NUMBER_LENGTH_VARIES = NO\n' ...
        'LENGTH_OF_NUMERICAL_PART = 4 # No. of characters\n' ...
        'FILE_POSTFIX = .edf\n' ...
        'FILE_INTERVAL = 1 # Interval between input files\n' ...
        '\n' ...
        '# Parameters defining the projection file format\n' ...
        'NUM_IMAGE_1 = ' num2str(PixelsHor,'%u') ' # Number of pixels horizontally\n' ...
        'NUM_IMAGE_2 = ' num2str(PixelsVer,'%u') ' # Number of pixels vertically\n' ...
        'IMAGE_PIXEL_SIZE_1 = ' num2str(IMAGE_PIXEL_SIZE,'%f') ' # Pixel size horizontally (microns)\n' ...
        'IMAGE_PIXEL_SIZE_2 = ' num2str(IMAGE_PIXEL_SIZE,'%f') ' # Pixel size vertically\n' ...
        '\n' ...
        '# Parameters defining background treatment\n' ...
        'SUBTRACT_BACKGROUND = NO # No background subtraction\n' ...
        'BACKGROUND_FILE = N.N. \n' ...
        '\n' ...
        '# Parameters defining flat-field treatment\n' ...
        'CORRECT_FLATFIELD = NO # No flat-field correction\n' ...
        'FLATFIELD_CHANGING = N.A.\n' ...
        'FLATFIELD_FILE = N.A.\n' ...
        'FF_PREFIX = N.A.\n' ...
        'FF_NUM_FIRST_IMAGE = N.A.\n' ...
        'FF_NUM_LAST_IMAGE = N.A.\n' ...
        'FF_NUMBER_LENGTH_VARIES = N.A.\n' ...
        'FF_LENGTH_OF_NUMERICAL_PART = N.A.\n' ...
        'FF_POSTFIX = N.A.\n' ...
        'FF_FILE_INTERVAL = N.A.\n' ...
        '\n' ...
        'TAKE_LOGARITHM = NO # Take log of projection values\n' ...
        '\n' ...
        '# Parameters defining experiment\n' ...
        'ANGLE_BETWEEN_PROJECTIONS = ' num2str(ANGLE_BETWEEN_PROJECTIONS,'%f') ' # Increment angle in degrees\n' ...
        'ROTATION_VERTICAL = YES\n' ...
        'ROTATION_AXIS_POSITION = ' num2str(RotAxisPos,'%f') ' # Position in pixels\n' ...
        '\n' ...
        '# Parameters defining reconstruction\n' ...
        'OUTPUT_SINOGRAMS = NO # Output sinograms to files or not\n' ...
        'OUTPUT_RECONSTRUCTION = YES # Reconstruct and save or not\n' ...
        'START_VOXEL_1 = ' num2str(START_VOXEL_1,'%u') ' # X-start of reconstruction volume\n' ...
        'START_VOXEL_2 = ' num2str(START_VOXEL_2,'%u') ' # Y-start of reconstruction volume\n' ...
        'START_VOXEL_3 = ' num2str(START_VOXEL_3,'%u') ' # Z-start of reconstruction volume\n' ...
        'END_VOXEL_1 = ' num2str(END_VOXEL_1,'%u') ' # X-end of reconstruction volume\n' ...
        'END_VOXEL_2 = ' num2str(END_VOXEL_2,'%u') ' # Y-end of reconstruction volume\n' ...
        'END_VOXEL_3 = ' num2str(END_VOXEL_3,'%u') ' # Z-end of reconstruction volume\n' ...
        'OVERSAMPLING_FACTOR = 4 # 0 = Linear, 1 = Nearest pixel\n' ...
        'ANGLE_OFFSET = 0.000000 # Reconstruction rotation offset angle in degrees\n' ...
        'CACHE_KILOBYTES = 4096 # Size of processor cache (L2) per processor (KBytes)\n' ...
        'SINOGRAM_MEGABYTES = 800 # Maximum size of sinogram storage (megabytes)\n' ...
        '\n' ...
        '# Parameters defining output file / format\n' ...
        'OUTPUT_FILE = ' OUTPUT_FILE '\n' ...
        '# Reconstruction program options\n' ...
        'DISPLAY_GRAPHICS = NO # No images\n' ...
        '\n']);
    fclose(fid);
end
fprintf('PAR FILES CREATED FOR %u INTENSITY DATA SETS\n',NumIntSets)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PAR FILE FOR RETRIEVED PHASES.
%Loop over different phase retrievals.
NumPhaseSets = 0;
for PhaseSubDirNum = 1:NumPhaseSubFolders
    PhaseSubPath = [PhasePath PhaseSubDirNames(PhaseSubDirNum).name];
    TomoFolderNames = dir([PhaseSubPath '/' InputFolderPrefix '*']);
    NumTomos = numel(TomoFolderNames);
    for tomoNum = 1:NumTomos     
        NumPhaseSets = NumPhaseSets +1;
        %% Set input file prefixes and output file name.
        FILE_PREFIX = sprintf('%s/%s/phase_',PhaseSubPath,TomoFolderNames(tomoNum).name);
        OUTPUT_FILE = sprintf('%s%s_%s.vol',OutputPath,PhaseSubDirNames(PhaseSubDirNum).name,TomoFolderNames(tomoNum).name);
        %% Open .par file.
        ParFileName = sprintf('%s.par',OUTPUT_FILE);
        fid = fopen(ParFileName,'wt');
        %% Write into .par file.
        fprintf(fid, ...
            ['# HST_SLAVE PARAMETER FILE\n' ...
            '# This parameter file was created automatically by Matlab script ''MakeParFile''\n' ...
            '\n' ...
            'RECONSTRUCT_FROM_SINOGRAMS = NO\n'...
            '\n'...
            '# Parameters defining the projection file series\n' ...
            'FILE_PREFIX = ' FILE_PREFIX '\n' ...
            'NUM_FIRST_IMAGE = ' num2str(NUM_FIRST_IMAGE,'%u') ' # No. of first projection file\n' ...
            'NUM_LAST_IMAGE  = ' num2str(NUM_LAST_IMAGE,'%u') ' # No. of last projection file\n' ...
            'NUMBER_LENGTH_VARIES = NO\n' ...
            'LENGTH_OF_NUMERICAL_PART = 4 # No. of characters\n' ...
            'FILE_POSTFIX = .edf\n' ...
            'FILE_INTERVAL = 1 # Interval between input files\n' ...
            '\n' ...
            '# Parameters defining the projection file format\n' ...
            'NUM_IMAGE_1 = ' num2str(PixelsHor,'%u') ' # Number of pixels horizontally\n' ...
            'NUM_IMAGE_2 = ' num2str(PixelsVer,'%u') ' # Number of pixels vertically\n' ...
            'IMAGE_PIXEL_SIZE_1 = ' num2str(IMAGE_PIXEL_SIZE,'%f') ' # Pixel size horizontally (microns)\n' ...
            'IMAGE_PIXEL_SIZE_2 = ' num2str(IMAGE_PIXEL_SIZE,'%f') ' # Pixel size vertically\n' ...
            '\n' ...
            '# Parameters defining background treatment\n' ...
            'SUBTRACT_BACKGROUND = NO # No background subtraction\n' ...
            'BACKGROUND_FILE = N.N. \n' ...
            '\n' ...
            '# Parameters defining flat-field treatment\n' ...
            'CORRECT_FLATFIELD = NO # No flat-field correction\n' ...
            'FLATFIELD_CHANGING = N.A.\n' ...
            'FLATFIELD_FILE = N.A.\n' ...
            'FF_PREFIX = N.A.\n' ...
            'FF_NUM_FIRST_IMAGE = N.A.\n' ...
            'FF_NUM_LAST_IMAGE = N.A.\n' ...
            'FF_NUMBER_LENGTH_VARIES = N.A.\n' ...
            'FF_LENGTH_OF_NUMERICAL_PART = N.A.\n' ...
            'FF_POSTFIX = N.A.\n' ...
            'FF_FILE_INTERVAL = N.A.\n' ...
            '\n' ...
            'TAKE_LOGARITHM = NO # Take log of projection values\n' ...
            '\n' ...
            '# Parameters defining experiment\n' ...
            'ANGLE_BETWEEN_PROJECTIONS = ' num2str(ANGLE_BETWEEN_PROJECTIONS) ' # Increment angle in degrees\n' ...
            'ROTATION_VERTICAL = YES\n' ...
            'ROTATION_AXIS_POSITION = ' num2str(RotAxisPos,'%f') ' # Position in pixels\n' ...
            '\n' ...
            '# Parameters defining reconstruction\n' ...
            'OUTPUT_SINOGRAMS = NO # Output sinograms to files or not\n' ...
            'OUTPUT_RECONSTRUCTION = YES # Reconstruct and save or not\n' ...
            'START_VOXEL_1 = ' num2str(START_VOXEL_1) ' # X-start of reconstruction volume\n' ...
            'START_VOXEL_2 = ' num2str(START_VOXEL_2) ' # Y-start of reconstruction volume\n' ...
            'START_VOXEL_3 = ' num2str(START_VOXEL_3) ' # Z-start of reconstruction volume\n' ...
            'END_VOXEL_1 = ' num2str(END_VOXEL_1) ' # X-end of reconstruction volume\n' ...
            'END_VOXEL_2 = ' num2str(END_VOXEL_2) ' # Y-end of reconstruction volume\n' ...
            'END_VOXEL_3 = ' num2str(END_VOXEL_3) ' # Z-end of reconstruction volume\n' ...
            'OVERSAMPLING_FACTOR = 4 # 0 = Linear, 1 = Nearest pixel\n' ...
            'ANGLE_OFFSET = 0.000000 # Reconstruction rotation offset angle in degrees\n' ...
            'CACHE_KILOBYTES = 4096 # Size of processor cache (L2) per processor (KBytes)\n' ...
            'SINOGRAM_MEGABYTES = 800 # Maximum size of sinogram storage (megabytes)\n' ...
            '\n' ...
            '# Parameters defining output file / format\n' ...
            'OUTPUT_FILE = ' OUTPUT_FILE '\n' ...
            '# Reconstruction program options\n' ...
            'DISPLAY_GRAPHICS = NO # No images\n' ...
            '\n']);
        fclose(fid);
    end
end
fprintf('PAR FILES CREATED FOR %u PHASE DATA SETS\n',NumPhaseSets)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PyHST extra features.
%             '\n' ...
%             '# Parameters extra features PyHST\n' ...
%             'DO_CCD_FILTER = NO # CCD filter (spikes)\n' ...
%             'CCD_FILTER = "CCD_Filter"\n' ...
%             'CCD_FILTER_PARA = {"threshold": 0.040000 }\n' ...
%             'DO_SINO_FILTER = NO # Sinogram filter (rings)\n' ...
%             'SINO_FILTER = "SINO_Filter"\n' ...
%             'ar = Numeric.ones(2048,''f'')\n' ...
%             'ar[0]=0.0\n' ...
%             'ar[2:18]=0.0\n' ...
%             'SINO_FILTER_PARA = {"FILTER": ar }\n' ...
%             'DO_AXIS_CORRECTION = NO # Axis correction\n' ...
%             'AXIS_CORRECTION_FILE = correct.txt\n' ...
%             '#konditionaler Medianfilter' ...
%             '#DO_CCD_FILTER= YES' ...
%             '#CCD_FILTER = "CCD_Filter"' ...
%             '#CCD_FILTER_PARA={"threshold": 0.0000 } #0.0005 Bedingung/Schwellwert' ...
