imlcones = rgb2gray(imread('im2.png'));
imrcones = rgb2gray(imread('im6.png'));

%imfull = rgb2gray(imread('cam_full.JPG'));

%imleft = imresize(imfull(:,961:1920), [480 427]);
%imright = imresize(imfull(:,1:960), [480 427]);

%imlcones = imleft(1:478, :);
%imrcones = imright(3:480, :);

size(imlcones)
size(imrcones)

census_match(imlcones, imrcones, 64);