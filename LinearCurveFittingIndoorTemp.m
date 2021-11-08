% MATLAB code of linear regression to solve for indoor temperature
% prediction constants

x=readmatrix('SF Meter HP.xlsx','Sheet','TrainingHP (2)');
itr = 10; % number of iterations to average
n = 1000:1000:100000; % number of data points in each training set
l = length(n); % number of training sets
D = zeros(3,l); % matrix to hold the constants per training set
E = zeros(3,l*itr); % constants in each iteration before averaging

for a=1:itr % a is iternation number     
    for i=1:l % loop for each training set
        N = zeros(n(i),3); % creating matrix of dependent variables
        B = zeros(n(i),1); % creating matrix of eused val
        r = randi([2 103985],1,n(i)); % creating array of random numbers to select random data
        for j=1:n(i)
            m=r(j);
            for k=1:3
                N(j,k)=x(m,k); % matrix of (Outdoor - past Indoor Temperatures), energy used, and solar radiation
            end
            B(j,:) = x(m,4); % (indoor temp - past indoor temp)/dt column
        end
        F = N\B;% solving for the constants
        E(:,i+l*(a-1)) = F;
        D(:,i) = F ./itr + D(:,i);
    end
end
%%
% MATLAB Code to solve for RMSE of Indoor Temperature Prediction

% setting up matricies to be used
eUsed = x(:,2);
Tindoor = x(:,4);
Qsolar = x(:,3);
OutIn = x(:,1);
Tpredict = zeros(length(x),length(D));
Tdifference = zeros(length(x),length(D));
Tsum=zeros(1,length(D));
RMSE = zeros(1,length(D));

for p=1:length(D)
    for o =1:length(x)
        Tpredict(o,p) = D(1,p)*OutIn(o) +D(2,p)*eUsed(o) + D(3,p)*Qsolar(o); % Calculating the predicted (future indoor temp - current indoor temp)/dt
        Tdifference(o,p)=(Tindoor(o)-Tpredict(o,p))^2; % squaring the difference between the preidction and the true value
        Tsum(1,p)=Tsum(1,p)+Tdifference(o,p); % summing the squares
    end
    RMSE(1,p) = sqrt(Tsum(1,p)/length(x)); % calculating the RMSE
end
%%

Tipredict = zeros(length(x),length(D));
Tidifference = zeros(length(x),length(D));
Tisum=zeros(1,length(D));
RMSEi = zeros(1,length(D));

for p=1:length(D)
    for o =1:length(x)
        Tipredict(o,p) = 5*60*(D(1,p)*OutIn(o) +D(2,p)*eUsed(o) + D(3,p)*Qsolar(o));
        Tidifference(o,p)=(Tindoor(o)-Tipredict(o,p))^2;
        Tisum(1,p)=Tisum(1,p)+Tidifference(o,p);
    end
    RMSEi(1,p) = sqrt(Tisum(1,p)/length(x));
end