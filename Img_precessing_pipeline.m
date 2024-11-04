% Computer Vision and CNN, Johnstone
% simulating the image processing pipeline on a raw image

% please use the following variable names for images at intermediate stages:
% raw:       raw image
% im_linear: linearized image
% im_zoom:   zoomed image showing Bayer pattern
% im_bggr, im_rggb, im_grbg, im_gbrg: brightened quarter-resolution RGB images
%                                     (for the 4 Bayer pattern candidates)
% im_gw, im_ww: white-balanced images under grey and white assumptions
% im_rgb:       demosaicked RGB image
% im_final:     final image

clear; close all; clc

% read the image (raw.tiff) as-is
% write its width, height, and type to the file 'hw2-24fa73.txt'
% write its min and max values to the file
% display the image (before casting to double); use the title 'raw image'
% cast the image to double
raw = imread('raw.tiff');
size(raw);
class(raw);
min(raw(:));
max(raw(:));
imshow(raw), title('raw image');
raw = double(raw);
%imshow(raw), title('image')

fprintf('Program paused. Press enter to continue.\n');
pause;
% -----------------------------------------------------------------------------
% linearize: map black to 0 and white to 1, then clamp to [0,1]

% display the new image with the title 'linearized'
% and write to 'linearized.jpg'
b = 2047;
s = 13584;
im_linear = (raw - b) / (s - b);
im_linear = min(max(im_linear, 0), 1);
figure;
imshow(im_linear), title('linearized');
imwrite(im_linear, 'linearized.jpg');
fprintf('Program paused. Press enter to continue.\n');
pause;
% -----------------------------------------------------------------------------
% 3. visualize the Bayer mosaic

% extract the 100x100 patch with top-right corner at (1000,1000)
% display a zoomed version of this image with the title
% 'visualizing the Bayer mosaic' and write to 'zoomed.jpg'
im_zoom = im_linear(1000:1099, 1000:1099);

im_zoom = min(im_zoom * 5, 1);
figure;
imshow(im_zoom,'InitialMagnification', 'fit');
title('visualizing the Bayer mosaic');
imwrite(im_zoom, 'zoomed.jpg');

fprintf('Program paused. Press enter to continue.\n');
pause;
% -----------------------------------------------------------------------------
% 4. discover the Bayer pattern

% extract quarter-resolution images from the linearized image
% suggested variable names: top_left, top_right, bot_left, bot_right

% build 4 quarter-resolution RGB images, one per Bayer mosaic candidate
% hint: given a Bayer candidate, which subimage represents red? (draw a 2x2 box)

% display 4 brightened quarter-resolution RGB images, 
% labeled by their mosaic 4-tuple (e.g., bggr) in a 2x2 grid

% choose the best one for downstream processing (hint: use the shirt)
% write your chosen Bayer pattern choice to 'hw2-24fa73.txt' and to the screen

% write the associated brightened quarter-resolution image to 'best_bayer.jpg'

top_left = im_linear(1:2:end, 1:2:end); %blue_channel
bot_left = im_linear(2:2:end, 1:2:end); %green_channel1
top_right = im_linear(1:2:end, 2:2:end); %green_channel2
bot_right = im_linear(2:2:end, 2:2:end); %red_channel

im_bggr = cat(3, bot_right, (bot_left + top_right) / 2, top_left);
im_rggb = cat(3, top_left,(bot_left+top_right)/2, bot_right);
im_gbrg = cat(3, bot_left,(top_left+bot_right)/2, top_right);
im_grbg = cat(3, top_right,(top_left+bot_right)/2, bot_left);

im_bggr = im_bggr * 4;
im_rggb = im_rggb * 4;
im_gbrg = im_gbrg * 4;
im_grbg = im_grbg * 4;

figure;
subplot(2, 2, 1), imshow(im_bggr), title('BGGR');
subplot(2, 2, 2), imshow(im_rggb), title('RGGB');
subplot(2, 2, 3), imshow(im_gbrg), title('GBRG');
subplot(2, 2, 4), imshow(im_grbg), title('GRBG');

best_pattern = im_bggr;

figure;
imshow(best_pattern);
title('Chosen pattern: BGGR');
imwrite(best_pattern,'best_bayer.jpg')
fprintf('Program paused. Press enter to continue.\n');
pause;
% -----------------------------------------------------------------------------
% 5. white balance

% extract the red, blue, and green channels from the original Bayer mosaic
% (using your choice of the underlying Bayer pattern)

% white-balance the Bayer mosaic under the grey-world assumption:
% 1) find the mean of each channel
% 2) inject the white-balanced red/blue channels back into a new mosaic;
%    inject the original green channels (both of them) back too;
% call the new Bayer mosaic image im_gw 

% white-balance the Bayer mosaic using the white-world assumption:
% 1) find the maximum of each channel
% 2) inject back into a new mosaic called im_ww

% display the white-balanced images, with labels 'grey-world' and 'white-world',
% as a 2x1 grid;
% write them to 'grey_world.jpg' and 'white_world.jpg'
R_avg = mean(bot_right(:));
G_avg = mean([bot_left(:); top_right(:)]);
B_avg = mean(top_left(:));

%white balancing using grey world
red_gw = bot_right * (G_avg / R_avg);
blue_gw = top_left * (G_avg / B_avg);

im_gw = cat(3, red_gw, (bot_left + top_right)/2, blue_gw);

R_max = max(bot_right(:));
G_max = max([bot_left(:); top_right(:)]);
B_max = max(top_left(:));

%white world
red_ww = bot_right * (G_max / R_max);
blue_ww = top_left * (G_max / B_max);

im_ww = cat(3, red_ww, (bot_left + top_right)/2, blue_ww);

figure;
subplot(2,1,1), imshow(im_gw), title('Grey-World');
subplot(2,1,2), imshow(im_ww), title('White-World');

imwrite(im_gw, 'grey_world.jpg');
imwrite(im_ww, 'white_world.jpg');

fprintf('Program paused. Press enter to continue.\n');
pause;
% -----------------------------------------------------------------------------
% 6. demosaicing [673/773 only]

% choose one of the white-balanced images, store in im, and work with im
% (so that you can easily shift white-balancing assumptions)

% build the red channel, using bilinear interpolation

% a) insert the existing red pixels directly
% b) ind the coordinates of the red pixels in the Bayer pattern
%   notes: standard geometric coords rather than image, in both input and output
%   and cannot use end;
%   hint: what are the dimensions of an image in conventional x and y,
%   which is what meshgrid expects
% c) insert the missing pixels using bilinear interpolation, 1/4 at a time


% build the blue channel, using bilinear interpolation

% build the green channel, using bilinear interpolation
% a) insert the existing green pixels directly
% b) find the coordinates of the green pixels in the Bayer pattern (two sets)
% c) insert the missing pixels using bilinear interpolation, 1/4 at a time:
%    compute both ways (using both available green pixels) and average them;
%    recall vectorized operators and that the average of two values is (a+b)/2;

% now that all channels are available, 
% build the 3-channel RGB image, called im_rgb

% write it to 'demosaicked.jpg', and display it, labeled 'demosaicked'
% display the red/green/blue channels and the rgb image in a 2x2 grid

im = im_ww;
[height, width, channels] = size(im);

[Xq, Yq] = meshgrid(1:width, 1:height);

%red channel
red_exist = im(2:2:end, 2:2:end, 3);
[Xr, Yr] = meshgrid(2:2:width, 2:2:height);
red_full = interp2(Xr, Yr, double(red_exist), Xq, Yq, 'linear', 0); 

%blue channel
blue_exist = im(1:2:end, 1:2:end, 1);
[Xb, Yb] = meshgrid(1:2:width, 1:2:height);
blue_full = interp2(Xb, Yb, double(blue_exist), Xq, Yq, 'linear', 0);

%green channed
green_exist1 = im(1:2:end, 2:2:end, 2);
green_exist2 = im(2:2:end, 1:2:end, 2);
[Xg1, Yg1] = meshgrid(2:2:width, 1:2:height);
[Xg2, Yg2] = meshgrid(1:2:width, 2:2:height);
green_full1 = interp2(Xg1, Yg1, double(green_exist1), Xq, Yq, 'linear', 0);
green_full2 = interp2(Xg2, Yg2, double(green_exist2), Xq, Yq, 'linear', 0);

green_full = (green_full1 + green_full2) / 2;

im_rgb = cat(3, red_full, green_full, blue_full); 
im_rgb = im_rgb / max(im_rgb(:)); 

imwrite(im_rgb, 'demosaicked.jpg');
figure;
imshow(im_rgb), title('demosaicked');

figure;
subplot(2,2,1), imshow(red_full), title('Red channel');
subplot(2,2,2), imshow(green_full), title('Green channel');
subplot(2,2,3), imshow(blue_full), title('Blue channel');
subplot(2,2,4), imshow(im_rgb), title('RGB Image');

fprintf('Program paused. Press enter to continue.\n');
pause;
% -----------------------------------------------------------------------------
% 7. brighten and gamma-correct

% convert to grayscale to discover max luminance
% scale (brighten) the image, capped by 1
% report the brightening factor to hw2-24fa73.txt
% write to 'brightened.jpg' and display with title 'brightened'
grey_image = rgb2gray(im_rgb);
max_luminance = max(grey_image(:));
bright_image = min(im_rgb * 2.5,1);
imwrite(bright_image,'brightened.jpg');
figure;
imshow(bright_image), title('brightened');

fprintf('Program paused. Press enter to continue.\n');
pause;

% build a gamma corrected image
% display this final image with title 'final'
% write to final.png and final.jpg (which compresses)
% then find a minimal quality that is indistinguishable from uncompressed png
% and report this quality and its compression ratio to hw2-24fa73.txt
g = 2.2;
im_final = bright_image.^(1/g);
figure;
imshow(im_final), title('final');
imwrite(im_final, 'final.png');
imwrite(im_final, 'final.jpg', 'Quality',30);

png = dir('final.png').bytes;
jpg = dir('final.jpg').bytes;
compression_ratio = png/jpg;
disp(compression_ratio);
% report your favourite white balancing algorithm to hw2-24fa73.txt
% (after running pipeline both ways)
