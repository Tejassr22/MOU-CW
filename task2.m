%% Optimization Comparison on CEC'2005 Benchmark Functions

clc; clear; close all;

%% Define Optimization Parameters
D_values = [2, 10];  % Dimensions to test
pop_size = 50;       % Population size
max_iter = 1000;     % Maximum iterations
num_runs = 15; % Run each algorithm 15 times

% Benchmark Functions
benchmark_functions = {@sphere_function, @rosenbrock_function, @rastrigin_function};
function_names = {'Sphere', 'Rosenbrock', 'Rastrigin'};

% Store results
results_table = [];

%% Run Optimization for Different Methods
for D = D_values
    fprintf('\nRunning optimizations for D = %d...\n', D);
    
    for i = 1:length(benchmark_functions)
        f = benchmark_functions{i};
        
        fprintf('Optimizing %s function...\n', function_names{i});
        
        % Track convergence
        de_convergence = zeros(1, max_iter);
        pso_convergence = zeros(1, max_iter);
        sa_convergence = zeros(1, max_iter);
        
        % Run Differential Evolution (DE)
        tic;
        [de_result, de_convergence] = differential_evolution(f, D, pop_size, max_iter);
        de_time = toc;
        
        % Run Custom Particle Swarm Optimization (PSO)
        tic;
        [pso_result, pso_convergence] = custom_pso(f, D, pop_size, max_iter);
        pso_time = toc;
        
        % Run Custom Simulated Annealing (SA)
        tic;
        [sa_result, sa_convergence] = custom_sa(f, D, max_iter);
        sa_time = toc;
        
        % Store results
        results_table = [results_table; {function_names{i}, D, 'DE', f(de_result), de_time};
                                       {function_names{i}, D, 'PSO', f(pso_result), pso_time};
                                       {function_names{i}, D, 'SA', f(sa_result), sa_time}];
        
        % Display Results
        fprintf('DE Best Fitness: %f (Time: %.2f sec)\n', f(de_result), de_time);
        fprintf('PSO Best Fitness: %f (Time: %.2f sec)\n', f(pso_result), pso_time);
        fprintf('SA Best Fitness: %f (Time: %.2f sec)\n\n', f(sa_result), sa_time);
        
        % Plot Convergence
        figure;
        plot(1:max_iter, de_convergence, 'r', 'LineWidth', 2);
        hold on;
        plot(1:max_iter, pso_convergence, 'b', 'LineWidth', 2);
        plot(1:max_iter, sa_convergence, 'g', 'LineWidth', 2);
        xlabel('Iterations'); ylabel('Fitness Value');
        title(sprintf('%s Function (D = %d)', function_names{i}, D));
        legend('DE', 'PSO', 'SA');
        grid on;
    end
end

% Convert results to table and display
results_table = cell2table(results_table, 'VariableNames', {'Function', 'Dimension', 'Algorithm', 'BestFitness', 'Runtime'});
disp(results_table);

%% Benchmark Functions
function y = sphere_function(x)
    y = sum(x.^2);
end

function y = rosenbrock_function(x)
    y = sum(100 * (x(2:end) - x(1:end-1).^2).^2 + (1 - x(1:end-1)).^2);
end

function y = rastrigin_function(x)
    y = sum(x.^2 - 10 * cos(2 * pi * x) + 10);
end

%% Custom Simulated Annealing (SA)
function [best_solution, convergence] = custom_sa(f, D, max_iter)
    T = 1.0; % Initial temperature
    alpha = 0.99; % Cooling rate
    lb = -5 * ones(1, D);
    ub = 5 * ones(1, D);
    
    best_solution = lb + (ub - lb) .* rand(1, D);
    best_fitness = f(best_solution);
    convergence = zeros(1, max_iter);
    
    for iter = 1:max_iter
        candidate = best_solution + 0.1 * randn(1, D);
        candidate = max(min(candidate, ub), lb);
        candidate_fitness = f(candidate);
        
        if candidate_fitness < best_fitness || rand < exp((best_fitness - candidate_fitness) / T)
            best_solution = candidate;
            best_fitness = candidate_fitness;
        end
        
        convergence(iter) = best_fitness;
        T = T * alpha; % Cool down
    end
end

%% Differential Evolution Algorithm
function [best_solution, convergence] = differential_evolution(f, D, pop_size, max_iter)
    F = 0.8; % Mutation factor
    CR = 0.9; % Crossover rate
    lb = -5 * ones(1, D); % Lower bounds
    ub = 5 * ones(1, D); % Upper bounds
    
    % Initialize population
    pop = lb + (ub - lb) .* rand(pop_size, D);
    fitness = arrayfun(@(i) f(pop(i, :)), 1:pop_size);
    [best_fitness, best_idx] = min(fitness);
    best_solution = pop(best_idx, :);
    convergence = zeros(1, max_iter);
    
    for iter = 1:max_iter
        for i = 1:pop_size
            % Mutation
            r = randperm(pop_size, 3);
            mutant = pop(r(1), :) + F * (pop(r(2), :) - pop(r(3), :));
            mutant = max(min(mutant, ub), lb);
            
            % Crossover
            crossover = rand(1, D) < CR;
            if ~any(crossover)
                crossover(randi(D)) = true;
            end
            trial = pop(i, :);
            trial(crossover) = mutant(crossover);
            
            % Selection
            trial_fitness = f(trial);
            if trial_fitness < fitness(i)
                pop(i, :) = trial;
                fitness(i) = trial_fitness;
            end
        end
        [best_fitness, best_idx] = min(fitness);
        best_solution = pop(best_idx, :);
        convergence(iter) = best_fitness;
    end
end

%% Custom Particle Swarm Optimization (PSO)
function [best_solution, convergence] = custom_pso(f, D, pop_size, max_iter)
    w = 0.7; c1 = 1.5; c2 = 1.5;
    lb = -5 * ones(1, D);
    ub = 5 * ones(1, D);
    
    pop = lb + (ub - lb) .* rand(pop_size, D);
    velocity = zeros(pop_size, D);
    fitness = arrayfun(@(i) f(pop(i, :)), 1:pop_size);
    [best_fitness, best_idx] = min(fitness);
    best_solution = pop(best_idx, :);
    convergence = zeros(1, max_iter);
    
    for iter = 1:max_iter
        for i = 1:pop_size
            velocity(i, :) = w * velocity(i, :) + c1 * rand .* (best_solution - pop(i, :)) + c2 * rand .* (pop(best_idx, :) - pop(i, :));
            pop(i, :) = max(min(pop(i, :) + velocity(i, :), ub), lb);
            fitness(i) = f(pop(i, :));
        end
        [best_fitness, best_idx] = min(fitness);
        best_solution = pop(best_idx, :);
        convergence(iter) = best_fitness;
    end
end
