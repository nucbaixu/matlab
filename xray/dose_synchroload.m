%function out = dose_synchroload(fluxDensity_ph_per_s_mm2,energy.value,absorptionLength.value,scanTime.value,objectLength.value,objectDensity_g_per_ccm,containerLength.value)
% One gray is the absorption of one joule of energy, in the form of
% ionizing radiation, per kilogram of matter.
%
%   1 Gy = 1 J / kg = m^2 / s^2
clear all
%% ID 19 flux: undulator U13, 193 mA ring current, pink beam ca 4% bandwith 26.2 keV peak energy, flux 166e-12 ph / mm^2 / s
flux.id19.source = 'undulator U13';
flux.id19.spectrum = 'pink';
flux.id19.energy.value = 26.3;
flux.id19.energy.unit = 'keV';
flux.id19.bandwidth = 0.04;
flux.id19.ring_current.value = 193;
flux.id19.ring_current.unit = 'mA';
flux.id19.flux.value = 166e-12;
flux.id19.flux.unit = 'photons / mm^2 / s';


% 2-BM-B flux @ 30keV DMM: Henke: 8.0e13 ph/s/mrad^2/0.1%BW
% flux density = 8e13*10 ph/s/1%BW / (35m)^2 /mrad^2
% = 6.54e11 ph/s/1%BW/mm^2 ~ 10^12 ph/s/mm^2
fluxDensity_ph_per_s_mm2 = 10^12; % photons / s / mm ^2

energy.value = 30 ;
energy.unit = 'keV' ;

% for water: l_att = 1 / (4*pi*beta/lambda) = 3.10 cm at 30 keV
absorptionLength.value = 30.9;
absorptionLength.unit = 30.9;

scanTime.value = 20 ;
scanTime.unit = 's' ;

objectLength.value = 1.0 ;
objectLength.unit = 'mm';

objectDensity_g_per_ccm  = 0.997 ; % g / cm^3 = 1000 kg / m^3
objectDensity.unit  = 'g / cm^3';
objectDensity.unitequiv = '1000 kg / m^3' ;

containerLength.value = 12 ; % mm
containerLength.unit = 'mm';

%% P05 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% absorber

% CVD 300 micron
% Cu 50 micron
% transmission at 30000 eV: 0.59

% glassy / vitreous carbon / Glaskohlenstoff
% density
GC.density = [1.4 1.5];% g / cm3
GC.thickness = 0.004; % m


% max flux ON SAMPLE
flux_14400eV = 7e13; % photons / s

% spot size ON SAMPLE
flux_area_14400eV = 6.000 * 3.0; % mm^2
flux_density_14400eV = flux_14400eV / flux_area_14400eV;
flux_30000eV_1x1mm2 = 525542981736 / 3; % photons / s
flux_density_30000eV = flux_30000eV_1x1mm2;
flux = flux_density_30000eV / 0.9; % Correct for 90 mA instead of 100 mA

%% Materials

% sample environment
PEEK.density = 1320; % kg / m^3
PEEK.formula = 'C19H12O3';

transmission.PEEK = 0.85; %extrapolated guess from 30

% average bone+PEEK
transmission.data.bone_PEEK = 0.61;

% Bone
% formulas: https://physics.nist.gov/PhysRefData/XrayMassCoef/chap2.html
% constants: https://physics.nist.gov/PhysRefData/XrayMassCoef/tab2.html

% Energy / MeV
E = [1.00000E-02 1.50000E-02 2.00000E-02 3.00000E-02 4.00000E-02 5.00000E-02 6.00000E-02 8.00000E-02];
% X-ray mass attenuation coefficient mu/rho / (cm^2/g)
mu_over_rho = [ 2.851E+01 9.032E+00 4.001E+00 1.331E+00 6.655E-01 4.242E-01 3.148E-01 2.229E-01];

% transmission I/I_0 = exp( - mu * t )
t = 1 / 1000; % thickness in m
rho = 1.920E+00; % density / (g/cm^3)
trans = exp( - mu_over_rho * rho * t*100 );
mu_over_rho_35000eV = mean( mu_over_rho(4:5) );
transmission_bone_35000eV = exp( - mu_over_rho_35000eV * rho * t*100 );

mass = rho * ( 1 / 1000 / (1e-2)^3 ) * (t)^3; %kg

absorption = 1 - transmission_bone_35000eV;

% exposure
exposure = 1200 * 0.15; % s
exposure = 3000 * 0.1; % s

energy.value = 34000;
energy.unit = 'eV';
eV_to_J = 1.602176565e-19 ;

%% Dose
dose = transmission.PEEK * absorption * flux * (t*1000)^2 * exposure * energy * eV_to_J / mass;

fprintf( '\ndose : %g\b kGy', dose / 1000 )

% Attenuation
out.containerTransmission = exp( - (containerLength.value -objectLength.value)/2 / absorptionLength.value) ;
out.objectAbsorption = 1-exp( - objectLength.value/ absorptionLength.value) ;
% Number of photons
out.absorbedPhotons = out.containerTransmission * out.objectAbsorption * fluxDensity_ph_per_s_mm2 * scanTime.value  * (objectLength.value)^2;
% Cubic mass of object
out.cubeMass_g = objectLength.value^3 * objectDensity_g_per_ccm / 1000 ;
% Dose
out.dose_Gy = out.absorbedPhotons * energy.value*10^3 * eV_to_J ...
    / ( out.cubeMass_g / 1000 );

