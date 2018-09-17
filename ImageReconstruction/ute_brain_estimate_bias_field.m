function im_biasfield = ute_brain_estimate_bias_field(imute, brainmask)

% estimate bias field, normalize

brainmask_open = imdilate(brainmask, strel('disk', 16));
brainmask_open = permute(imdilate(permute(brainmask_open, [3 2 1]), strel('disk', 6)), [3 2 1]);
im_biasfield = imgaussfilt3(abs(imute).*brainmask_open,6);
I = find(brainmask);
Snormall = max(abs(imute(I)));

im_biasfield = im_biasfield / Snormall;

% figure(1)
% disp3d(imbias)