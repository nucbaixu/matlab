function [vol, reco_metric] = find_rot_axis_tilt(par, proj)
% Reconstruct slices from a single sinogram using a range of rotation axis
% tilt.
%
% RETURN
% vol : 3D array. stack of slices with different rotation axis tilts
% reco_metric : struct containing different metrics: mean of all values,
% mean of all absolute values, mean non-negative values, mean of isotropic
% modulus of gradient, mean of Laplacian, entropy
% 
% Written by Julian Moosmann. Last modification: 2018-05-03
%
% [vol, reco_metric] = find_rot_axis_tilt(par, proj)

%% Default arguments %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

slice = assign_from_struct( par, 'slice', [] );
vol_shape = assign_from_struct( par, 'vol_shape', [] );
vol_size = assign_from_struct( par, 'vol_size', [] );
offset = double( assign_from_struct( par, 'offset', 0 ));
tilt = assign_from_struct( par, 'tilt', -0.005:0.001:0.005 );
offset_shift = assign_from_struct( par, 'offset_shift', 0 );
lamino = assign_from_struct( par, 'lamino', 0 );
fixed_tilt = assign_from_struct( par, 'fixed_tilt', 0 );
take_neg_log = assign_from_struct( par, 'take_neg_log', 1 );
number_of_stds = assign_from_struct( par, 'number_of_stds', 4 );
butterworth_filtering = assign_from_struct( par.butterworth_filter, 'apply', 0 );

mask_rad = 0.95;
mask_val = 0;
filter_histo_roi = 0.25;

%% Main %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[num_pix, num_row, ~] = size( proj );
if isempty( vol_shape )
    vol_shape = [num_pix, num_pix, 1];
else
    vol_shape(3) = 1;
end
par.vol_shape = vol_shape;
if isempty( vol_size )
    vol_size = [-num_pix/2 num_pix/2 -num_pix/2 num_pix/2 -0.5 0.5];
else
    vol_size(5) = -0.5;
    vol_size(6) = 0.5;
end
par.vol_size = vol_size;
if isempty( slice )
    slice = round( num_row / 2 );
end
par.slice = slice;

% Calculate required slab
rot_axis_pos = offset + num_pix / 2;
l = max( rot_axis_pos, abs( num_pix - rot_axis_pos ));
dz = ceil( sin( max( abs( tilt ) ) ) * l ); % maximum distance between sino plane and reco plane
if slice - dz < 0 || slice + dz > num_row
    fprintf( '\nWARNING: Inclination of reconstruction plane, slice %u, exceeds sinogram volume. Better choose a more central slice or a smaller tilts.', slice)
end

% Slab
y_range = slice + (-dz:dz);
sino = proj(:, y_range, :);

if strcmpi( par.algorithm, 'fbp' )
    % Ramp filter
    filt = iradonDesignFilter('Ram-Lak', 2 * num_pix, 1);
    
    % Butterworth filter
    if butterworth_filtering
        [b, a] = butter(1, 0.5);
        bw = freqz(b, a, numel(filt) );
        filt = filt .* bw;
    end
    
    % Apply filters
    sino = padarray( NegLog(sino, take_neg_log), [num_pix 0 0 ], 'symmetric', 'post');
    sino = real( ifft( bsxfun(@times, fft( sino, [], 1), filt), [], 1, 'symmetric') );
    sino = sino(1:num_pix,:,:);
end

% Metrics
reco_metric(1).name = 'mean';
reco_metric(2).name = 'abs';
reco_metric(3).name = 'neg';
reco_metric(4).name = 'iso-grad';
reco_metric(5).name = 'laplacian';
reco_metric(6).name = 'entropy';
reco_metric(7).name = 'entropy-ML';

% Preallocation
vol = zeros(vol_shape(1), vol_shape(2), numel(tilt));
for nn = 1:numel(reco_metric)
    reco_metric(nn).val = zeros( numel(tilt), 1);
end

par.rot_axis.offset = offset + offset_shift + eps;

% Backprojection
for nn = 1:numel( tilt )
    if ~lamino
        par.tilt_camera = tilt(nn);
        par.tilt_lamino = fixed_tilt;
    else
        par.tilt_camera = fixed_tilt;
        par.tilt_lamino = tilt(nn);
    end
    
    %% Reco
    im = astra_parallel3D( par, permute( sino, [1 3 2]) );
    vol(:,:,nn) = FilterHisto(im, number_of_stds, filter_histo_roi);
    
    %% Metrics        
    im = double( MaskingDisc( im, mask_rad, mask_val) ) * 2^16;
    % mean
    reco_metric(1).val(nn) = mean2( im );
    % mean abs
    reco_metric(2).val(nn) = mean2( abs( im ) );
    % mean negativity
    reco_metric(3).val(nn) = - mean( im( im <= 0 ) );
    % isotropic gradient
    [g1, g2] = gradient(im);
    reco_metric(4).val(nn) = mean2( sqrt( g1.^2 + g2.^2 ) );
    % laplacian
    reco_metric(5).val(nn) = mean2( abs( del2( im ) ) );
    % entropy
    p = histcounts( im(:) );
    p = p(p>0);
    p = p / sum( p );
    reco_metric(6).val(nn) = -sum( p .* log2( p ) );
    % entropy built-in
    reco_metric(7).val(nn) = -entropy( im );

end

% Normalize for ease of plotting and comparison
for nn = 1:numel(reco_metric)
    reco_metric(nn).val = normat( reco_metric(nn).val );
end
