function disparity_map = correlation_match2(left, right, maxdisp)
%disparity_map = correlation_match2(left, right, maxdisp): given a pair of stereo
%images and maximum disparity, calculates both the left-to-right and
%right-to-left disparity maps, collates info from them, does left-right
%consistency check and returns the final result
%
% left    : the left image in the stereo pair
% right   : the right image in the stereo pair
% maxdisp : maximum disparity accepted
%
% disparity_map: disparity map- image of the same size as input image

% find left-to-right and right-to-left disparity maps
leftToRightDisp = correlation_match(left,right,maxdisp,0);
rightToLeftDisp = correlation_match(left,right,maxdisp,1);

% compare them
% find the pixels in the rightToLeftDisp corresponding to those in leftToRightDisp
[m n] = size(leftToRightDisp);

rInds = (1:m*n)' - leftToRightDisp(:);

%see if the value from one is the negative of the other
x = leftToRightDisp(:) - rightToLeftDisp(rInds);
okInds = find(abs(x) < 20);



final = zeros(m,n);
final(okInds) =  leftToRightDisp (okInds);

figure;imagesc(leftToRightDisp);colormap(gray);axis image;