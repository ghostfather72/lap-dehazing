%% For laproscopic image dehazing
close all;

%% Estimate for A
% We need a handle on finding A for which we will use the method proposed

    Orig_image = imread('I1.png');
%     Orig_image = imresize(Orig_image,0.10);
    
    Orig_image = double(Orig_image) ./ 255;   
    Orig_image = Orig_image + 0.001*randn(size(Orig_image));
    Clean_image = imread('Original.png');
    Clean_image = im2double(Clean_image);
    % We generate the dark channel prior at every pixel, using window size
    % and zero padding
    
%     dark_ch = makeDarkChannel(Orig_image,3);
    
    %   Estimate Atmosphere
    
    %  We first pick the top 0.1% bright- est pixels in the dark channel.
    %  These pixels are most haze- opaque (bounded by yellow lines in 
    %  Figure 6(b)). Among these pixels, the pixels with highest intensity 
    %  in the input image I is selected as the atmospheric light.     
    %
    % TL;DR  TAKE .1% of the brightest pixels
%     dimJ = size(dark_ch);
%     numBrightestPixels = ceil(0.001 * dimJ(1) * dimJ(2)); % Use the cieling to overestimate number needed
%     
%     A_est = estimateA(Orig_image,dark_ch,numBrightestPixels);
    A_est = imread('A.png');
    A_est = im2double(A_est);  
    A = [A_est(1,1,1)  A_est(1,1,2)  A_est(1,1,3)];
    
%% Manually to be tuned parameters

% tau = 0.05; % gradient descent step size
% beta = 0.99; % huber function parameter for t(x)
% gamma = 0.001; % huber function parameter for J(x)
% delta = 0.0001; % weight for the Dark Channel Prior
% beta_of = 0.2; % constant multiplier to priorpenelty(t(x)) in objective function
% gamma_of = 0.2; % constant multiplier to priorpenelty(J(x)) in objective function
% k_green = 2.3952;
% k_blue = 2.7056;
% k_red = 4.1693;
% theta_green = 23.8942;
% theta_blue = 20.20;
% theta_red = 25.1374;
% conv_par = 0.02; % Convergence parameter for gradient descent
% max_iter = 101; % Maximum iterations

% tau = 0.05; % gradient descent step size
% beta = 0.99; % huber function parameter for t(x)
% gamma = 0.001; % huber function parameter for J(x)
% delta = 0.01; % weight for the Dark Channel Prior
% beta_of = 0.2; % constant multiplier to priorpenelty(t(x)) in objective function
% gamma_of = 0.2; % constant multiplier to priorpenelty(J(x)) in objective function
% k_green = 2.3952;
% k_blue = 2.7056;
% k_red = 4.1693;
% theta_green = 23.8942;
% theta_blue = 20.20;
% theta_red = 25.1374;
% conv_par = 0.02; % Convergence parameter for gradient descent
% max_iter = 50; % Maximum iterations

tau = 0.05; % gradient descent step size
beta = 0.9; % huber function parameter for t(x)
gamma = 0.01; % huber function parameter for J(x)
delta = 0.0003; % weight for the Dark Channel Prior
beta_of = 0.2; % constant multiplier to priorpenelty(t(x)) in objective function
gamma_of = 0.2; % constant multiplier to priorpenelty(J(x)) in objective function
k_green = 2.3952;
k_blue = 2.7056;
k_red = 4.1693;
theta_green = 23.8942;
theta_blue = 20.20;
theta_red = 25.1374;
conv_par = 0.02; % Convergence parameter for gradient descent

max_iter = 500; % Maximum iterations

present_J = double(zeros(size(Orig_image)));

% tau = 0.005; % gradient descent step size
% beta = 0; % huber function parameter for t(x)
% gamma = 0; % huber function parameter for J(x)
% delta = 0.005; % weight for the Dark Channel Prior
% beta_of = 0.2; % constant multiplier to priorpenelty(t(x)) in objective function
% gamma_of = 0.2; % constant multiplier to priorpenelty(J(x)) in objective function
% k_green = 2.3952;
% k_blue = 2.7056;
% theta_green = 23.8942;
% theta_blue = 20.20;
% conv_par = 0.02; % Convergence parameter for gradient descent
% max_iter = 1000; % Maximum iterations

% present_J = double(ones(size(Orig_image)));
k = size(present_J);
present_t = double(ones(k(1),k(2)));

modelFidelityTerm = modelFidelity(Orig_image, present_J, present_t, A);
obj_fn = sum(sum(sum(modelFidelityTerm.^2))) + ...
         beta * edgePrior(present_t, beta_of,0) + ...
         gamma * edgePrior(present_J(:, :, 1), gamma_of, 0) + ...
         gamma * edgePrior(present_J(:, :, 2), gamma_of, 0) + ...
         gamma * edgePrior(present_J(:, :, 3), gamma_of, 0) - ...
         delta * sum(sum(log(gampdf(present_J(:, :, 2), k_green, theta_green) + 10^-10))) - ...
         delta * sum(sum(log(gampdf(present_J(:, :, 3), k_blue, theta_blue) + 10^-10 ))) - ...
         delta * sum(sum(log(gampdf(present_J(:, :, 1), k_red, theta_red) + 10^-10)));
obj_fns = double(zeros(max_iter, 1));
J_update = double(zeros(size(present_J)));
iter = 1;


while iter <= max_iter
    
    obj_fns(iter) = obj_fn;
    
    % Calculate the update
    t_update = 2 * sum(modelFidelityTerm, 3) .* ...
               (A(1) - present_J(:, :, 1) + ...
                A(2) - present_J(:, :, 2) + ...
                A(3) - present_J(:, :, 3)) + ...
                beta * priorUpdate(present_t, beta_of);
    
    for i = 1:3
        J_update(:, :, i) = -2 * modelFidelityTerm(:, :, i) .* present_t + ...
                            gamma * priorUpdate(present_J(:, :, i), gamma_of);
    end
    J_update(:, :, 2) = J_update(:, :, 2) + delta * gamma_derivative(present_J(:, :, 2), k_green, theta_green);
    J_update(:, :, 3) = J_update(:, :, 3) + delta * gamma_derivative(present_J(:, :, 3), k_blue, theta_blue);    
    J_update(:, :, 1) = J_update(:, :, 1) + delta * gamma_derivative(present_J(:, :, 1), k_red, theta_red);
    
    % Perform the update
    present_J = present_J + tau * J_update;
    present_J = check(present_J,0);
    present_J = check(present_J,1);
    present_t = present_t + tau * t_update;
    
    modelFidelityTerm = modelFidelity(Orig_image, present_J, present_t, A);
    obj_fn = sum(sum(sum(modelFidelityTerm).^2)) + ...
         beta * edgePrior(present_t, beta_of,0) + ...
         gamma * edgePrior(present_J(:, :, 1), gamma_of, 0) + ...
         gamma * edgePrior(present_J(:, :, 2), gamma_of, 0) + ...
         gamma * edgePrior(present_J(:, :, 3), gamma_of, 0) - ...
         delta * sum(sum(log(gampdf(present_J(:, :, 2), k_green, theta_green)+ 10^-10))) - ...
         delta * sum(sum(log(gampdf(present_J(:, :, 3), k_blue, theta_blue)+ 10^-10)))- ...
         delta * sum(sum(log(gampdf(present_J(:, :, 1), k_red, theta_red)+ 10^-10)));
    
    disp(iter);
    iter = iter+1;
end

figure;
plot(obj_fns);
figure;
x = imfuse(Orig_image,present_J,'montage');
imshow(x);
figure; imshow(present_t);
figure; imshowpair(present_J,Clean_image,'montage');
% sum(sum(sum(abs(present_J - Clean_image))))