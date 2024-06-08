
%E:\Research\Experimental\Liq sheet\LS_EXP_POLYIMIDE\Liquid_sheet_polyimide\cal_version\videos\09_05_24_t127_w500_a40_Q50_S0001.mp4'
%F:\Liquid_sheet_polyimide\test\cropped1.png
% Load the reference image
referenceImage = imread('F:\Liquid_sheet_polyimide\test\cropped1.png');

% Convert to grayscale if necessary
if size(referenceImage, 3) == 3
    referenceImageGray = im2gray(referenceImage);
else
    referenceImageGray = referenceImage;
end

% Detect features in the reference image
referencePoints = detectSURFFeatures(referenceImageGray);
[referenceFeatures, referencePoints] = extractFeatures(referenceImageGray, referencePoints);

% Load the video
videoFile = 'E:\Research\Experimental\Liq sheet\LS_EXP_POLYIMIDE\Liquid_sheet_polyimide\cal_version\videos\09_05_24_t127_w500_a40_Q50_S0001.mp4';
videoReader = VideoReader(videoFile);

% Create a video player to display the results
videoPlayer = vision.VideoPlayer('Position', [100, 100, 680, 520]);

while hasFrame(videoReader)
    % Read the next frame
    videoFrame = readFrame(videoReader);
    
    % Convert to grayscale if necessary
    if size(videoFrame, 3) == 3
        videoFrameGray = im2gray(videoFrame);
    else
        videoFrameGray = videoFrame;
    end

    % Detect features in the video frame
    videoPoints = detectSURFFeatures(videoFrameGray);
    [videoFeatures, videoPoints] = extractFeatures(videoFrameGray, videoPoints);

    % Match features between the reference image and the video frame
    indexPairs = matchFeatures(referenceFeatures, videoFeatures);
    matchedReferencePoints = referencePoints(indexPairs(:, 1), :);
    matchedVideoPoints = videoPoints(indexPairs(:, 2), :);

    if size(matchedReferencePoints, 1) >= 4
        % Estimate the geometric transformation
        tform = estimateGeometricTransform2D(matchedReferencePoints, matchedVideoPoints, 'affine');

        % Transform the reference image polygon to the video frame
        [height, width, ~] = size(referenceImage);
        referencePolygon = [1, 1; width, 1; width, height; 1, height];
        newPolygon = transformPointsForward(tform, referencePolygon);

        % Display the video frame with the detected object
        videoFrame = insertShape(videoFrame, 'Polygon', newPolygon, 'LineWidth', 3);

         %Display matched points (optional)
         videoFrame = insertMarker(videoFrame, matchedVideoPoints.Location, '+', 'Color', 'white');
    end

    % Display the annotated video frame
    step(videoPlayer, videoFrame);
end

% Release the video player
release(videoPlayer);

