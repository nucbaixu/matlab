function  [phi,im,dat,flat]=RecoLoopMeshes()
% Loop over Data from Inhouse Experiment at ESRF to retrieve the phase to
% LO and NLO.


% Reco.m arguments.
% ESRF ID19 experimental setup parameters.
energy     = 17.68;
lambda     = EnergyConverter(energy);
distance   = [7 20 53 80 94 121]*10^-3;
pixelsize  = 0.69e-6;
padvalue   = 0;
iterations = 0;
compute_correction = 1;

padding  = 1 ;  
dim1     = 2048;
dim2     = 2048;
ycrop    = 128;

% Folder to data.
ParentFolder = '/mnt/tomoraid3/tomo/ESRF_20100411_InhouseExperiment/';
ScanName     = {'CT_carbonMeshesPApet'; 'CT_graphiteMinePApet'; 'CT_meshesPApet'; 'CT_meshesPApet_B'};
totalcounter = 0;

ttotal = 0;
% Loop over data.
for ii = 1:4, % Loop over samples defined in ScanName.
    for jj = 1:6, % Loop over distances within scan.
    
        % Get names of data files.
        Prefix      = [char(ScanName(ii)) '_' num2str(jj) '_'];
        DataFolder  = [ParentFolder char(ScanName(ii)) '/' Prefix '/'];
        RecoFolder  = [DataFolder(1:end-1) 'PhaseRetrieval/'];
        unix(['mkdir ' RecoFolder 'LO >&/dev/null']);
        unix(['mkdir ' RecoFolder 'NLO >&/dev/null']);
        files       = dir([DataFolder '/' char(ScanName(ii)) '_' num2str(jj) '_*.edf']);
        num_files   = numel(files);
        fprintf(['Current folder: ' DataFolder '\n']);
        % Read alpha.
        fid         = fopen([RecoFolder 'AlphaOptByHand.txt']);
        alpha       = str2num(fgetl(fid));
        fclose(fid);
        % Read flat and dark fields.
        tic;
        flat        = zeros(4,dim1,dim2);
        dark        = edfread([DataFolder '/darkend0000.edf']);
        flat(1,:,:) = edfread([DataFolder '/refHST0000.edf']);
        flat(2,:,:) = edfread([DataFolder '/refHST0500.edf']);
        flat(3,:,:) = edfread([DataFolder '/refHST1000.edf']);
        flat(4,:,:) = edfread([DataFolder '/refHST1500.edf']);
        % Crop data.
        if ycrop>0,
            dark    = dark(:,1+ycrop:end-ycrop);
            flat    = flat(:,:,1+ycrop:end-ycrop);
        end;
        fprintf(sprintf(['Distance: %g, alpha: %g, number of files: %g, ' ...
                         'resolution: %g x %g\n'],distance(jj),alpha,num_files,size(dark,1),size(dark,2)));
        df          = 10;
        flat_stack  = interp1(0:500:1500,flat,0:df:1500);
        tflatdark   = toc;
        dkk         = 1;
        tic;
        counter     = 0;
        for kk = 1:dkk:num_files,
            dat     = edfread([DataFolder char(files(kk).name)]);
            if ycrop>0, dat = dat(:,1+ycrop:end-ycrop);end;
            im      = (dat - dark)./(squeeze(flat_stack(ceil((kk+df/2)/df),:,:)) - dark);
            % Reconstruct phase
            phi     = Reco(im,alpha,lambda,distance(jj),pixelsize,padding, ...
                       padvalue,iterations,compute_correction);
            LO      = phi(:,:,1);
            NLO     = phi(:,:,2);
            edfwrite([RecoFolder 'LO/phaseLO_' num2str(kk,'%04i') '.edf'],LO,'float32');
            edfwrite([RecoFolder 'NLO/phaseNLO_' num2str(kk,'%04i') '.edf'],NLO,'float32');
            if kk==1,
                fprintf(sprintf(['Projection 0000: [Min,Max]=[%g,%g], Mean=%g, Max-Min=%g\n'], ...
                            min(im(:)),max(im(:)),mean(im(:)),max(im(:))-min(im(:))));
                fprintf(sprintf(['Phase LO: [Min,Max]=[%g,%g], Mean=%g, Max-Min=%g\n'], ...
                            min(LO(:)),max(LO(:)),mean(LO(:)),max(LO(:))-min(LO(:))));
            end;
            counter = counter + 1;
            totalcounter = totalcounter + 1;
        end;

        trec = toc;
        fprintf(sprintf(['Time for flat and dark field processing: %gs, time to retrieve ' ...
                 'phase (LO+NLO) of %g projections: %gs\n'],tflatdark,counter,trec));
        ttotal = tflatdark + trec;
    end;
end;
fprintf(sprintf('\nProcessed %g intensity maps in %gm.\n',totalcounter,ttotal/60));

