% Change filename here.
img_name = 'b.jpg';

input_img = imread(strcat('test_images\',img_name));
input_img = input_img(:,:,1);

size(input_img)

% Instantiate output image
output_img = zeros(size(input_img),'uint8');

% Go through image pixel by pixel, calculating output
for i = 1:240
    for j = 1:320
        % 8 point sparse census
        im1 = (i <= 1)*(239) + (i > 1)*(i-1);
        im2 = (i <= 2)*(i+238) + (i > 2)*(i-2);
        ip1 = (i >= 240)*(1) + (i < 240)*(i+1);
        ip2 = (i >= 239)*(i-238) + (i < 239)*(i+2);
        
        jm1 = (j <= 1)*(319) + (j > 1)*(j-1);
        jm2 = (j <= 2)*(j+318) + (j > 2)*(j-2);
        jp1 = (j >= 320)*(1) + (j < 320)*(j+1);
        jp2 = (j >= 319)*(j-318) + (j < 319)*(j+2);
        
        output_img(i,j) = 0;
        
        if input_img(im2,jm2) < input_img(i,j)
            output_img(i,j) = output_img(i,j) + 1;
        end
        if input_img(i,jm2) < input_img(i,j)
            output_img(i,j) = output_img(i,j) + 2;
        end
        if input_img(ip2,jm2) < input_img(i,j)
            output_img(i,j) = output_img(i,j) + 4;
        end
        if input_img(im2,j) < input_img(i,j)
            output_img(i,j) = output_img(i,j) + 8;
        end
        if input_img(ip2,j) < input_img(i,j)
            output_img(i,j) = output_img(i,j) + 16;
        end
        if input_img(im2,jp2) < input_img(i,j)
            output_img(i,j) = output_img(i,j) + 32;
        end
        if input_img(i,jp2) < input_img(i,j)
            output_img(i,j) = output_img(i,j) + 64;
        end
        if input_img(ip2,jp2) < input_img(i,j)
            output_img(i,j) = output_img(i,j) + 128;
        end
    end
end

% Display image
figure;
imagesc(output_img);
colormap('gray');
colorbar();