% Change filename here.
mem_name = 'out.list';
fid = fopen(mem_name,'r');

% Instantiate matrix
img_mat = zeros(240,320,'uint8');

% Read file into matrix
for i = 1:240
    for j = 1:320
        str = fgetl(fid);
        found = size(findstr('x', str));
        if found(1,1) == 0
            val = hex2dec(str);
        else
            val = 0;
        end
        img_mat(i,j) = val;
    end
end 

fclose(fid);

% Display image
figure;
imagesc(img_mat);
colormap('gray');
colorbar();