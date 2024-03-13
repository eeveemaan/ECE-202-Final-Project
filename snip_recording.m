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

%lcount=sum(savesound==1); rcount=sum(savesound==2); scount=sum(savesound==3);

%after = 0.5;    % [0,1] fraction/percentage of epoch window that is after sound played

% % Downsampling
% data_ds = data_filt(1,1:20:end);
% idx_sound = int32(round(idx_sound/20,0));
% 
% % Fs original: 5000, downsample => 250
% Fs = 250;
% Tsnip = 0.1; N = Fs*Tsnip;
% t = 0:1/Fs:Tsnip;


snippets_labels = zeros(L,1); snippets_issound = zeros(L,1);
%snippets_d = zeros(L,N+1,2); 
%snippets_l = zeros(lcount,N+1,2);
%snippets_r = zeros(rcount,N+1,2); rcounter=1;
%snippets_s = zeros(scount,N+1,2); scounter=1;

dcount=0;
lcounter=1; rcounter=1; scounter=1;

clear temp snippets_d snippets_l snippets_r snippets_s snippets_labels snippets_issound;

% figure;
for ii=1:L
    for jj=1:2
        temp(:,jj)=data_filt(jj,idx_sound(ii)-round(N*(1-after),0):idx_sound(ii)+round(N*after,0));        
        %snippets_d(ii,:,jj)=data_filt(jj,idx_sound(ii)-N/2:idx_sound(ii)+N/2);
        %snippets_d(ii,:)=data_ds(1,idx_sound(ii)-N/2:idx_sound(ii)+N/2);
        % subplot(L,1,ii)
        % plot(t,snippets_d(ii,:))
    end
    
    if(sum(sum(temp.^2))>2e7)
        continue;
    end
    dcount=dcount+1;
    snippets_d(dcount,:,:)   =temp;
    snippets_labels(dcount)  =savesound(idx_sound(ii));
    snippets_issound(dcount) =(savesound(idx_sound(ii))~=3);

    if(savesound(idx_sound(ii))==1)
        snippets_l(lcounter,:,:)=snippets_d(dcount,:,:);
        lcounter=lcounter+1;
    elseif(savesound(idx_sound(ii))==2)
        snippets_r(rcounter,:,:)=snippets_d(dcount,:,:);
        rcounter=rcounter+1;
    elseif(savesound(idx_sound(ii))==3)
        snippets_s(scounter,:,:)=snippets_d(dcount,:,:);
        scounter=scounter+1;
    end
end

lcount=lcounter-1;
rcount=rcounter-1;
scount=scounter-1;

%% Plot Overlay v2
cell_snippets = {snippets_d, snippets_l, snippets_r, snippets_s; "All", "Left", "Right", "Silence"};
ylimits = [-60 60];
figure('Position',[0 10 1200 600]);
for idx_cell=1:length(cell_snippets)
    subplot(2,4,idx_cell);
    plot(t*1e3,mean(cell_snippets{1, idx_cell}(:,:,1),1),'Color',[0.2 0.5 0.9 1],'LineWidth',2); hold on;
    plot(t*1e3,cell_snippets{1,idx_cell}(:,:,1),'Color',[0.2 0.5 0.9 0.1]);
    ax = gca; ax.LineWidth = 2; ax.FontName = 'Arial'; ax.FontSize = 12;
    ylim(ylimits);
    text(Tsnip/2*1000+1,0.8*ax.YLim(1),"Sound","FontSize",8,"FontWeight",'bold',"FontName",'Arial')
    rectangle('Position',[Tsnip*(1-after)*1000 ax.YLim(1) 18 ax.YLim(2)-ax.YLim(1)],'FaceColor',[0.6 0.6 0.2 0.1],'EdgeColor',[0.6 0.6 0.1 0.3]);
    title(cell_snippets{2, idx_cell} + 'Channel 19'); xlabel('Time (ms)'); ylabel('Potential (\muV)');
    legend('Average','Individual')
    
    subplot(2,4,idx_cell+4);
    plot(t*1e3,mean(cell_snippets{1,idx_cell}(:,:,2),1),'Color',[0.2 0.5 0.9 1],'LineWidth',2); hold on;
    plot(t*1e3,cell_snippets{1,idx_cell}(:,:,2),'Color',[0.2 0.5 0.9 0.1]);
    ax = gca; ax.LineWidth = 2; ax.FontName = 'Arial'; ax.FontSize = 12;
    ylim(ylimits);
    rectangle('Position',[Tsnip*(1-after)*1000 ax.YLim(1) 18 ax.YLim(2)-ax.YLim(1)],'FaceColor',[0.6 0.6 0.2 0.1],'EdgeColor',[0.6 0.6 0.1 0.3]);
    text(Tsnip/2*1000+1,0.8*ax.YLim(1),"Sound","FontSize",8,"FontWeight",'bold',"FontName",'Arial')
    title(cell_snippets{2, idx_cell} + 'Channel 20'); xlabel('Time (ms)'); ylabel('Potential (\muV)');
    legend('Average','Individual')
end
sgtitle("sound centered epochs overlayed")

%% FFT of snippets
snippets_f = zeros(dcount,N+1,2);
snippets_fl = zeros(lcount,N+1,2);
snippets_fr = zeros(rcount,N+1,2);
snippets_fs = zeros(scount,N+1,2);

lcounter=1; rcounter=1; scounter=1;
% figure;
f = 0:Fs/N:Fs;
for ii=1:dcount
    for jj=1:2
        snippets_f(ii,:,jj) = fft(snippets_d(ii,:,jj));
        %snippets_f(ii,50:end-50,1) = 0;
    end

    if(savesound(idx_sound(ii))==1)
        snippets_fl(lcounter,:,:)=snippets_f(ii,:,:);
        lcounter=lcounter+1;
    elseif(savesound(idx_sound(ii))==2)
        snippets_fr(rcounter,:,:)=snippets_f(ii,:,:);
        rcounter=rcounter+1;
    elseif(savesound(idx_sound(ii))==3)
        snippets_fs(scounter,:,:)=snippets_f(ii,:,:);
        scounter=scounter+1;
    end
end

cell_snippets = {snippets_f, snippets_fl, snippets_fr, snippets_fs; "All", "Left", "Right", "Silence"};
xlimits = [0 50]; ylimits=[0 2e4];
figure('Position',[0 10 1200 600]);
for idx_cell=1:length(cell_snippets)
    subplot(2,4,idx_cell);
    plot(f,mean(abs(cell_snippets{1, idx_cell}(:,:,1)),1),'Color',[0.2 0.5 0.9 1],'LineWidth',2); hold on;
    plot(f,abs(cell_snippets{1,idx_cell}(:,:,1)),'Color',[0.2 0.5 0.9 0.1]);
    ax = gca; ax.LineWidth = 2; ax.FontName = 'Arial'; ax.FontSize = 12;
    xlim(xlimits); ylim(ylimits);
    title(cell_snippets{2, idx_cell} + 'Channel 19'); xlabel('Frequency (Hz)'); ylabel('Potential (\muV)'); 
    legend('Average','Individual')

    subplot(2,4,idx_cell+4);
    plot(f,mean(abs(cell_snippets{1,idx_cell}(:,:,2)),1),'Color',[0.2 0.5 0.9 1],'LineWidth',2); hold on;
    plot(f,abs(cell_snippets{1,idx_cell}(:,:,2)),'Color',[0.2 0.5 0.9 0.1]);
    ax = gca; ax.LineWidth = 2; ax.FontName = 'Arial'; ax.FontSize = 12;
    xlim(xlimits); ylim(ylimits);   
    title(cell_snippets{2, idx_cell} + 'Channel 20'); xlabel('Frequency (Hz)'); ylabel('Potential (\muV)');
    legend('Average','Individual')
end
sgtitle("Epochs: Frequency Domain")