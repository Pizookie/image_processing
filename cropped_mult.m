% Read the main image (image containing the object to be detected)
%% cleaning
clc;
close all;
clear;

%% feed samples
fileNumbers = 1:5;

%% initializing cells to store values
num_mainImage = length(fileNumbers);
mainImage = cell(1, num_mainImage);
name_main_filename = cell(1, num_mainImage);

%% providing the pictures for processing (main pictures)
main_baseDir = 'F:\WAFERS\Wafer 1\2024_05_13\250_40\q20_F_S1';

%% calling all the files for main images
for i = 1:num_mainImage
    numberStr = num2str(fileNumbers(i), '%04d'); % Zero-pad the number to 4 digits
    main_filename = ['q20_F_S100', numberStr, '.tif'];
    name_main_filename{i} = main_filename;
    mainImage{i} = imread(fullfile(main_baseDir, main_filename));
end

%% Folder with template images
baseDir = 'F:\Liquid_sheet_polyimide\test\';
number = 1:5;
numTemplates = length(number);
templateImages = cell(1, numTemplates);
name_template_filename = cell(1, numTemplates);

%% Loading template images
for i = 1:numTemplates
    filename = ['cropped_image_sample', num2str(number(i)), '.tif'];
    name_template_filename{i} = filename;
    templateImages{i} = imread(fullfile(baseDir, filename));
end

%% GRAY SCALE convert main images
mainImageGray = cell(1, num_mainImage);
for i = 1:num_mainImage
    if size(mainImage{i}, 3) == 3
        mainImageGray{i} = rgb2gray(mainImage{i});
    else
        mainImageGray{i} = mainImage{i};
    end
end

%% variables to store the best match for each main image
croppedImages = cell(1, num_mainImage);  % cell array to store best cropped images for each main image
% adjust image after binary conversion
adjusted_images=cell(1, num_mainImage);
bwd_all=cell(1,num_mainImage);
outputDir = 'F:\Liquid_sheet_polyimide\cropped_images\';
adjusted_Dir='F:\Liquid_sheet_polyimide\adjusted\';
plot_Dir='F:\Liquid_sheet_polyimide\contour\';
avg_imageDir='F:\Liquid_sheet_polyimide\avg_image\';
avg_cropped_imageDir='F:\Liquid_sheet_polyimide\avg_cropped_img\';
LS_cont_store=cell(1,num_mainImage);
all_plot=cell(1,num_mainImage);
%% Template matching using normalized cross-correlation for each main image
for m = 1:num_mainImage
    bestMatchValue = -inf;
    bestTemplateIndex = -1;
    bestBoundingBox = [];
    
    for t = 1:numTemplates
        % Convert the template image to grayscale if it is not already
        templateImage = templateImages{t};
        if size(templateImage, 3) == 3
            templateImageGray = rgb2gray(templateImage);
        else
            templateImageGray = templateImage;
        end
        
        correlationOutput = normxcorr2(templateImageGray, mainImageGray{m});
        
        %  the peak correlation value and its location
        [maxCorrValue, maxIndex] = max(correlationOutput(:));
        [yPeak, xPeak] = ind2sub(size(correlationOutput), maxIndex);
        
        % getting the best match if the current correlation value is higher
        if maxCorrValue > bestMatchValue
            bestMatchValue = maxCorrValue;
            bestTemplateIndex = t;
            bestBoundingBox = [xPeak - size(templateImageGray, 2) + 1, yPeak - size(templateImageGray, 1) + 1, size(templateImageGray, 2), size(templateImageGray, 1)];
        end
    end
    
    % showing the the main image with the detected bounding box
    figure;
    imshow(mainImage{m});
    hold on;
    rectangle('Position', bestBoundingBox, 'EdgeColor', 'g', 'LineWidth', 3);
    text(bestBoundingBox(1), bestBoundingBox(2) - 10, ['Detected Template Image: ', num2str(bestTemplateIndex)], 'Color', 'red', 'FontSize', 10, 'FontWeight', 'bold');
    hold off;

    % cropping the detected image
    croppedImage = imcrop(mainImage{m}, bestBoundingBox);
    cropped_filename = ['feed_image_', num2str(m), '.tif'];
    % Storing the best cropped image in the cell array
    croppedImages{m} = croppedImage;

    % display the cropped image
    figure;
    imshow(croppedImage);
    title(['Cropped Image of Detected Object (Main Image: ', num2str(m), ', Template: ', num2str(bestTemplateIndex), ')']);
    imwrite(croppedImage, fullfile(outputDir, cropped_filename));

    %% converting to binary 
adjusted_image          = imadjust(croppedImage);                                      % Adjust the grayscale intensity values
adjusted_images{m}=adjusted_image;
adjusted_filename = ['adjusted_image_', num2str(m), '.tif'];
imwrite(adjusted_image, fullfile(adjusted_Dir, adjusted_filename));

bwd                 = imdilate(adjusted_image,strel('disk',1));                      % Dilate and emphasize the white elements of the image
bwd                 = imbinarize(bwd,0.28);                                % Binarize the image
bwd                 = imfill(bwd,'holes');                                 % Fill the holes to create closed loops
bwd_all{m}=bwd;

%% contour

LSContour           = bwboundaries(bwd);
LS_cont_store{m}=LSContour;
cellLengths         = cellfun(@numel, LSContour);       
% the length of each cell element
[~, maxIndex]       = max(cellLengths);                                    % Find the index of the cell with the largest length

c1 = LSContour{maxIndex}; X = c1(:,2); Y = c1(:,1);

windowWidth         = 15;
polynomialOrder     = 4;
smoothX             = sgolayfilt(X,polynomialOrder,windowWidth);
smoothY             = sgolayfilt(Y,polynomialOrder,windowWidth);
shading flat
colormap(gray)
axis image

hold on
a=plot(smoothX,smoothY,'g-','LineWidth',2);
all_plot{m}=a;
plot_filename = ['contour_image_', num2str(m), '.tif'];
saveas(gcf,fullfile(plot_Dir,plot_filename));

    % Display the best match results for the current main image
    disp(['Main Image ', num2str(m), ':']);
    disp(['  Best match value: ', num2str(bestMatchValue)]);
    disp(['  Best template index: ', num2str(bestTemplateIndex)]);
    disp(['  Best bounding box: ', num2str(bestBoundingBox)]);
end
%% all the images to get a single image
avg_image = zeros(size(mainImage{1}));
for i = 1:num_mainImage
    avg_image = avg_image + double(mainImage{i});
end
avg_image = avg_image / num_mainImage;

% displaying the average image
figure;
imshow(uint8(avg_image));
title('Average Image');
avg_image_filename = ['average_image_', num2str(m), '.tif'];
saveas(gcf,fullfile(avg_imageDir,avg_image_filename));
imwrite(uint8(avg_image), 'F:\Liquid_sheet_polyimide\average_image.tif');
%% all the cropped images as an average image
avg_cropped_image = zeros(size(croppedImage(1)));
for i = 1:num_mainImage
    avg_cropped_image = avg_cropped_image + double(croppedImage(i));
end
avg_cropped_image = avg_cropped_image / num_mainImage;

% display the average image
figure;
imshow(uint8(avg_cropped_image));
title('Average ROI Image');
avg_cropped_image_filename = ['average_cropped_image_', num2str(m), '.tif'];
saveas(gcf,fullfile(avg_cropped_imageDir,avg_cropped_image_filename));
imwrite(uint8(avg_cropped_image), 'F:\Liquid_sheet_polyimide\average_image.tif');
imwrite(uint8(avg_cropped_image), 'F:\Liquid_sheet_polyimide\average_cropped_image.tif');