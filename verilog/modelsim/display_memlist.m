% Change filename here. Also change x_dim, y_dim.
mem_name = 'out.list';
fid = fopen(mem_name,'r');

row_sz = 450;
col_sz = 375;

% Instantiate matrix
img_mat = zeros(col_sz,row_sz,'uint8');

% Read file into matrix
early_end_flag = 0;

for i = 1:col_sz
    for j = 1:row_sz
        str = fgetl(fid);
        
        if str == -1
            early_end_flag = 1;
            break
        end
        
        found = size(findstr('x', str));
        if found(1,1) == 0
            val = hex2dec(str);
        else
            val = 0;
        end
        
        img_mat(i,j) = val;
    end
    
    if early_end_flag == 1
        break
    end
end 

fclose(fid);

% Display image
figure;
imagesc(img_mat);
%colormap('gray');
colorbar();

% Post processing
img_filt = medfilt2(img_mat, [3 3]);
figure;
imagesc(img_filt);
%colormap('gray');
colorbar();