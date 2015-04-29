% Tomographic reconstruction of Shepp-Logan phantom using filtered
% backprojection


%% Phantom and projections
N = 128;
NumProj = 4*N;
theta = 0:180/NumProj:180-1/NumProj;
P = phantom('Modified Shepp-Logan',N);
P2 = P + 10;
[R Xp] = radon(P,theta);
[R2] = radon(P2,theta);
RotAxis = ceil(size(R,1)/2);
%% Inverse radon transformation
freqScal = 1;
OutputSize = size(R,1);
[I1,h] = iradon(R,theta,'linear','Ram-Lak',freqScal,OutputSize);
I2 = iradon(R,theta,'linear','none',freqScal,OutputSize);
[IR2] = iradon(R,theta,'linear','Ram-Lak',freqScal,OutputSize);
%% Plotting
figure('Name','Sinogram')
imshow(R,[])
figure('Name','Phantom: Original, Filtered BP, Unfiltered BP')
subplot(1,3,1), imshow(P), title('Original')
subplot(1,3,2), imshow(I1), title('Filtered backprojection')
subplot(1,3,3), imshow(I2,[]), title('Unfiltered backprojection')

%% Phantom and projections
P = 1-P;
R = radon(P,theta);
%% Inverse radon transformation
freqScal = 1;
OutputSize = size(R,1);
I1 = iradon(R,theta,'linear','Ram-Lak',freqScal,OutputSize);
I2 = iradon(R,theta,'linear','none',freqScal,OutputSize);
%% Plotting
figure('Name','Sinogram')
imshow(R,[])
figure('Name','Phantom: Original, Filtered BP, Unfiltered BP')
subplot(1,3,1), imshow(P), title('Original')
subplot(1,3,2), imshow(I1), title('Filtered backprojection')
subplot(1,3,3), imshow(I2,[]), title('Unfiltered backprojection')
%% Writing
% OutputFolder = '/home/moosmann/data/sim_shepplogan';
% edfwrite([OutputFolder '/sino/sino_shepplogan_pixel185proj256.edf'],R','float32');
% imwrite(normat(R),[OutputFolder '/sino/sino_shepplogan_pixel185proj256.tif'])
% % for ii = 100:-1:1
% %     R2(:,:,ii) = R;
% % end
% for ii=1:size(R,2)
%     edfwrite(sprintf('%s/proj/proj_%04u.edf',OutputFolder,ii),squeeze(R2(:,ii,:)),'float32');
% end