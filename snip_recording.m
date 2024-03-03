%% Read file
[fname,fpath] = uigetfile("./data/*.mat");
load(strcat(fpath,fname));

%% Quick filter
% NEEDS TSNIP AND AFTER TO BE SET BEFOREHAND!
Fs = 5000;
N = Fs*Tsnip;
t = 0:1/Fs:Tsnip;
lsave = length(savedata(1,:));
idx_filt=int32(50/Fs*lsave); % Sets the freq after which you want to set to 0. 
data_f = [fft(savedata(1,:)); fft(savedata(2,:))]; data_f(:,idx_filt:end-idx_filt)=0;
data_filt = real([ifft(data_f(1,:)); ifft(data_f(2,:))]);
% data_filt = savedata(:,:);

discard_sf=1000;
figure;
subplot(2,1,1)
plot(savetime(discard_sf:end-discard_sf),data_filt(1,discard_sf:end-discard_sf))

subplot(2,1,2)
plot(savetime(discard_sf:end-discard_sf),data_filt(2,discard_sf:end-discard_sf))

%% Split out snippets
idx_sound = find(savesound); L=length(idx_sound);

lcount=sum(savesound==1); rcount=sum(savesound==2); scount=sum(savesound==3);

%after = 0.5;    % [0,1] fraction/percentage of epoch window that is after sound played

% % Downsampling
% data_ds = data_filt(1,1:20:end);
% idx_sound = int32(round(idx_sound/20,0));
% 
% % Fs original: 5000, downsample => 250
% Fs = 250;
% Tsnip = 0.1; N = Fs*Tsnip;
% t = 0:1/Fs:Tsnip;

snippets_d = zeros(length(idx_sound),N+1,2);
snippets_l = zeros(lcount,N+1,2); lcounter=1;
snippets_r = zeros(rcount,N+1,2); rcounter=1;
snippets_s = zeros(scount,N+1,2); scounter=1;

% figure;
for ii=1:L
    for jj=1:2
        snippets_d(ii,:,jj)=data_filt(jj,idx_sound(ii)-round(N*(1-after),0):idx_sound(ii)+round(N*after,0));

        %snippets_d(ii,:,jj)=data_filt(jj,idx_sound(ii)-N/2:idx_sound(ii)+N/2);
        %snippets_d(ii,:)=data_ds(1,idx_sound(ii)-N/2:idx_sound(ii)+N/2);
        % subplot(L,1,ii)
        % plot(t,snippets_d(ii,:))
    end

    if(savesound(idx_sound(ii))==1)
        snippets_l(lcounter,:,:)=snippets_d(ii,:,:);
        lcounter=lcounter+1;
    elseif(savesound(idx_sound(ii))==2)
        snippets_r(rcounter,:,:)=snippets_d(ii,:,:);
        rcounter=rcounter+1;
    elseif(savesound(idx_sound(ii))==3)
        snippets_s(scounter,:,:)=snippets_d(ii,:,:);
        scounter=scounter+1;
    end
end

% Plot overlay
figure('Position',[0 10 600 600]);
subplot(2,1,1);
plot(t*1e3,mean(snippets_d(:,:,1),1),'Color',[0.2 0.5 0.9 1],'LineWidth',2); hold on;
plot(t*1e3,snippets_d(:,:,1),'Color',[0.2 0.5 0.9 0.1])
ax = gca; ax.LineWidth = 2; ax.FontName = 'Arial'; ax.FontSize = 12;
text(Tsnip/2*1000+1,0.8*ax.YLim(1),"Sound","FontSize",8,"FontWeight",'bold',"FontName",'Arial')
rectangle('Position',[Tsnip*(1-after)*1000 ax.YLim(1) 18 ax.YLim(2)-ax.YLim(1)],'FaceColor',[0.6 0.6 0.2 0.1],'EdgeColor',[0.6 0.6 0.1 0.3]);
title('Channel 19'); xlabel('Time (ms)'); ylabel('Potential (\muV)');
legend('Average','Individual')

subplot(2,1,2);
plot(t*1e3,mean(snippets_d(:,:,2),1),'Color',[0.2 0.5 0.9 1],'LineWidth',2); hold on;
plot(t*1e3,snippets_d(:,:,2),'Color',[0.2 0.5 0.9 0.1])
ax = gca; ax.LineWidth = 2; ax.FontName = 'Arial'; ax.FontSize = 12;
rectangle('Position',[Tsnip*(1-after)*1000 ax.YLim(1) 18 ax.YLim(2)-ax.YLim(1)],'FaceColor',[0.6 0.6 0.2 0.1],'EdgeColor',[0.6 0.6 0.1 0.3]);
text(Tsnip/2*1000+1,0.8*ax.YLim(1),"Sound","FontSize",8,"FontWeight",'bold',"FontName",'Arial')
title('Channel 20'); xlabel('Time (ms)'); ylabel('Potential (\muV)');
legend('Average','Individual')

sgtitle("sound centered epochs overlayed")

%% Plotting Epoch Comparison of Different Sound Types

figure('Position',[0 10 600 600]);
subplot(2,3,1);
plot(t*1e3,mean(snippets_l(:,:,1),1),'Color',[0.2 0.5 0.9 1],'LineWidth',2); hold on;
plot(t*1e3,snippets_l(:,:,1),'Color',[0.2 0.5 0.9 0.1])
ax = gca; ax.LineWidth = 2; ax.FontName = 'Arial'; ax.FontSize = 12;
text(Tsnip/2*1000+1,0.8*ax.YLim(1),"Sound","FontSize",8,"FontWeight",'bold',"FontName",'Arial')
rectangle('Position',[Tsnip*(1-after)*1000 ax.YLim(1) 18 ax.YLim(2)-ax.YLim(1)],'FaceColor',[0.6 0.6 0.2 0.1],'EdgeColor',[0.6 0.6 0.1 0.3]);
title('Left Channel 19'); xlabel('Time (ms)'); ylabel('Potential (\muV)');
legend('Average','Individual')

subplot(2,3,4);
plot(t*1e3,mean(snippets_l(:,:,2),1),'Color',[0.2 0.5 0.9 1],'LineWidth',2); hold on;
plot(t*1e3,snippets_l(:,:,2),'Color',[0.2 0.5 0.9 0.1])
ax = gca; ax.LineWidth = 2; ax.FontName = 'Arial'; ax.FontSize = 12;
rectangle('Position',[Tsnip*(1-after)*1000 ax.YLim(1) 18 ax.YLim(2)-ax.YLim(1)],'FaceColor',[0.6 0.6 0.2 0.1],'EdgeColor',[0.6 0.6 0.1 0.3]);
text(Tsnip/2*1000+1,0.8*ax.YLim(1),"Sound","FontSize",8,"FontWeight",'bold',"FontName",'Arial')
title('Left Channel 20'); xlabel('Time (ms)'); ylabel('Potential (\muV)');
legend('Average','Individual')

subplot(2,3,2);
plot(t*1e3,mean(snippets_r(:,:,1),1),'Color',[0.2 0.5 0.9 1],'LineWidth',2); hold on;
plot(t*1e3,snippets_r(:,:,1),'Color',[0.2 0.5 0.9 0.1])
ax = gca; ax.LineWidth = 2; ax.FontName = 'Arial'; ax.FontSize = 12;
text(Tsnip/2*1000+1,0.8*ax.YLim(1),"Sound","FontSize",8,"FontWeight",'bold',"FontName",'Arial')
rectangle('Position',[Tsnip*(1-after)*1000 ax.YLim(1) 18 ax.YLim(2)-ax.YLim(1)],'FaceColor',[0.6 0.6 0.2 0.1],'EdgeColor',[0.6 0.6 0.1 0.3]);
title('Right Channel 19'); xlabel('Time (ms)'); ylabel('Potential (\muV)');
legend('Average','Individual')

subplot(2,3,5);
plot(t*1e3,mean(snippets_r(:,:,2),1),'Color',[0.2 0.5 0.9 1],'LineWidth',2); hold on;
plot(t*1e3,snippets_r(:,:,2),'Color',[0.2 0.5 0.9 0.1])
ax = gca; ax.LineWidth = 2; ax.FontName = 'Arial'; ax.FontSize = 12;
rectangle('Position',[Tsnip*(1-after)*1000 ax.YLim(1) 18 ax.YLim(2)-ax.YLim(1)],'FaceColor',[0.6 0.6 0.2 0.1],'EdgeColor',[0.6 0.6 0.1 0.3]);
text(Tsnip/2*1000+1,0.8*ax.YLim(1),"Sound","FontSize",8,"FontWeight",'bold',"FontName",'Arial')
title('Right Channel 20'); xlabel('Time (ms)'); ylabel('Potential (\muV)');
legend('Average','Individual')

subplot(2,3,3);
plot(t*1e3,mean(snippets_s(:,:,1),1),'Color',[0.2 0.5 0.9 1],'LineWidth',2); hold on;
plot(t*1e3,snippets_s(:,:,1),'Color',[0.2 0.5 0.9 0.1])
ax = gca; ax.LineWidth = 2; ax.FontName = 'Arial'; ax.FontSize = 12;
text(Tsnip/2*1000+1,0.8*ax.YLim(1),"Sound","FontSize",8,"FontWeight",'bold',"FontName",'Arial')
rectangle('Position',[Tsnip*(1-after)*1000 ax.YLim(1) 18 ax.YLim(2)-ax.YLim(1)],'FaceColor',[0.6 0.6 0.2 0.1],'EdgeColor',[0.6 0.6 0.1 0.3]);
title('Silence Channel 19'); xlabel('Time (ms)'); ylabel('Potential (\muV)');
legend('Average','Individual')

subplot(2,3,6);
plot(t*1e3,mean(snippets_s(:,:,2),1),'Color',[0.2 0.5 0.9 1],'LineWidth',2); hold on;
plot(t*1e3,snippets_s(:,:,2),'Color',[0.2 0.5 0.9 0.1])
ax = gca; ax.LineWidth = 2; ax.FontName = 'Arial'; ax.FontSize = 12;
rectangle('Position',[Tsnip*(1-after)*1000 ax.YLim(1) 18 ax.YLim(2)-ax.YLim(1)],'FaceColor',[0.6 0.6 0.2 0.1],'EdgeColor',[0.6 0.6 0.1 0.3]);
text(Tsnip/2*1000+1,0.8*ax.YLim(1),"Sound","FontSize",8,"FontWeight",'bold',"FontName",'Arial')
title('Silence Channel 20'); xlabel('Time (ms)'); ylabel('Potential (\muV)');
legend('Average','Individual')

sgtitle("sound centered epochs overlayed")