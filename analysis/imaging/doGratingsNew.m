%%%% doGratings
x=0;
for rep=[3] %%% 1 = background gratings, 2 = 3x2y patches; 3 = simple behavior passive; 4 = 4x3y patches
    mnAmp{rep}=0; mnPhase{rep}=0; mnAmpWeight{rep}=0; mnData{rep}=0; mnFit{rep}=0;
    clear shiftData shiftAmp shiftPhase fit cycavg
    
    for f = 1:length(use)
        figure
        set(gcf,'Name',[files(use(f)).subj ' ' files(use(f)).expt])
        
        
        for i = 1:4  %%%% load in topos for check
            if i==1
                load([pathname files(use(f)).topox],'map');
            elseif i==2
                load([pathname files(use(f)).topoy],'map');
            elseif i==3 && length(files(use(f)).topoyland)>0
                load([pathname files(use(f)).topoyland],'map');
            elseif i==4 &&length(files(use(f)).topoxland)>0
                load([pathname files(use(f)).topoxland],'map');
            end
            subplot(2,2,i);
            imshow(polarMap(shiftImageRotate(map{3},allxshift(f)+x0,allyshift(f)+y0,allthetashift(f),allzoom(f),sz),90));
            hold on; plot(ypts,xpts,'w.','Markersize',2)
            set(gca,'LooseInset',get(gca,'TightInset'))
        end
        
        
        
        
        if rep ==1
         load ([pathname files(use(f)).background3x2yBlank ], 'dfof_bg','sp','stimRec')
            zoom = 260/size(dfof_bg,1);
            if ~exist('sp','var')
                sp =0;stimRec=[];
            end
            dfof_bg = shiftImageRotate(dfof_bg,allxshift(f)+x0,allyshift(f)+y0,allthetashift(f),zoom,sz);
            [ph amp data ft cyc] = analyzeGratingPatch(imresize(dfof_bg,0.25),sp,...
                'C:\background3x2y2sf_021215_16minBlank',18:22,16,xpts/4, ypts/4, [files(use(f)).subj ' ' files(use(f)).expt],stimRec);
        elseif rep==2
            load ([pathname files(use(f)).grating3x2y6sf4tf ], 'dfof_bg','sp','stimRec')
            zoom = 260/size(dfof_bg,1);
            if ~exist('sp','var')
                sp =0;stimRec=[];
            end
            dfof_bg = shiftImageRotate(dfof_bg,allxshift(f)+x0,allyshift(f)+y0,allthetashift(f),zoom,sz);
            [ph amp data ft cyc] = analyzeGratingPatch(imresize(dfof_bg,0.25),sp,...
                'C:\grating3x2y6sf4tf_021215_20min',21:25,14:16,xpts/4, ypts/4, [files(use(f)).subj ' ' files(use(f)).expt],stimRec);
        elseif rep==3
            load ([pathname files(use(f)).behavGratings ], 'dfof_bg','sp','stimRec')
            zoom = 260/size(dfof_bg,1);
            if ~exist('sp','var')
                sp =0;stimRec=[];
            end
            dfof_bg = shiftImageRotate(dfof_bg,allxshift(f)+x0,allyshift(f)+y0,allthetashift(f),zoom,sz);
            [ph amp data ft cyc] = analyzeGratingPatch(imresize(dfof_bg,0.25),sp,...
                'C:\behavStim2sfSmall3366',24:26,18:20,xpts/4, ypts/4, [files(use(f)).subj ' ' files(use(f)).expt],stimRec);
      
        
        
        elseif rep ==4
            load ([pathname files(use(f)).grating4x3y6sf3tf], 'dfof_bg','sp','stimRec')
            zoom = 260/size(dfof_bg,1);
            if ~exist('sp','var')
                sp =0;stimRec=[];
            end
            dfof_bg = shiftImageRotate(dfof_bg,allxshift(f)+x0,allyshift(f)+y0,allthetashift(f),zoom,sz);
            [ph amp data ft cyc] = analyzeGratingPatch(imresize(dfof_bg,0.25),sp,...
                'C:\grating4x3y5sf3tf_short011315.mat',13:16,8:9,xpts/4, ypts/4, [files(use(f)).subj ' ' files(use(f)).expt],stimRec);
        end
        sp = conv(sp,ones(50,1),'same')/50;;
        sp_all(:,f) = sp;
        mv(f) = sum(sp>500)/length(sp);
      if rep~=3
          shiftData(:,:,:,f) = imresize(data,4);
        shiftAmp(:,:,:,f) = imresize(amp,4);
        shiftPhase(:,:,:,f) = imresize(ph,4);
        fit(:,:,:,f) = imresize(ft,4);
        cycavg(:,:,:,f) = imresize(cyc,4);
        
        
        shiftData(isnan(shiftData))=0;
        
        % plotGratingResp(shiftPhase,shiftAmp,rep,xpts,ypts)
        plotGratingRespFit(squeeze(shiftData(:,:,:,f)),squeeze(shiftData(:,:,5,f)+shiftData(:,:,6,f)),squeeze(fit(:,:,:,f)),rep,xpts,ypts,[files(use(f)).subj ' ' files(use(f)).expt])
      end
      
        
    end
    figure
    plot(sp_all);
    figure
    bar(mv);
    % plotGratingResp(mnPhase{rep}/length(use),mnAmp{rep}/length(use),rep,xpts,ypts);
    %plotGratingResp(mnAmpWeight{rep}./(mnAmp{rep}+0.0001),mnAmp{rep}/length(use),rep,xpts,ypts);
    plotGratingRespFit(mean(shiftData,4),mean(shiftData(:,:,5,:) + shiftData(:,:,6,:),4),mean(fit,4),rep,xpts,ypts,'average')
    
    
    
    mnfit = mean(fit,4);
    if x==0
       [fname pname] = uigetfile('*.mat','points file');
       if fname~=0
           load(fullfile(pname, fname));
       else
           figure
        imagesc(squeeze(mean(shiftData(:,:,5,:),4)));
        hold on; plot(ypts,xpts,'w.','Markersize',2)
        for i = 1:7
            [y(i) x(i)] =ginput(1);
            plot(y(i),x(i),'o');
        end
        x=round(x); y=round(y);
        
 
        close(gcf);
        [fname pname] = uiputfile('*.mat','save points?');
        if fname~=0
            save(fullfile(pname,fname),'x','y');
        end
        
       end
    
    end
              col = 'bgrcmyk'
        w=2;
        range = -w:w;
    if rep ==2
        
        figure
        subplot(2,3,1)
        imagesc(mean(shiftData(:,:,5,:),4));
        hold on
        for i = 1:7;
            plot([y(i)-w y(i)-w y(i)+w y(i)+w y(i)-w],[x(i)-w x(i)+w x(i)+w x(i)-w x(i)-w],col(i),'LineWidth',2)
        end
        legend({'V1','LM','AL','RL','AM','PM','MM'})
        
        hold on; plot(ypts,xpts,'w.','Markersize',2); axis off
        
        subplot(2,3,2);
        hold on
        for i = 1:7
            d=(squeeze(mean(mean(mnfit(x(i)+range,y(i)+range,1:3),2),1)));
            plot(d,col(i),'LineWidth',2);
        end
        xlim([1 3]); title('x');
        set(gca,'Xtick',[1 4]);
        set(gca,'Xticklabel',{'medial','lateral'});
        
        
        subplot(2,3,3)
        hold on
        for i = 1:7
            d=squeeze(mean(mean(mnfit(x(i)+range,y(i)+range,4:5),2),1));
            plot(d/max(d),col(i),'LineWidth',2);
        end
        xlim([1 2]);ylim([0 1]); title('y');
        set(gca,'Xtick',[1 3]);
        set(gca,'Xticklabel',{'top','bottom'});
        
        subplot(2,3,4);
        hold on
        for i = 1:7
            d =  squeeze(mean(mean(mnfit(x(i)+range,y(i)+range,6:11),2),1));
            plot(d(1)/max(d),[col(i) 'o'],'LineWidth',2);
            plot(2:6,d(2:6)/max(d),col(i),'LineWidth',2);
        end
        xlim([0.75 6.25]); ylim([0 1]); title('sf');
        set(gca,'Xtick',[1 3 5]);
        set(gca,'Xticklabel',{'0','0.04','0.16'});
        xlabel('cpd')
        
        subplot(2,3,5);
        hold on
        for i = 1:7
            d=squeeze(mean(mean(mnfit(x(i)+range,y(i)+range,12:15),2),1));
            plot(d/max(d),col(i),'LineWidth',2);
        end
        xlim([1 4]); ylim([0 1]); title('tf');
        set(gca,'XtickLabel',{'0', '2','8'});
        xlabel('Hz')
        
        subplot(2,3,6);
        
        hold on
        for i = 1:7
            d=squeeze(mean(mean(mean(cycavg(x(i)+range,y(i)+range,:,:),4),2),1));
            %     repd = repmat(d,[10 1]);
            %     dconvd = deconvg6s(repd'+0.5,0.1);
            %    % figure
            %    d = dconvd(16:30);
            plot((circshift(d',10)-min(d))/(max(d)-min(d)),col(i),'LineWidth',2);
        end
        xlim([1 20]); title('timecourse');
        xlabel('frames')
        
        %%% 4x3y
    elseif rep==4
        figure
        subplot(2,3,1)
        imagesc(mean(shiftData(:,:,5,:),4));
        hold on
        for i = 1:7;
            plot([y(i)-w y(i)-w y(i)+w y(i)+w y(i)-w],[x(i)-w x(i)+w x(i)+w x(i)-w x(i)-w],col(i),'LineWidth',2)
        end
        legend({'V1','LM','AL','RL','AM','PM','MM'})
        
        hold on; plot(ypts,xpts,'w.','Markersize',2); axis off
        
        subplot(2,3,2);
        hold on
        for i = 1:7
            d=(squeeze(mean(mean(mnfit(x(i)+range,y(i)+range,1:4),2),1)));
            plot(d,col(i),'LineWidth',2);
        end
        xlim([1 4]); title('x');
        set(gca,'Xtick',[1 4]);
        set(gca,'Xticklabel',{'medial','lateral'});
        
        
        subplot(2,3,3)
        hold on
        for i = 1:7
            d=squeeze(mean(mean(mnfit(x(i)+range,y(i)+range,5:7),2),1));
            plot(d/max(d),col(i),'LineWidth',2);
        end
        xlim([1 3]);ylim([0 1]); title('y');
        set(gca,'Xtick',[1 3]);
        set(gca,'Xticklabel',{'top','bottom'});
        
        subplot(2,3,4);
        hold on
        for i = 1:7
            d =  squeeze(mean(mean(mnfit(x(i)+range,y(i)+range,8:13),2),1));
            plot(d(1)/max(d),[col(i) 'o'],'LineWidth',2);
            plot(2:6,d(2:6)/max(d),col(i),'LineWidth',2);
        end
        xlim([0.75 6.25]); ylim([0 1]); title('sf');
        set(gca,'Xtick',[1 3 5]);
        set(gca,'Xticklabel',{'0','0.04','0.16'});
        xlabel('cpd')
        
        subplot(2,3,5);
        hold on
        for i = 1:7
            d=squeeze(mean(mean(mnfit(x(i)+range,y(i)+range,14:16),2),1));
            plot(d/max(d),col(i),'LineWidth',2);
        end
        xlim([1 3]); ylim([0 1]); title('tf');
        set(gca,'Xtick',[1 2 3])
        set(gca,'XtickLabel',{'0', '2','8'});
        xlabel('Hz')
        
        subplot(2,3,6);
        
        hold on
        for i = 1:7
            d=squeeze(mean(mean(mean(cycavg(x(i)+range,y(i)+range,:,:),4),2),1));
            %     repd = repmat(d,[10 1]);
            %     dconvd = deconvg6s(repd'+0.5,0.1);
            %    % figure
            %    d = dconvd(16:30);
            plot((circshift(d',10)-min(d))/(max(d)-min(d)),col(i),'LineWidth',2);
        end
        xlim([1 15]); title('timecourse');
        xlabel('frames')
   
    
    elseif rep ==1
        
        figure
        subplot(2,3,1)
        imagesc(mean(shiftData(:,:,5,:),4));
        hold on
        for i = 1:7;
            plot([y(i)-w y(i)-w y(i)+w y(i)+w y(i)-w],[x(i)-w x(i)+w x(i)+w x(i)-w x(i)-w],col(i),'LineWidth',2)
        end
        legend({'V1','LM','AL','RL','AM','PM','MM'})
        
        hold on; plot(ypts,xpts,'w.','Markersize',2); axis off
        
        subplot(2,3,2);
        hold on
        for i = 1:7
            d=(squeeze(mean(mean(mnfit(x(i)+range,y(i)+range,1:3),2),1)));
            plot(d,col(i),'LineWidth',2);
        end
        xlim([1 3]); title('x');
        set(gca,'Xtick',[1 4]);
        set(gca,'Xticklabel',{'medial','lateral'});
        
        
        subplot(2,3,3)
        hold on
        for i = 1:7
            d=squeeze(mean(mean(mnfit(x(i)+range,y(i)+range,4:5),2),1));
            plot(d/max(d),col(i),'LineWidth',2);
        end
        xlim([1 2]);ylim([0 1]); title('y');
        set(gca,'Xtick',[1 3]);
        set(gca,'Xticklabel',{'top','bottom'});
        
        subplot(2,3,4);
        hold on
        for i = 1:7
            d =  squeeze(mean(mean(mnfit(x(i)+range,y(i)+range,6:7),2),1));
            plot(d(1)/max(d),[col(i) 'o'],'LineWidth',2);
            plot(1:2,d(1:2)/max(d),col(i),'LineWidth',2);
        end
        xlim([0.75 2.25]); ylim([0 1]); title('sf');
  
        xlabel('cpd')
        
%         subplot(2,3,5);
%         hold on
%         for i = 1:7
%             d=squeeze(mean(mean(mnfit(x(i)+range,y(i)+range,12:15),2),1));
%             plot(d/max(d),col(i),'LineWidth',2);
%         end
%         xlim([1 4]); ylim([0 1]); title('tf');
%         set(gca,'XtickLabel',{'0', '2','8'});
%         xlabel('Hz')
        
        subplot(2,3,6);
        
        hold on
        for i = 1:7
            d=squeeze(mean(mean(mean(cycavg(x(i)+range,y(i)+range,:,:),4),2),1));
            %     repd = repmat(d,[10 1]);
            %     dconvd = deconvg6s(repd'+0.5,0.1);
            %    % figure
            %    d = dconvd(16:30);
            plot((circshift(d',10)-min(d))/(max(d)-min(d)),col(i),'LineWidth',2);
        end
        xlim([1 25]); title('timecourse');
        xlabel('frames')
        
        %%% 4x3y
    end
end

    
    
