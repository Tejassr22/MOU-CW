% ============================================
% Simulated Annealing (SA) Optimization for Sugeno FIS
% ============================================

clc; clear; close all;

% Load the Sugeno FIS
fis = readfis('patient_monitoring.fis');

% Add fallback rules to avoid "No rules fired" warnings
fallbackRules = [
    "HeartRate==Low & Temperature==Low => AlertLevel=Low (0.5)";
    "HeartRate==Low & Temperature==High => AlertLevel=Medium (0.5)";
    "HeartRate==High & Temperature==Low => AlertLevel=Medium (0.5)";
    "HeartRate==High & Temperature==High => AlertLevel=High (0.5)";
    "HeartRate==Normal => AlertLevel=Medium (0.5)";
    "Temperature==Normal => AlertLevel=Medium (0.5)";
];
fis = addRule(fis, fallbackRules);

% Define parameter bounds for optimization
lowerBound = [50, 50, 60, 70, 70, 80, 90, 100, 110, 120, 130, 35, 35, 36, 37, 36.5, 37.5, 38.5, 38, 39, 40, 42];
upperBound = [60, 70, 80, 100, 80, 100, 110, 120, 130, 140, 150, 36, 37, 38, 40, 37.5, 38.5, 39.5, 39, 41, 43, 44];

% Objective function for SA optimization
objectiveFunction = @(params) evaluateFISPerformance(fis, params);

% Simulated Annealing Options
saOptions = optimoptions('simulannealbnd', ...
    'MaxIterations', 300, ... % Increased iterations
    'Display', 'iter');

% Run Simulated Annealing
[optimalParams, optimalScore] = simulannealbnd(objectiveFunction, ...
    (lowerBound + upperBound) / 2, lowerBound, upperBound, saOptions);

% Update FIS with optimized parameters
fis = updateFISParameters(fis, optimalParams);

% Save Optimized FIS
writeFIS(fis, 'optimized_patient_monitoring_sa.fis');
disp('Optimized FIS saved as optimized_patient_monitoring_sa.fis');

% =============================================
% Helper Function: Evaluate FIS Performance
% =============================================
function performance = evaluateFISPerformance(fis, params)
    % Map the parameters to the FIS
    fis = updateFISParameters(fis, params);
    
    % Define test cases and expected outputs (ground truth)
    testCases = [
        50, 35; % Case 1
        80, 37; % Case 2
        100, 39; % Case 3
    ];
    expectedOutput = [0; 0.5; 1]; % Expected Alert Levels

    % Compute the Mean Squared Error (MSE)
    mse = 0;
    for i = 1:size(testCases, 1)
        output = evalfis(fis, testCases(i, :));
        mse = mse + (expectedOutput(i) - output)^2;
    end
    mse = mse / size(testCases, 1);
    
    % Fitness is negative MSE (as SA minimizes the fitness function)
    performance = -mse;
end

% =============================================
% Helper Function: Update FIS Parameters
% =============================================
function fis = updateFISParameters(fis, params)
    % Validate parameter assignment for trapezoidal and triangular membership functions
    
    % Ensure trapezoidal parameters follow logical order
    % Heart Rate (Input 1)
    fis.Inputs(1).MembershipFunctions(1).Parameters = sort([params(1), params(2), params(3), params(4)]); % "Low" (trapmf)
    fis.Inputs(1).MembershipFunctions(2).Parameters = sort([params(5), params(6), params(7)]);            % "Normal" (trimf)
    fis.Inputs(1).MembershipFunctions(3).Parameters = sort([params(8), params(9), params(9)+10, params(10)]); % "High" (trapmf)

    % Temperature (Input 2)
    fis.Inputs(2).MembershipFunctions(1).Parameters = sort([params(11), params(12), params(13), params(14)]); % "Low" (trapmf)
    fis.Inputs(2).MembershipFunctions(2).Parameters = sort([params(15), params(16), params(17)]);             % "Normal" (trimf)
    fis.Inputs(2).MembershipFunctions(3).Parameters = sort([params(18), params(19), params(19)+5, params(20)]); % "High" (trapmf)
end
