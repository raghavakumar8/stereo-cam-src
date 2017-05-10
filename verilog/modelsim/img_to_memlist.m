% Change filename here.
img_name = 'cones_r.png';

input_img = imread(strcat('test_images\',img_name));
input_img = input_img(:,:,1);

sz = size(input_img);
sz_x = sz(1,1);
sz_y = sz(1,2);

fprintf('Image size: %d x %d \n', sz_y, sz_x);

fid = fopen(strcat(strtok(img_name,'.'),'.list'),'w');

% Loop over pixels and write to file
for i = 1:sz_x
    for j = 1:sz_y
        val = dec2hex(input_img(i,j),2);
        fprintf(fid, strcat(val, '\n')); 
    end
end

fclose(fid);

        