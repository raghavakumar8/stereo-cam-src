% Change filename here.
img_name = 'c.jpg';

input_img = imread(strcat('test_images\',img_name));
input_img = input_img(:,:,1);

fid = fopen(strcat(strtok(img_name,'.'),'.list'),'w');

% Loop over pixels and write to file
for i = 1:240
    for j = 1:320
        val = dec2hex(input_img(i,j),2);
        fprintf(fid, strcat(val, '\n')); 
    end
end

fclose(fid);

        