function disparity_map = census_match(left, right, maxdisp)
% disparity_map = correlation_match(left, right, maxdisp): given a pair of stereo
% images, calculates the disparity (along horizontal direction) subject
% to a maximum of maxdisp. The direction of matching is specified by dir
%
% left    : the left image in the stereo pair
% right   : the right image in the stereo pair
% maxdisp : maximum disparity accepted
% dir     : 0 (default) => left-to-right matching, 1 => right-to-left matching
%
% disparity_map: disparity map- image of the same size as input image
% but the left (or right) edge is incorrect

%filtering with laplacian of gaussian
% lapOfGauss = [0 -1 0 ; -1 4 -1 ; 0 -1 0];
% l1 = conv2(left, lapOfGauss,'same');
% r1 = conv2(right, lapOfGauss,'same');
% %figure;imagesc(l1);colormap(gray);axis image;
% left = l1;
% right = r1;

left = conv2(left, ones(3,3), 'same');
right = conv2(right, ones(3,3), 'same');

[m n]=size(left);

%window size
windowSize = 3;
postCensusWindowSize = 3;
window = ones(1, postCensusWindowSize);

% 3D array, used to store 0:maxdisp correlation values for each pixel
img = zeros(m - windowSize + 1,n - windowSize + 1,1+maxdisp);

% tmp array used to store corr. values
diss  = zeros(m - windowSize + 1,n - windowSize + 1);

%kernel to sum across the window
corrSumKernel =window'*window; %should probably be made two separate
                               %1-D convs

%do the census transform
leftCen = zeros(m-windowSize+1, n-windowSize+1, windowSize*windowSize);
rightCen = zeros(m-windowSize+1, n-windowSize+1, windowSize*windowSize);

%Generate the censur matrix for both left and right images
for y=1:m-windowSize+1
    for x=1:n-windowSize+1
        centerY = y+(windowSize-1)/2;
        centerX = x+(windowSize-1)/2;
        centerPixL = left(centerY, centerX);
        centerPixR = right(centerY, centerX);
        for j=0:windowSize-1
            for i=0:windowSize-1
                currentPixL = left(y+j, x+i);
                currentPixR = right(y+j, x+i);
                %if pixel > center pixel, then 1, else 0
                leftCen(y, x, j*9 + i + 1) = currentPixL > centerPixL;
                rightCen(y, x, j*9 + i + 1) = currentPixR > centerPixR;
            end
        end
    end
end

h = waitbar(0,'Computing disparity...');
set(h,'Name','Disparity progress');

for d=0:maxdisp
    diss(:) = Inf;
    
    for y = 1:m-windowSize+1
        for x = 1:n-windowSize+1-d
            leftCenVec = leftCen(y, x+d, :);
            rightCenVec = rightCen(y, x, :);
            
            hammingVec = xor(leftCenVec, rightCenVec);
            hammingDist = sum(hammingVec);
            
            diss(y, x) = hammingDist;
        end
    end
    
    img(:,:,d+1) = conv2(diss,corrSumKernel,'same');
    %img(:,:,d+1) = diss;
    waitbar(d/maxdisp);
end

% Close waitbar.
close(h);

%[valMin,indMin]=min(img,[],3);
[valMin2, indMin2] = sort(img, 3, 'ascend');
minSAD = valMin2(:,:,1);
min2SAD = valMin2(:,:,2);
uniqueCheck = arrayfun(@(min1, min2) (min1 + min1/4) < min2, minSAD, min2SAD);
dmapUnique = uniqueCheck.*indMin2(:,:,1) + (1 - uniqueCheck).*indMin2(:,:,3);
disparity_map = indMin2(:,:,1)-1;
%figure;imagesc(minSAD - min2SAD);colormap(gray);axis image;
if (nargout ==0) %show output only if the user didn't specify an output
                 %image
  %figure;imagesc(dmapUnique);colormap(gray);axis image;
  figure;imagesc(disparity_map);colormap(gray);axis image;
end