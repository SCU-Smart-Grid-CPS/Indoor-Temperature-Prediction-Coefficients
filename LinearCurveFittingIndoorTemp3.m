%% LinearCurveFittingIndoorTemp3.m
% Author(s):    PJ McCurdy, Brian Woo-Shem
% Version:      3.00 BETA
% Last Updated: 2021-10-11
% Changelog:
%   - Modified to have C4 = diffuse solar coeff
%   - No longer backward compatible to PJ .mlx code

%% Linear regression to solve for indoor temperature coefficients
% prediction constants

% Clear out old data
clear all
close all
clc

%Num calibration rows from EP <--- CHANGE ME
calibrows = 1154; %1153; %578; %2;

%File name <--- CHANGE ME!
infile = 'Sac_Basic_Winter_2.csv';
disp(infile);

x = readmatrix(infile); %,'Sheet','TrainingHP3');
sizx = size(x); % 2 values returned
datarows = sizx(1); % Total number of rows with some data (includes headers and calibration stuff)
%datarows = 27360; %Manual override for winter SF bc crashed
n = datarows-1-calibrows; %Number of usable data points. Can change to array of ranges of data points instead.
v = 4; % Number of constants to solve for. DO NOT CHANGE without good reason.
C_set = zeros(v,1); % matrix to hold the constants per training set
E = zeros(v,1); % constants in each iteration before averaging

N = zeros(n,v); % creating matrix of dependent variables
TD = zeros(n,1); % creating matrix of eused val
r = calibrows:1:datarows;
for j=1:n
    for k=1:v
        if ~isnan(x(r(j),k))
            N(j,k)=x(r(j),k); % matrix of (Outdoor - past Indoor Temperatures), energy used, and solar radiation
        end
    end
    TD(j,:) = x(r(j),4); % (indoor temp - past indoor temp)/dt column
end
C_it = N\TD;% solving for the constants in this iteration
E = C_it; %Saves constants from all iterations and sets, non-averaged.
C_set = C_it ./itr + C_set; % Create new row = average that constant from all iterations in set = 
%                             Sum of constants for this set / num interations in this set


% Overall avg constants
C_avg = mean(C_set,2);
fprintf('Overall constants: \n\tC_1 = %g', C_avg(1))
fprintf('\n\tC_2 = %g',C_avg(2))
fprintf('\n\tC_3 = %g',C_avg(3))
fprintf('\n\tC_4 = %g',C_avg(4))
disp(' ')

%% Code to solve for RMSE of Indoor Temperature Prediction

% Get arrays of each variable's data from excel spreadsheet
OutIn = x(:,1);
eUsed = x(:,2);
Q_directSol = x(:,3);
Q_diffuseSol = x(:,4);
Tindoor = x(:,5);

cssize = size(C_set); %Should = 1 in current code.

Tpredict = zeros(datarows,cssize(2)); % length(x) returns 105121 for 105121x61 double. length(D) returns 100 for 3x100 double
Tdifference = zeros(datarows,cssize(2));
Tsum = zeros(1,cssize(2));
RMSE = zeros(1,cssize(2));

for co=1:cssize(2) % co = all columns
    for ro = calibrows:datarows % ro = all rows
        Tpredict(ro-1,co) = C_set(1,co)*OutIn(ro) +C_set(2,co)*eUsed(ro) + C_set(3,co)*Q_directSol(ro) + C_set(4,co)*Q_diffuseSol(ro); % Calculating the predicted (future indoor temp - current indoor temp)/dt
        Tdifference(ro-1,co)=(Tindoor(ro)-Tpredict(ro-1,co))^2; % squaring the difference between the preidction and the true value
        Tsum(1,co)=Tsum(1,co)+Tdifference(ro-1,co); % summing the squares
    end
        RMSE(1,co) = sqrt(Tsum(1,co)/length(x)); % calculating the RMSE, one for each of 3 constants
end

disp('Estimated Root Mean Squared Error = ')
RMSE

%% Write results to file

% Crude comment out because this doesn't work.
attemptWriteResults = 0;

if attemptWriteResults == 1
    results = [C_set', RMSE];
    datatable = array2table(results,'VariableNames',{'C_1','C_2','C_3','RMSE C_1','RMSE C_2','RMSE C_3'});
    %datatable = addvars(datatable,char.empty(1,length(results)))
    clabel = ['C_1';'C_2';'C_3'];
    clabel(cssize(1)) = '';
    Final_Results = C_avg;
    Final_Results(cssize(1)) = 0;
    datatable = addvars(datatable,clabel);
    datatable = addvars(datatable,Final_Results);
    head(datatable)
    
    outputfile = "IndoorTempPredictCoeff_" + erase(erase(infile,'.xlsx'),' ') + ".csv";
    fprintf('Exporting as: ', outputfile)
    
    writetable(datatable, outputfile, 'Delimiter',',');
end

%%
% Mystery code. Probably is solving for a single timestep rather than the
% whole block

% Crude comment method
doRMSEi = 0;

if doRMSEi == 1
    Tipredict = zeros(length(x),length(C_set));
    Tidifference = zeros(length(x),length(C_set));
    Tisum=zeros(1,length(C_set));
    RMSEi = zeros(1,length(C_set));

    for co=1:length(C_set)
        for ro =1:length(x)
            Tipredict(ro,co) = 5*60*(C_set(1,co)*OutIn(ro) +C_set(2,co)*eUsed(ro) + C_set(3,co)*Q_directSol(ro)); %Difference in that this line multiplies by timestep
            Tidifference(ro,co)=(Tindoor(ro)-Tipredict(ro,co))^2;
            Tisum(1,co)=Tisum(1,co)+Tidifference(ro,co);
        end
        RMSEi(1,co) = sqrt(Tisum(1,co)/length(x));
    end
end