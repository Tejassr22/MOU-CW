% ===============================
% Sugeno Fuzzy Logic Controller (FLC) for Patient Monitoring
% Implementation in MATLAB with GUI & Performance Evaluation
% ===============================

clc; clear; close all;

%% Create Sugeno Fuzzy Inference System
fis = sugfis('Name', 'PatientMonitoring');

%% Define Input Variables

% Heart Rate (HR) - Low, Normal, High
fis = addInput(fis, [50 150], 'Name', 'HeartRate');
fis = addMF(fis, 'HeartRate', 'gaussmf', [10 50], 'Name', 'Low');
fis = addMF(fis, 'HeartRate', 'gaussmf', [10 90], 'Name', 'Normal');
fis = addMF(fis, 'HeartRate', 'gaussmf', [10 150], 'Name', 'High');

% Blood Pressure (BP) - Hypotension, Normal, Hypertension
fis = addInput(fis, [80 180], 'Name', 'BloodPressure');
fis = addMF(fis, 'BloodPressure', 'gaussmf', [10 80], 'Name', 'Hypotension');
fis = addMF(fis, 'BloodPressure', 'gaussmf', [10 120], 'Name', 'Normal');
fis = addMF(fis, 'BloodPressure', 'gaussmf', [10 180], 'Name', 'Hypertension');

% Oxygen Saturation (SpO2) - Low, Normal
fis = addInput(fis, [80 100], 'Name', 'SpO2');
fis = addMF(fis, 'SpO2', 'gaussmf', [5 80], 'Name', 'Low');
fis = addMF(fis, 'SpO2', 'gaussmf', [5 100], 'Name', 'Normal');

% Temperature - Low, Normal, High
fis = addInput(fis, [35 40], 'Name', 'Temperature');
fis = addMF(fis, 'Temperature', 'gaussmf', [0.5 35], 'Name', 'Low');
fis = addMF(fis, 'Temperature', 'gaussmf', [0.5 37], 'Name', 'Normal');
fis = addMF(fis, 'Temperature', 'gaussmf', [0.5 40], 'Name', 'High');

%% Define Output Variable (Risk Level)
fis = addOutput(fis, [0 2], 'Name', 'RiskLevel');

% Sugeno Output MFs (Constant values)
fis = addMF(fis, 'RiskLevel', 'constant', 0, 'Name', 'Normal');
fis = addMF(fis, 'RiskLevel', 'constant', 1, 'Name', 'AtRisk');
fis = addMF(fis, 'RiskLevel', 'constant', 2, 'Name', 'Critical');

%% Define Fuzzy Rules

ruleList = [...
    "If HeartRate is High and BloodPressure is Hypertension then RiskLevel is Critical";
    "If SpO2 is Low then RiskLevel is Critical";
    "If HeartRate is Normal and BloodPressure is Normal and SpO2 is Normal then RiskLevel is Normal";
    "If HeartRate is Low and BloodPressure is Hypotension then RiskLevel is AtRisk";
    "If Temperature is High then RiskLevel is AtRisk";
];
%%
% Add rules to the FIS
fis = addRule(fis, ruleList);
writeFIS(fis,'PatientMonitoring.fis')
fuzzyLogicDesigner('PatientMonitoring.fis')
%% Display FIS Information
disp(fis);

% Plot membership functions
figure;
subplot(2,2,1); plotmf(fis, 'input', 1); title('Heart Rate Membership');
subplot(2,2,2); plotmf(fis, 'input', 2); title('Blood Pressure Membership');
subplot(2,2,3); plotmf(fis, 'input', 3); title('SpO2 Membership');
subplot(2,2,4); plotmf(fis, 'input', 4); title('Temperature Membership');

%% GUI for Real-Time Patient Input
patient_monitoring_gui(fis);

% Function for GUI (Nested within the script)
function patient_monitoring_gui(fis)
    f = figure('Name', 'Patient Monitoring FLC', 'Position', [500, 300, 400, 300]);

    % Input fields
    uicontrol('Style', 'text', 'Position', [50, 250, 120, 20], 'String', 'Heart Rate:');
    hr = uicontrol('Style', 'edit', 'Position', [180, 250, 100, 20]);

    uicontrol('Style', 'text', 'Position', [50, 210, 120, 20], 'String', 'Blood Pressure:');
    bp = uicontrol('Style', 'edit', 'Position', [180, 210, 100, 20]);

    uicontrol('Style', 'text', 'Position', [50, 170, 120, 20], 'String', 'SpO2:');
    sp = uicontrol('Style', 'edit', 'Position', [180, 170, 100, 20]);

    uicontrol('Style', 'text', 'Position', [50, 130, 120, 20], 'String', 'Temperature:');
    temp = uicontrol('Style', 'edit', 'Position', [180, 130, 100, 20]);

    % Button to Evaluate FLC
    uicontrol('Style', 'pushbutton', 'String', 'Evaluate', 'Position', [100, 80, 200, 30],...
        'Callback', @(src, event) evaluate_fis(fis, hr, bp, sp, temp));
    
    % Output field
    outputLabel = uicontrol('Style', 'text', 'Position', [50, 40, 300, 30],...
        'String', 'Risk Level: ');
end

function evaluate_fis(fis, hr, bp, sp, temp)
    hr_val = str2double(get(hr, 'String'));
    bp_val = str2double(get(bp, 'String'));
    sp_val = str2double(get(sp, 'String'));
    temp_val = str2double(get(temp, 'String'));

    if isnan(hr_val) || isnan(bp_val) || isnan(sp_val) || isnan(temp_val)
        errordlg('Please enter valid numeric values!', 'Input Error');
        return;
    end

    % Evaluate the FLC
    risk_level = evalfis(fis, [hr_val, bp_val, sp_val, temp_val]);
    
    % Round the result to the nearest integer to get a discrete value (0, 1, or 2)
    risk_level = round(risk_level);

    % Display Result
    msg = sprintf('Predicted Risk Level: %.0f', risk_level);
    msgbox(msg, 'Result');
end


%% Performance Testing with Sample Cases
testCases = [
    110, 140, 90, 38;  % High risk
    80, 100, 95, 37;   % Normal
    130, 160, 85, 39;  % Critical
    70, 90, 100, 36;   % At Risk
];

fprintf('Testing the FLC with sample patient data:\n');
for i = 1:size(testCases, 1)
    result = evalfis(fis, testCases(i, :));
    fprintf('Test Case %d: HR=%d, BP=%d, SpO2=%d, Temp=%.1f --> Risk Level: %.2f\n', ...
        i, testCases(i, 1), testCases(i, 2), testCases(i, 3), testCases(i, 4), result);
end
