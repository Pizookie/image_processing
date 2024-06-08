% Clean workspace
clc;
clear;
close all;
%% images for averaging
imageDir = 'F:\WAFERS\Wafer 1\2024_05_13\250_40\q20_F_S1';
backgroundDir='F:\WAFERS\Wafer 1\2024_05_13\250_40\q20_F_CAL_S1';
% Image file numbers
fileNumbers = 1:1000;
fileNumber_BGI=1:100;
% Initialize a cell array to hold the images
numImages = length(fileNumbers);
numBGI=length(fileNumber_BGI);
images = cell(1, numImages);
backgroundImg=cell(1,numBGI);
% Load the images
for i = 1:numImages
    numberStr = num2str(fileNumbers(i), '%04d'); % Zero-pad the number to 4 digits
    filename = ['q20_F_S100', numberStr, '.tif'];
    images{i} = imread(fullfile(imageDir, filename));
    
    % Check if the image is loaded correctly
    if isempty(images{i})
        error(['Image ', filename, ' could not be loaded.']);
    end
    
    % Convert images to grayscale if they are RGB
    if size(images{i}, 3) == 3
        images{i} = rgb2gray(images{i});
    end
end

% Check if all images are of the same size
imageSize = size(images{1});
for i = 2:numImages
    if ~isequal(size(images{i}), imageSize)
        error('Not all images are of the same size.');
    end
end

% Initialize the average image matrix
avgImage = zeros(imageSize, 'double');
%% performing average on all images
% sum images
for i = 1:numImages
    avgImage = avgImage + double(images{i});
end

% divide for the average image
avgImage = avgImage / numImages;


avgImage = uint8(255 * mat2gray(avgImage));

% Display average image
figure;
imshow(avgImage);
title('Average Image');
set(gcf, 'Position', get(0, 'Screensize')); % Maximize the figure window

% saaving  the average image
outputDir = 'F:\Liquid_sheet_polyimide\avg_image\';
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end
avgImageFilename = fullfile(outputDir, 'average_image.tif');
imwrite(avgImage, avgImageFilename);
%% for background images
for i = 1:numBGI
    numberStr_bg = num2str(fileNumbers(i), '%03d'); % Zero-pad the number to 4 digits
    filename_BGI = ['q20_F_CAL_S1000', numberStr_bg, '.tif'];
    backgroundImg{i} = imread(fullfile(backgroundDir, filename_BGI));
    
    % Check if the image is loaded correctly
    if isempty(backgroundImg{i})
        error(['Image ', filename_BGI, ' could not be loaded.']);
    end
    
    % Convert images to grayscale if they are RGB
    if size(backgroundImg{i}, 3) == 3
        backgroundImg{i} = rgb2gray(backgroundImg{i});
    end
end


% Check if all images are of the same size
BGI_imageSize = size(backgroundImg{1});
for i = 2:numBGI
    if ~isequal(size(backgroundImg{i}), BGI_imageSize)
        error('Not all background images are of the same size.');
    end
end

% Initialize the average image matrix
avg_BGI_Image = zeros(BGI_imageSize, 'double');

for i = 1:numBGI
    avg_BGI_Image = avg_BGI_Image + double(backgroundImg{i});
end

% divide for the average image
avg_BGI_Image = avg_BGI_Image / numBGI;


avg_BGI_Image = uint8(255 * mat2gray(avg_BGI_Image));

% Display average image
figure;
imshow(avg_BGI_Image);
title('Average background Image');
set(gcf, 'Position', get(0, 'Screensize')); % Maximize the figure window

% saaving  the average image
outputDir_BGI = 'F:\Liquid_sheet_polyimide\avg_BGI\';
if ~exist(outputDir_BGI, 'dir')
    mkdir(outputDir_BGI);
end
avg_BGI_ImageFilename = fullfile(outputDir_BGI, 'average_BG_image.tif');
imwrite(avg_BGI_Image, avg_BGI_ImageFilename);

