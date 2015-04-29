function MakeParFile32ID(InputFilePrefix,OutputFilePrefix,Dimensions,RotAxisPos,varargin)
% Function to create par file for routine 'FlatCor32ID'

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% varargin
for nn = 1:2:numel(varargin)
    evalc([varargin{nn} ' = ' mat2str(varargin{nn+1})]);
end
%% Default arguments
if ~exist('NumberOfProjections','var')
    NumberOfProjections = 832;
end
if ~exist('OverallAngle','var')
    OverallAngle = 180;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
AngleBetweenProjections = OverallAngle/NumberOfProjections;
%% Volume to reconstruct.
PixelsHor = Dimensions(2);
PixelsVer = Dimensions(1);
START_VOXEL_1 = 1;
START_VOXEL_2 = 1;
START_VOXEL_3 = 1;
END_VOXEL_1   = PixelsHor;
END_VOXEL_2   = PixelsHor;
END_VOXEL_3   = PixelsVer;
%% PAR FILE
%% Set input file prefixes and output file name.
FILE_PREFIX = InputFilePrefix;
OUTPUT_FILE = OutputFilePrefix;
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
    'NUM_FIRST_IMAGE = ' num2str(1,'%u') ' # No. of first projection file\n' ...
    'NUM_LAST_IMAGE  = ' num2str(NumberOfProjections,'%u') ' # No. of last projection file\n' ...
    'NUMBER_LENGTH_VARIES = NO\n' ...
    'LENGTH_OF_NUMERICAL_PART = 4 # No. of characters\n' ...
    'FILE_POSTFIX = .edf\n' ...
    'FILE_INTERVAL = 1 # Interval between input files\n' ...
    '\n' ...
    '# Parameters defining the projection file format\n' ...
    'NUM_IMAGE_1 = ' num2str(PixelsHor,'%u') ' # Number of pixels horizontally\n' ...
    'NUM_IMAGE_2 = ' num2str(PixelsVer,'%u') ' # Number of pixels vertically\n' ...
    'IMAGE_PIXEL_SIZE_1 = 10000 # \n' ...
    'IMAGE_PIXEL_SIZE_2 = 10000 # Is not used at all\n' ...
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
    'ANGLE_BETWEEN_PROJECTIONS = ' num2str(AngleBetweenProjections) ' # Increment angle in degrees\n' ...
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
