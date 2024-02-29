%% Quick filter
Fs = 5000;
Tsnip = 0.1; N = Fs*Tsnip;
t = 0:1/Fs:Tsnip;
lsave = length(savedata(1,:));
data_f = fft(savedata(1,:)); data_f(50/Fs*lsave+1:end-50/Fs*lsave)=0;
data_filt = real(ifft(data_f));

figure;
plot(savetime(1000:end-1000),data_filt(1000:end-1000))

%% Split out snippets

idx_sound = find(savesound); L=length(idx_sound);

% % Downsampling
% data_ds = data_filt(1,1:20:end);
% idx_sound = int32(round(idx_sound/20,0));
% 
% % Fs original: 5000, downsample => 250
% Fs = 250;
% Tsnip = 0.1; N = Fs*Tsnip;
% t = 0:1/Fs:Tsnip;

snippets_d = zeros(length(idx_sound),N+1);

figure;
for ii=1:L
    snippets_d(ii,:)=data_filt(1,idx_sound(ii)-N/2:idx_sound(ii)+N/2);
    %snippets_d(ii,:)=data_ds(1,idx_sound(ii)-N/2:idx_sound(ii)+N/2);
    subplot(L,1,ii)
    plot(t,snippets_d(ii,:))
end

figure(pos=[0 1000 600 300]);
plot(t*1e3,mean(snippets_d,1),color=[0.2 0.5 0.9 1],LineWidth=2); hold on;
plot(t*1e3,snippets_d,color=[0.2 0.5 0.9 0.3])
rectangle('Position',[50 -25 18 45],'FaceColor',[0.6 0.6 0.2 0.1],'EdgeColor',[0.6 0.6 0.1 0.3]);
text(55,-20,"Sound","FontSize",12,"FontWeight",'bold',"FontName",'Arial')
ax = gca; ax.LineWidth = 2; ax.FontName = 'Arial'; ax.FontSize = 12;
title('sound centered epochs overlayed'); xlabel('Time (ms)'); ylabel('Potential (\muV)');
legend('Average','Individual')


%% FFT of snippets
snippets_f = zeros(length(idx_sound),N+1);
figure;
f = 0:Fs/N:Fs;
for ii=1:L
    snippets_f(ii,:) = fft(snippets_d(ii,:));
    snippets_f(ii,50:end-50) = 0;
    subplot(L,1,ii);
    plot(f,abs(snippets_f(ii,:)))
    xlim([0 50])
end


% snippets_rec = zeros(length(idx_sound),N+1);
% figure;
% for ii=1:L
%     snippets_rec(ii,:) = ifft(snippets_f(ii,:));
%     subplot(L,1,ii);
%     plot(t,abs(snippets_rec(ii,:)))
%     %xlim([0 50])
% end



%% Welch
pwelch(data_ds(1,:),N,0,N,Fs,"onesided","psd")
xlim([0 50])