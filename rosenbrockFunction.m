function f = rosenbrockFunction(x, D)
    % Rosenbrock function
    f = sum(100*(x(2:D) - x(1:D-1).^2).^2 + (1 - x(1:D-1)).^2);
end
