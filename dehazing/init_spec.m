
%% Initialization of the blobs
function D = init_spec(I)
%I = im2double(imread('Spec_haze_sim_3.png'));
% D = zeros(size(I,1),size(I,2));
D = I(:,:,1).^2 + I(:,:,2).^2 + I(:,:,3).^2;
D = D/max(max(D));
D(D<0.8)=0;

% x = imfuse(D,I,'montage','scaling','none');
% imshow(x);

end