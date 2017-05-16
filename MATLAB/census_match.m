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

gaussianFilt = [0.0625 0.125 0.0625; 0.125 0.25 0.125; 0.0625 0.125 0.0625;];

left = conv2(single(left), gaussianFilt, 'same');
right = conv2(single(right), gaussianFilt, 'same');

[m n]=size(left);

%window size
windowSize = 5;
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
leftCen = zeros(m-windowSize+1, n-windowSize+1, 3*3);
rightCen = zeros(m-windowSize+1, n-windowSize+1, 3*3);
leftCenVis = zeros(m-windowSize+1, n-windowSize+1);
rightCenVis = zeros(m-windowSize+1, n-windowSize+1);

%Generate the censur matrix for both left and right images
for y=1:m-windowSize+1
    for x=1:n-windowSize+1
        centerY = y+(windowSize-1)/2;
        centerX = x+(windowSize-1)/2;
        centerPixL = left(centerY, centerX);
        centerPixR = right(centerY, centerX);
        for j=0:(windowSize-1)/2
            for i=0:(windowSize-1)/2
                currentPixL = left(y+j*2, x+i*2);
                currentPixR = right(y+j*2, x+i*2);
                %if pixel > center pixel, then 1, else 0
                leftCen(y, x, j*(windowSize+1)/2 + i + 1) = currentPixL > centerPixL;
                rightCen(y, x, j*(windowSize+1)/2 + i + 1) = currentPixR > centerPixR;
            end
        end
    end
end

% leftCenVis = 128*leftCen(:,:,1) + 64*leftCen(:,:,2) + 32*leftCen(:,:,3) ...
%     + 16*leftCen(:,:,4) + 8*leftCen(:,:,6) + 4*leftCen(:,:,7) ... 
%     + 2*leftCen(:,:,8) + leftCen(:,:,9);
% 
% rightCenVis = 128*rightCen(:,:,1) + 64*rightCen(:,:,2) + 32*rightCen(:,:,3) ...
%     + 16*rightCen(:,:,4) + 8*rightCen(:,:,6) + 4*rightCen(:,:,7) ... 
%     + 2*rightCen(:,:,8) + rightCen(:,:,9);

%do the census windowing
[cen_m, cen_n, cen_l] = size(leftCen);
leftCenWnd = zeros(cen_m-postCensusWindowSize+1, cen_n-postCensusWindowSize+1, 72);
rightCenWnd = zeros(cen_m-postCensusWindowSize+1, cen_n-postCensusWindowSize+1, 72);

%Generate the censur matrix for both left and right images
for y=1:cen_m-postCensusWindowSize+1
    for x=1:cen_n-postCensusWindowSize+1
        % Combine into a single long ass 72 bit vec
        for j=0:(postCensusWindowSize-1)
            for i=0:(postCensusWindowSize-1)
                CenL = leftCen(y + j, x + i,:);
                CenR = rightCen(y + j, x + i,:);
                % Remove the center census bit
                CenL(5) = [];
                CenR(5) = [];
                % Now the census bit vec is 8 bits long
                
                leftCenWnd(y, x, (j*24 + i*8 + 1):(j*24 + i*8 + 8)) = CenL;
                rightCenWnd(y, x, (j*24 + i*8 + 1):(j*24 + i*8 + 8)) = CenR;
            end
        end
    end
end

h = waitbar(0,'Computing disparity...');
set(h,'Name','Disparity progress');

[cenwnd_m, cenwnd_n, cenwnd_l] = size(leftCenWnd);

% CHANGE THIS TO SET THE CENSUS OFFSET AMOUNT
CENSUS_OFFSET = 0;

for d=0:(maxdisp)
    diss(:) = Inf;
    
    for y = 1:cenwnd_m
        for x = 1:cenwnd_n-(d+CENSUS_OFFSET)
            leftCenVec = leftCenWnd(y, x+d+CENSUS_OFFSET, :);
            rightCenVec = rightCenWnd(y, x, :);
            
            hammingVec = xor(leftCenVec, rightCenVec);
            hammingDist = sum(hammingVec);
            
            diss(y, x) = hammingDist;
        end
    end
    
    %img(:,:,d+1) = conv2(diss,corrSumKernel,'same');
    img(:,:,d+1) = diss;
    waitbar((d)/maxdisp);
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
  A = medfilt2(disparity_map);
  figure;imagesc(A);colormap(gray);axis image;
end