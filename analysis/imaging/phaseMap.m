function [map cycmap full_im]= phaseMap(im,t,period,binning);
if ~exist('binning','var') | isempty(binning)
    binning=1;
end
perFrames = round(period/median(diff(t)))
map =0;

length(im)
nframes = floor(length(im)/perFrames)*perFrames
cycmap = zeros(ceil(size(im,1)*binning),ceil(size(im,2)*binning),perFrames);
if binning~=1
    full_im = zeros(ceil(size(im,1)*binning),ceil(size(im,2)*binning),size(im,3));
end

for f = 1:nframes
   if binning~=1;
       imframe = imresize(im(:,:,f),binning,'box');
   full_im(:,:,f) = imframe;
   else
       imframe = im(:,:,f);
   end
       map = map+imframe*exp(2*pi*sqrt(-1)*f/perFrames);
       cycmap(:,:,mod(f,perFrames)+1)=cycmap(:,:,mod(f,perFrames)+1)+imframe;
       
end
map = map/length(im);
cycmap = cycmap/(nframes/perFrames);

