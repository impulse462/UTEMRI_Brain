function ute_dicom(finalImage, pfile_name, output_image, image_option, scaleFactor, seriesNumberOffset)
% Convert matlab 3D matrix to dicom for UTE sequences
% resolution is fixed in the recon - FOV/readout(from scanner), isotropic
% matrix size is determined in the recon
% Inputs:
%   finalImage: 3D image matrix
%   pfile_name: original pfile name
%   output_image: output directory
%   image_option: 1 for both phase and magnitude, 0(offset) mag only
%   scaleFactor: scale image matrix
%   seriesNumber: output series number
%
% August, 2018, Xucheng Zhu, Nikhil Deveshwar


if nargin<4
    image_option = 0;
end
addpath(genpath('../util'));


addpath(genpath('../orchestra-sdk-1.7-1.matlab'));
Isize = size(finalImage);

pfile = GERecon('Pfile.Load', pfile_name);
pfile.header = GERecon('Pfile.Header', pfile);
pfile.phases = numel(finalImage(1,1,1,1,:)); 
pfile.xRes = size(finalImage,1);
pfile.yRes = size(finalImage,2);
pfile.slices = size(finalImage,3);
pfile.echoes = size(finalImage,4);

% calc real res(isotropic,axial)
corners = GERecon('Pfile.Corners', 1);
orientation = GERecon('Pfile.Orientation', 1);
outCorners = GERecon('Orient', corners, orientation);
% res = abs(outCorners.UpperRight(2)-outCorners.UpperLeft(2))/Isize(3);
res2 = 2;
scale = Isize/Isize(3);
scale2 = [1, 1e-6, 1];
corners.LowerLeft = corners.LowerLeft.*scale2;
corners.UpperLeft = corners.UpperLeft.*scale2;
corners.UpperRight = corners.UpperRight.*scale2;
info = GERecon('Pfile.Info', 1);


%     % NEED TO CONFIRM orientation/corners based on slice number
%     % HERE IS HOW this is done without the "corners" adjustment shown
%     % above:
%                      sliceInfo.pass = 1;
%                     sliceInfo.sliceInPass = s;
%            info = GERecon('Pfile.Info', 1);
%        orientation = info.Orientation;  corners = info.Corners;


%  X = repmat(int16(0), [96 86 1 94]);
X = zeros(96, 86, 1, 94);


seriesDescription = ['UTE T2 - ', output_image];
seriesNumber = pfile.header.SeriesData.se_no * 100 + seriesNumberOffset;


for s = flip(1:pfile.slices)
    
    
    for e = 1:pfile.echoes
        for p = 1:pfile.phases
            
             mag_t =flip(double(finalImage(:,:,s,e,p) * scaleFactor));
%             figure;imshow(mag_t);title('mag_t');

%             mag_t2 = GERecon('Orient', mag_t, orientation);
            

            imageNumber = ImageNumber(s, e, p, pfile);
            filename = ['DICOMs_' output_image, '/image_',num2str(imageNumber) '.dcm'];
            GERecon('Dicom.Write', filename, mag_t, imageNumber, orientation, corners, seriesNumber, seriesDescription);
    
            if image_option~=0
                phase_t = flip(flip(single(angle(finalImage(:,:,s,e,p))).',1),2);
                %phase_t = GERecon('Orient', phase_t, orientation);
                filename = [output_dir,'DICOMS/phase_',num2str(imageNumber) '.dcm'];
                GERecon('Dicom.Write', filename, phase_t, imageNumber, orientation, corners);
            end
            
            [X(:,:,1,s),map] = dicomread(filename);
        end
    end
    
    % sliceInfo.pass = 1
    % sliceInfo.sliceInPass = s
    % info = GERecon('Pfile.Info', 1)
    
    % Get corners and orientation for next slice location?
    corners.LowerLeft(3) = corners.LowerLeft(3) + res2;
    corners.UpperLeft(3) = corners.UpperLeft(3) + res2;
    corners.UpperRight(3) = corners.UpperRight(3) + res2;
     
    % Check header settings in Horos to ensure pixel spacing value is
    % correct relative to slice thickness
       
end

disp([output_image, ' generated.']);

% figure;montage(X(:,:,1,:),map);title(output_image);

end
               

function number = ImageNumber(slice, echo, phase, pfile)
% Image numbering scheme:
% P0S0E0, P0S0E1, ... P0S0En, P0S1E0, P0S1E1, ... P0S1En, ... P0SnEn, ...
% P1S0E0, P1S0E1, ... PnSnEn
    slicesPerPhase = pfile.slices * pfile.echoes;
    number = (phase-1) * slicesPerPhase + (slice-1) * pfile.echoes + (echo-1) + 1;
end
