% LinearCurveFittingIndoorTemp3.m   GNU Octave Edition
% Author(s):    PJ McCurdy, Brian Woo-Shem
% Version:      3.10 Stable
% Last Updated: 2021-10-11
% Instructions:
%   0. Install the io Octave Forge Package <https://octave.sourceforge.io/io/>
%      Only need to do this once per computer. 
%      Use commands in Command Window:
%         pkg install io
%         pkg load io
%      Note: if first command does not work, try: 
%         pkg install 'https://octave.sourceforge.io/download.php?package=io-2.6.3.tar.gz'
%   1. Run a simulation of the Basic_2 type (eg
%   Sac_Basic_Summer_changeHVAC_30pct.idf
%   2. Open the .csv file in Microsoft Excel, Google Sheets, or LibreOffice Calc
%   3. Add 6 new columns at the beginning:
%   Header Row: 
%   -----------------------------------------------------------------------
%   |      A       |                      B                       | 
%   | T_out - T_in | (HeatingEnergy + CoolingEnergy)*2.77E-7_[KWh]|
%   -----------------------------------------------------------------------
%   |                C               |                 D               |
%   | Direct_Solar_Radiation_[W/m^2] | Diffuse_Solar_Radiation_[W/m^2] |
%   -----------------------------------------------------------------------
%   |            E           |   F   |         G ... ZZZ        |
%   | (T_r - T_(r-1))/(60*5) | blank | Energy Plus .CSV Data ...|
%   -----------------------------------------------------------------------
%
%   4. Enter the Filename and calibration rows ( <--- CHANGE ME )
%   5. Run this program
%
% Changelog:
%   - Modified to have C4 = diffuse solar coeff
%   - No longer backward compatible to PJ .mlx code. Makes single pass thru
%     all data points only! (No multiple sub-training sets)

% -------------------------------------------------------------------------
% Linear regression to solve for indoor temperature coefficients
% prediction constants

% Clear out old data
clear all
close all
clc

%Num calibration rows from EP <--- CHANGE ME!
calibrows = 1154; %1153; %578; %2;

%File name <--- CHANGE ME!
infile = 'Sac_Basic_changeHVAC_40pct_Annual.xlsx'; %'Sac_Basic_Winter_2.csv';
fprintf('Processing File: %s \n', infile);

x = xlsread(infile);
sizx = size(x); % 2 values returned
datarows = sizx(1); % Total number of rows with some data (includes headers and calibration stuff)
n = datarows-1-calibrows; %Number of usable data points. Can change to array of ranges of data points instead.
v = 4; % Number of constants to solve for. DO NOT CHANGE without good reason.
C_set = zeros(v,1); % matrix to hold the constants

N = zeros(n,v); % creating matrix of dependent variables
TD = zeros(n,1); % creating matrix of eused val
r = calibrows:1:datarows;
for j=1:n
    for k=1:v
        if ~isnan(x(r(j),k)) % Catch invalid values to avoid crashing. Might cause inaccuracies if values get set to 0 however.
            N(j,k)=x(r(j),k); % matrix of (Outdoor - past Indoor Temperatures), energy used, direct solar radiation, diffuse solar radiation
        end
    end
    TD(j,:) = x(r(j),5); % (indoor temp - past indoor temp)/dt column
end
C_set = N\TD; %Solves for constants

% Display constants
fprintf('\nIndoor Temperature Prediction Constants: \n\tC_1 = %g', C_set(1))
fprintf('\n\tC_2 = %g',C_set(2))
fprintf('\n\tC_3 = %g',C_set(3))
fprintf('\n\tC_4 = %g',C_set(4))
disp(' ')

% -------------------------------------------------------------------------
% Code to solve for RMSE of Indoor Temperature Prediction

% Get arrays of each variable's data from excel spreadsheet
OutIn = x(:,1);
eUsed = x(:,2);
Q_directSol = x(:,3);
Q_diffuseSol = x(:,4);
Tindoor = x(:,5);

Tpredict = zeros(datarows,1); % length(x) returns 105121 for 105121x61 double. length(D) returns 100 for 3x100 double
Tdifference = zeros(datarows,1);
Tsum = zeros(1);
RMSE = zeros(1);

co = 1; % co = all columns. See next section with pointless for-loop for what it used to do
for ro = calibrows:datarows % ro = all rows
    Tpredict(ro-1,co) = C_set(1,co)*OutIn(ro) +C_set(2,co)*eUsed(ro) + C_set(3,co)*Q_directSol(ro) + C_set(4,co)*Q_diffuseSol(ro); % Calculating the predicted (future indoor temp - current indoor temp)/dt
    Tdifference(ro-1,co)=(Tindoor(ro)-Tpredict(ro-1,co))^2; % squaring the difference between the preidction and the true value
    Tsum(1,co)=Tsum(1,co)+Tdifference(ro-1,co); % summing the squares
end
RMSE(1) = sqrt(Tsum(1)/length(x)); % calculating the RMSE, one for each of 3 constants

fprintf('\nEstimated Root Mean Squared Error = %g \n',RMSE)

% -------------------------------------------------------------------------
% Write results to file - DOES NOT WORK

% Crude comment out because this doesn't work.
attemptWriteResults = 0;

if attemptWriteResults == 1
    results = [C_set', RMSE];
    datatable = array2table(results,'VariableNames',{'C_1','C_2','C_3','RMSE C_1','RMSE C_2','RMSE C_3'});
    %datatable = addvars(datatable,char.empty(1,length(results)))
    clabel = ['C_1';'C_2';'C_3'];
    clabel(v) = '';
    Final_Results = C_set;
    Final_Results(v) = 0;
    datatable = addvars(datatable,clabel);
    datatable = addvars(datatable,Final_Results);
    head(datatable)
    
    outputfile = "IndoorTempPredictCoeff_" + erase(erase(infile,'.xlsx'),' ') + ".csv";
    fprintf('Exporting as: ', outputfile)
    
    writetable(datatable, outputfile, 'Delimiter',',');
end

% -------------------------------------------------------------------------
% ???
% Mystery code. Probably is solving for a single timestep rather than the
% whole block

% Crude comment method
doRMSEi = 0;

if doRMSEi == 1
    Tipredict = zeros(length(x),length(C_set));
    Tidifference = zeros(length(x),length(C_set));
    Tisum=zeros(1,length(C_set));
    RMSEi = zeros(1,1);
    %RMSEi = zeros(1,length(C_set));

    for co=1:1 %length(C_set)
        for ro = calibrows:datarows
            Tipredict(ro,co) = 5*60*(C_set(1,co)*OutIn(ro) +C_set(2,co)*eUsed(ro) + C_set(3,co)*Q_directSol(ro)); %Difference in that this line multiplies by timestep
            Tidifference(ro,co)=(Tindoor(ro)-Tipredict(ro,co))^2;
            Tisum(1,co)=Tisum(1,co)+Tidifference(ro,co);
        end
        RMSEi(1,co) = sqrt(Tisum(1,co)/length(x));
    end
    disp('')
    RMSEi
end