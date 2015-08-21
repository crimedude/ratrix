scsz = get( 0, 'Screensize' ); %get screensize for plots
%screensize = get( groot, 'Screensize' ); %get screensize for plots in R2014b and later

load mapOverlay

% %%%% tf tuning plots
% figure('Position', [scsz(3)/2 scsz(2)/2 scsz(3)/scscale scsz(4)/scscale]);
% subplot(2,4,1)
% plot(0,squeeze(allshiftData(1,1,1,conds)))
% title('X tuning','position',[0.5 0.5],'color','r','fontsize',20)
% axis([0 1 0 1])
% axis off
% legend(datafiles(conds),'location','south')
% for area = 1:7
%     subplot(2,4,area+1)
%     plot(squeeze(mean(mean(allshiftData(x(area)+range, y(area)+range, 1:3,conds),2),1)))
% %         plot(squeeze(allmnfit(x(area)+(-2:2),y(area),1:4,:).*squeeze((amp(x(i),y(i),:))%%% un-normalize it
%     title(sprintf(cell2mat(areanames(area))));
%     ylim([0 1])
% end

w = 2;
figure
%plot the average? response
imagesc(mean(shiftData(:,:,5,:),4));
hold on
plot(ypts,xpts,'w.','Markersize',2); axis off
for i = 1:7;
    plot([y(i)-w y(i)-w y(i)+w y(i)+w y(i)-w],[x(i)-w x(i)+w x(i)+w x(i)-w x(i)-w])
end
axis('square')
legend(areanames,'location','southeast')
hold off


%%%% sf tuning plots
figure('Position', [scsz(1) scsz(2) scsz(3)/scscale scsz(4)/scscale]);
subplot(2,4,1)
plot(0,squeeze(allmnfit(1,1,1,conds)))
title('SF tuning','position',[0.5 0.5],'color','r','fontsize',12)
axis([0 1 0 1])
axis off
legend(datafiles(conds),'location','south')
for area = 1:7
    subplot(2,4,area+1)
    plot(squeeze(mean(mean(allmnfit(x(area)+range, y(area)+range,6:7,conds),2),1)))
    title(sprintf(cell2mat(areanames(area))));
    axis([1 2 0 1])
end

   
%%%% y tuning plots
figure('Position', [scsz(3)/2 scsz(2)/2 scsz(3)/scscale scsz(4)/scscale]);
subplot(2,4,1)
plot(0,squeeze(allmnfit(1,1,1,conds)))
title('Y tuning','position',[0.5 0.5],'color','r','fontsize',12)
axis([0 1 0 1])
axis off
legend(datafiles(conds),'location','south')
for area = 1:7
    subplot(2,4,area+1)
    plot(squeeze(mean(mean(allmnfit(x(area)+range, y(area)+range,4:5,conds),2),1)))
    title(sprintf(cell2mat(areanames(area))));
    axis([1 2 0 1])
end

%%%% x tuning plots
figure('Position', [scsz(1) scsz(2) scsz(3)/scscale scsz(4)/scscale]);
subplot(2,4,1)
plot(0,squeeze(allmnfit(1,1,1,conds)))
title('X tuning','position',[0.5 0.5],'color','r','fontsize',12)
axis([0 1 0 1])
axis off
legend(datafiles(conds),'location','south')
for area = 1:7
    subplot(2,4,area+1)
    plot(squeeze(mean(mean(allmnfit(x(area)+range, y(area)+range,1:3,conds),2),1)))
    title(sprintf(cell2mat(areanames(area))));
    axis([1 3 0 max(max(max(allmnfit(:,:,1:3))))])
end

%circleshifted cycle average
figure('Position', [scsz(3)/4 scsz(4)/2-scsz(4)/10 scsz(3)/scscale scsz(4)/scscale]);%displays at top of screen
subplot(2,4,1)
plot(0,squeeze(allmnfit(1,1,1,conds)))
title('CycAvg','position',[0.5 0.5],'color','r','fontsize',12)
axis([0 1 0 1])
axis off
legend(datafiles(conds),'location','south')
for area = 1:7
    subplot(2,4,area+1)
    d=squeeze(mean(mean(allcycavg(x(area)+range,y(area)+range,:,conds),2),1))';
    for i = 1:length(conds)
        d(i,:) = (d(i,:) - min(d(i,:)))/(max(d(i,:))-min(d(i,:)));
    end
    plot(0.1:0.1:(0.1*length(d)),circshift(d',10));
    title(sprintf(cell2mat(areanames(area))));
    axis([0.1 2.5 0 1])
end


%%%% deconvolved circleshifted cycle averages
figure('Position', [scsz(3)/4 scsz(4)/2-scsz(4)/10 scsz(3)/scscale scsz(4)/scscale]);%displays at top of screen
subplot(2,4,1)
plot(0,squeeze(allmnfit(1,1,1,conds)))
title('Decon CycAvg','position',[0.5 0.5],'color','r','fontsize',12)
axis([0 1 0 1])
axis off
legend(datafiles(conds),'location','south')
for area = 1:7
    subplot(2,4,area+1)
    d=squeeze(mean(mean(allcycavg(x(area)+range,y(area)+range,:,conds),2),1));
    repd = repmat(d,[10 1]);
    dconvd = deconvg6s(repd'+0.5,0.1);
    d = dconvd(:,(ceil(length(dconvd)/2)):((ceil(length(dconvd)/2))+ceil(length(dconvd)/10)));
    for i = 1:length(conds)
        d(i,:) = (d(i,:) - min(d(i,:)))/(max(d(i,:))-min(d(i,:)));
    end
    plot(0.1:0.1:(0.1*length(d)),circshift(d',10));
    title(sprintf(cell2mat(areanames(area))));    
    axis([0.1 2.5 0 1])
end

% %%%% cycle averages
% figure('Position', [scsz(3)/4 scsz(4)/2-scsz(4)/10 scsz(3)/scscale scsz(4)/scscale]);%displays at top of screen
% subplot(2,4,1)
% plot(0,squeeze(allmnfit(1,1,1,conds)))
% title('CycAvg','position',[0.5 0.5],'color','r','fontsize',12)
% axis([0 1 0 1])
% axis off
% legend(datafiles(conds),'location','south')
% for area = 1:7
%     subplot(2,4,area+1)
%     d = squeeze(mean(mean(allcycavg(x(area)+range, y(area)+range,:,conds),2),1))';
%     for i = 1:length(conds) %this normalization can be done more efficiently, figure out how please
%         d(i,:) = (d(i,:) - min(d(i,:)))/(max(d(i,:))-min(d(i,:)));
%     end   
%     plot(d')
% %     plot(circshift(d',10))
%     title(sprintf(cell2mat(areanames(area))));
%     axis([1 25 0 1])
% end


% deconvolved cycle average
% figure('Position', [scsz(3)/4 scsz(4)/2-scsz(4)/10 scsz(3)/scscale scsz(4)/scscale]);%displays at top of screen
% subplot(2,4,1)
% plot(0,squeeze(allmnfit(1,1,1,conds)))
% title('Decon Shift CycAvg','position',[0.5 0.5],'color','r','fontsize',12)
% axis([0 1 0 1])
% axis off
% legend(datafiles(conds),'location','south')
% for area = 1:7
%     subplot(2,4,area+1)
%     d=squeeze(mean(mean(allcycavg(x(area)+range,y(area)+range,:,conds),2),1));
%     repd = repmat(d,[10 1]);
%     dconvd = deconvg6s(repd'+0.5,0.1);
%     d = dconvd(:,31:45);
%     for i = 1:length(conds)
%         d(i,:) = (d(i,:) - min(d(i,:)))/(max(d(i,:))-min(d(i,:)));
%     end
%     plot(d')
%     axis([0.1 1.5 0 1])
% end
% 


%%%        
%figures for PDF

w = 2;
figure('visible','off');
imagesc(mean(shiftData(:,:,5,:),4));
hold on
plot(ypts,xpts,'w.','Markersize',2); axis off
for i = 1:7;
    plot([y(i)-w y(i)-w y(i)+w y(i)+w y(i)-w],[x(i)-w x(i)+w x(i)+w x(i)-w x(i)-w])
end
legend(areanames,'location','southeast')
axis('square')
legend(areanames,'location','southeast')
hold off
print('-dpsc',psfilename,'-append');

%%%% x tuning plots
figure('visible','off');
subplot(2,4,1)
plot(0,squeeze(allmnfit(1,1,1,conds)))
title('X tuning','position',[0.5 0.5],'color','r','fontsize',12)
axis([0 1 0 1])
axis off
legend(datafiles(conds),'location','south')
for area = 1:7
    subplot(2,4,area+1)
    plot(squeeze(mean(mean(allmnfit(x(area)+range, y(area)+range,1:3,conds),2),1)))
    title(sprintf(cell2mat(areanames(area))));
    axis([1 3 0 max(max(max(allmnfit(:,:,1:3))))])
end
print('-dpsc',psfilename,'-append');
   
%%%% y tuning plots
figure('visible','off');
subplot(2,4,1)
plot(0,squeeze(allmnfit(1,1,1,conds)))
title('Y tuning','position',[0.5 0.5],'color','r','fontsize',12)
axis([0 1 0 1])
axis off
legend(datafiles(conds),'location','south')
for area = 1:7
    subplot(2,4,area+1)
    plot(squeeze(mean(mean(allmnfit(x(area)+range, y(area)+range,4:5,conds),2),1)))
    title(sprintf(cell2mat(areanames(area))));
    axis([1 2 0 1])
end
print('-dpsc',psfilename,'-append');

%%%% sf tuning plots
figure('visible','off');
subplot(2,4,1)
plot(0,squeeze(allmnfit(1,1,1,conds)))
title('SF tuning','position',[0.5 0.5],'color','r','fontsize',12)
axis([0 1 0 1])
axis off
legend(datafiles(conds),'location','south')
for area = 1:7
    subplot(2,4,area+1)
    plot(squeeze(mean(mean(allmnfit(x(area)+range, y(area)+range,6:7,conds),2),1)))
    title(sprintf(cell2mat(areanames(area))));
    axis([1 2 0 1])
end
print('-dpsc',psfilename,'-append');

%circleshifted cycle average
figure('visible','off');
subplot(2,4,1)
plot(0,squeeze(allmnfit(1,1,1,conds)))
title('CycAvg','position',[0.5 0.5],'color','r','fontsize',12)
axis([0 1 0 1])
axis off
legend(datafiles(conds),'location','south')
for area = 1:7
    subplot(2,4,area+1)
    d=squeeze(mean(mean(allcycavg(x(area)+range,y(area)+range,:,conds),2),1))';
    for i = 1:length(conds)
        d(i,:) = (d(i,:) - min(d(i,:)))/(max(d(i,:))-min(d(i,:)));
    end
    plot(0.1:0.1:2.5,circshift(d',10));
    title(sprintf(cell2mat(areanames(area))));
    axis([0.1 2.5 0 1])
end
print('-dpsc',psfilename,'-append');

%%%% deconvolved cycle averages
figure('visible','off');
subplot(2,4,1)
plot(0,squeeze(allmnfit(1,1,1,conds)))
title('Decon CycAvg','position',[0.5 0.5],'color','r','fontsize',12)
axis([0 1 0 1])
axis off
legend(datafiles(conds),'location','south')
for area = 1:7
    subplot(2,4,area+1)
    d=squeeze(mean(mean(allcycavg(x(area)+range,y(area)+range,:,conds),2),1));
    repd = repmat(d,[10 1]);
    dconvd = deconvg6s(repd'+0.5,0.1);
    d = dconvd(:,(ceil(length(dconvd)/2)):((ceil(length(dconvd)/2))+ceil(length(dconvd)/10)));
    for i = 1:length(conds)
        d(i,:) = (d(i,:) - min(d(i,:)))/(max(d(i,:))-min(d(i,:)));
    end
    plot(0.1:0.1:(0.1*length(d)),circshift(d',10));
    title(sprintf(cell2mat(areanames(area))));    
    axis([0.1 2.5 0 1])
end
print('-dpsc',psfilename,'-append');


%         amp(:,:,i) = max(allmnfit(:,:,1:4,:),[],3); 
%         plot(squeeze(allmnfit(x(area)+(-2:2),y(area),1:4,:).*squeeze((amp(x(i),y(i),:))
%         %un-normalizes data via x tuning