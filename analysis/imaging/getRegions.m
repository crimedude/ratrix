function [gradmapAll merge]= getRegions(expfile, pathname, outpathname)

maptype = {'topox','topoy'};

    
    expname = [expfile.subj expfile.expt];
    for m = 1:2
        if m==1
            load([pathname expfile.topox],'map')
        elseif m==2
            load([pathname expfile.topoy],'map')
        end
        
        map = map{3};
        map_all{m} = map;
        ph = angle(map);
        amp = abs(map);
        
        %         figure
        %         imshow(polarMap(map));
        %         title(sprintf('polarmap %s',maptype{m}));
        
        [dx dy] = gradient(ph);
        grad = dx + sqrt(-1)*dy;
        grad_amp = abs(grad);
        
        dx(grad_amp>1)=0; dy(grad_amp>1)=0;
        dx = medfilt2(dx,[5 5]); dy = medfilt2(dy, [5 5]);
        
        grad = dx + sqrt(-1)*dy;
        
        %         figure
        %         plot(dx.*amp./abs(grad),dy.*amp./abs(grad),'.')
        %         title(sprintf('normalized gradient %s',maptype{m}));
        
        
        gradmap = grad.*amp./abs(grad);
        gradmap(isnan(gradmap))=0;
        size(gradmap)
  
        gradmapAll(:,:,1+(m-1)*2) = real(gradmap);
        gradmapAll(:,:,2+(m-1)*2) = imag(gradmap);
        %         figure
        %         imshow(polarMap(gradmap));
        %         title(sprintf('gradient %s',maptype{m}));
        
        
        absnorm = abs(grad);       
        absnorm(absnorm==0)=10^6;
        grad_all{m} = grad; amp_all{m}=amp;  norm_grad{m} = grad./absnorm;
        
        %         figure
        %         imshow(polarMap(gradmap));
        %         hold on
        %         quiver(10*real(norm_grad{m}),10*imag(norm_grad{m}))
        
    end
    
    %     figure
    %     plot(angle(norm_grad{1}).*(amp_all{1}>0.002),angle(norm_grad{2}).*(amp_all{2}>0.002),'.')
    %     title('angle 1 vs angle 2 normalized by step binary');
    
    ampscale = amp_all{2};
    ampscale = ampscale/0.0075;
    ampscale(ampscale>1)=1;
    
    merge = zeros(size(map,1),size(map,2),3);
    
    %     merge(:,:,1) = ampscale.*(0.66*(real(norm_grad{1}) + 1)*0.5 + 0.33*(imag(norm_grad{2}) + 1)*0.5) ;
    %     merge(:,:,2) = ampscale.*((imag(norm_grad{1}) + 1)*0.5 );
    %     merge(:,:,3) = ampscale.*(0.66*(real(norm_grad{2}) + 1)*0.5+ 0.33*(imag(norm_grad{2}) + 1)*0.5);
    
    merge(:,:,1) = ampscale.*(0.75*(real(norm_grad{1}) + 1)*0.5 + 0.25*(imag(norm_grad{2}) + 1)*0.5) ;
    merge(:,:,2) = ampscale.*(0.75*(imag(norm_grad{1}) + 1)*0.5 + 0.25*(imag(norm_grad{2}) + 1)*0.5);
    merge(:,:,3) = ampscale.*(0.75*(real(norm_grad{2}) + 1)*0.5+ 0.25*(imag(norm_grad{2}) + 1)*0.5);
 
    
    % merge(:,:,1) = ampscale.*(real(norm_grad{1}) + 1)*0.5 ;
    % merge(:,:,2) = ampscale.*(imag(norm_grad{1}) + 1)*0.5;
    % merge(:,:,3) = ampscale.*(real(norm_grad{2}) + 1)*0.5;
    
    %     figure
    %     imshow(merge)
    %     title('composite of gradient components')
    
    clear div
    for m= 1:2
        div{m} = divergence(real(norm_grad{m}),imag(norm_grad{m}));
    end
    borders = abs(div{1})+abs(div{2});
    
    
    
    %
    %     for m = 1:2
    %         figure
    %         imshow((merge));
    %         hold on
    %         quiver(10*real(norm_grad{m}),10*imag(norm_grad{m}),'w')
    %     end
    
    
    %     figure
    %     imshow(zeros(size(merge)));
    %     hold on
    %     quiver(10*real(norm_grad{1}),10*imag(norm_grad{1}),'r')
    %     quiver(10*real(norm_grad{2}),10*imag(norm_grad{2}),'g')
    
    mapsfig = figure;
    mag=1;
    dx=3;
    rangex = dx:dx:size(norm_grad{1},1);
    rangey = dx:dx:size(norm_grad{1},1);
    
    subplot(2,4,2)
    imshow(imresize(merge,mag));
                xlim([20 150]);
            ylim([10 140]);
            
    for m= 1:2
        subplot(2,4,4*(m-1)+1)
        imshow(polarMap(map_all{m},90))
        if m==1
            title([expfile.subj ' ' expfile.expt ' ' expfile.monitor])
        end
        xlim([20 140]*mag);
        ylim([10 130]*mag);
    end
    
    for m = 1:2
        subplot(2,4,4*(m-1)+3)
        imshow(imresize(merge,mag));
        hold on
        quiver(rangex*mag, rangey*mag, 10*real(norm_grad{m}(rangex,rangey)),10*imag(norm_grad{m}(rangex,rangey)),'w')
        xlim([20 140]*mag);
        ylim([10 130]*mag);
    end
    
    for m= 1:2
        subplot(2,4,4*(m-1)+4)
        imshow(polarMap(map_all{m},90));
        hold on
        quiver(rangex, rangey, 10*real(norm_grad{m}(rangex,rangey)),10*imag(norm_grad{m}(rangex,rangey)),'w')
        xlim([20 140]*mag);
        ylim([10 130]*mag);
    end
    
        for m= 2:2
      subplot(2,4,6)
            imshow(polarMap(map_all{m},90));
            hold on
            h=imagesc(borders,[0 1]);
            transp = borders>0.3;
            set(h,'AlphaData',transp);
            xlim([20 150]);
            ylim([10 140]);
        end
    
    save([outpathname expname '_topography.mat'],'div','norm_grad','map_all','grad_all','amp_all','merge');
    saveas(mapsfig,[outpathname expname 'topo.fig'],'fig')
    %     figure
    %     imshow(ones(size(merge)));
    %     hold on
    %     quiver(rangex, rangey, 10*real(norm_grad{1}(rangex,rangey)),10*imag(norm_grad{1}(rangex,rangey)),'r')
    %     quiver(rangex, rangey, 10*real(norm_grad{2}(rangex,rangey)),10*imag(norm_grad{2}(rangex,rangey)),'b')
    %     xlim([30 110]);
    %     ylim([10 90]);
    
    % figure
    %     imagesc(angle(map_all{1})); colormap(hsv); colorbar
    %
    %     figure
    %     imagesc(angle(map_all{2})); colormap(hsv);colorbar
    %
    %     d1 = (angle(map_all{1})- -2.8);
    %     d1(d1>pi) = d1(d1>pi)-2*pi;
    %
    %     d2 = (angle(map_all{2})- -2.8);
    %     d2(d2>pi) = d2(d2>pi)-2*pi;
    %
    %     ecc = sqrt(d1.^2 + d2.^2);
    %     figure
    %     imagesc(ecc,[ 0 2]);
    %     title('eccentricity plot')
    %
    %     figure
    %     subplot(2,2,1)
    %     imshow(polarMap(map_all{1}));
    %     subplot(2,2,2)
    %     imshow(polarMap(map_all{2}));
    %     subplot(2,2,3)
    %     imshow(merge)
    %     subplot(2,2,4)
    %     imagesc(ecc,[ 0 2]); axis equal
    
end



