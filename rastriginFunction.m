function f = rastriginFunction(x, D)
    % Rastrigin function
    f = 10 * D + sum(x.^2 - 10 * cos(2 * pi * x));
end
