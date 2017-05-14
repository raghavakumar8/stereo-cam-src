%imlcones = rgb2gray(imread('cam_l2.png'));
%imrcones = rgb2gray(imread('cam_r2.png'));

imfull = rgb2gray(imread('cam_full.JPG'));

imleft = imresize(imfull(:,961:1920), [480 427]);
imright = imresize(imfull(:,1:960), [480 427]);

imlcones = imleft(1:478, :);
imrcones = imright(3:480, :);

size(imlcones)
size(imrcones)

%iml_n = imnoise(imlcones,'gaussian',0, 0.01);
%imr_n = imnoise(imrcones,'gaussian',0, 0.01);

%iml_n_filtered = imgaussfilt(iml_n, 2);
%imr_n_filtered = imgaussfilt(imr_n, 2);

%iml_n_edge = edge(iml_n_filtered, 'Canny', 0.3);
%imr_n_edge = edge(imr_n_filtered, 'Canny', 0.3);

w     = 5;       % bilateral filter half-width
sigma = [3 0.1]; % bilateral filter standard deviations

%iml_n_blftl = bfilter2(double(iml_n)/255,w,sigma);
%imr_n_blftl = bfilter2(double(imr_n)/255,w,sigma);

%imshow(iml_n_blftl);

census_match(imlcones, imrcones, 32);
%census_match(iml_n, imr_n, 60);