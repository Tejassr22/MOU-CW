clc; clear; close all;

% Load Benchmark Functions
benchmarkFuncs = {@sphereFunction, @rosenbrockFunction, @rastriginFunction};
benchmarkNames = {'Sphere', 'Rosenbrock', 'Rastrigin'};

% Dimensions to evaluate
dimensionSizes = [2, 10];

% Number of runs
iterations = 15;

% Initialize storage
evaluationResults = struct();

for idxFunc = 1:numel(benchmarkFuncs)
    currentFunc = benchmarkFuncs{idxFunc};
    funcName = benchmarkNames{idxFunc};

    for idxDim = 1:numel(dimensionSizes)
        D = dimensionSizes(idxDim);

        % Set bounds
        lb = -10 * ones(1, D);
        ub = 10 * ones(1, D);
        
        performanceData = struct('SA', [], 'DE', [], 'PSO', []);

        for trial = 1:iterations
            fprintf('Running %s | Dimension: %d | Trial: %d\n', funcName, D, trial);
            
            % Simulated Annealing (SA)
            saOpts = saoptimset('Display', 'off');
            [~, fval] = simulannealbnd(@(x) currentFunc(x, D), rand(1,D).*(ub-lb) + lb, lb, ub, saOpts);
            performanceData.SA(end+1,1) = fval;

            % Differential Evolution (DE)
            deOpts = optimoptions('ga', 'Display', 'off', 'PopulationType', 'doubleVector', 'MutationFcn', {@mutationadaptfeasible});
            [~, fval] = ga(@(x) currentFunc(x, D), D, [], [], [], [], lb, ub, [], deOpts);
            performanceData.DE(end+1,1) = fval;
            
            % Particle Swarm Optimization (PSO)
            psoOpts = optimoptions('particleswarm', 'Display', 'off');
            [~, fval] = particleswarm(@(x) currentFunc(x, D), D, lb, ub, psoOpts);
            performanceData.PSO(end+1,1) = fval;
        end

        % Store results
        key = sprintf('Dim%d', D);
        evaluationResults.(funcName).(key) = performanceData;
        
        % Display
        fprintf('\n=== %s (D=%d) ===\n', funcName, D);
        fprintf('SA  - Mean: %.4f | Std: %.4f | Best: %.4f | Worst: %.4f\n', ...
            mean(performanceData.SA), std(performanceData.SA), min(performanceData.SA), max(performanceData.SA));
        fprintf('DE  - Mean: %.4f | Std: %.4f | Best: %.4f | Worst: %.4f\n', ...
            mean(performanceData.DE), std(performanceData.DE), min(performanceData.DE), max(performanceData.DE));
        fprintf('PSO - Mean: %.4f | Std: %.4f | Best: %.4f | Worst: %.4f\n', ...
            mean(performanceData.PSO), std(performanceData.PSO), min(performanceData.PSO), max(performanceData.PSO));
        
        % Plot
        figure;
        hold on;
        plot(performanceData.SA, '-o', 'DisplayName', 'SA');
        plot(performanceData.DE, '-x', 'DisplayName', 'DE');
        plot(performanceData.PSO, '-s', 'DisplayName', 'PSO');
        xlabel('Run Number');
        ylabel('Objective Function Value');
        title(sprintf('Performance Comparison on %s (Dimension=%d)', funcName, D));
        legend;
        grid on;
        hold off;
    end
end
