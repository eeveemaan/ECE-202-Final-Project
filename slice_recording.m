%% Quick filter
Fs = 5000;
lsave = length(savedata(1,:));
data_f = fft(savedata(1,:)); data_f(50/Fs*lsave+1:end-50/Fs*lsave)=0;
data_filt = real(ifft(data_f));

figure;
plot(savetime(1000:end-1000),data_filt(1000:end-1000))

%% Split out snippets

idx_sound = find(savesound); L=length(idx_sound);

% Downsampling
data_ds = data_filt(1,1:20:end);
idx_sound = int32(round(idx_sound/20,0));

% Fs original: 5000, downsample => 250
Fs = 250;
Tsnip = 4; N = Fs*Tsnip;
t = 0:1/Fs:Tsnip;

snippets_d = zeros(length(idx_sound),N+1);

figure;
for ii=1:L
    %snippets_d(ii,:)=savedata(1,idx_sound(ii)-N/2:idx_sound(ii)+N/2);
    snippets_d(ii,:)=data_ds(1,idx_sound(ii)-N/2:idx_sound(ii)+N/2);
    subplot(L,1,ii)
    plot(t,snippets_d(ii,:))
end


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


snippets_rec = zeros(length(idx_sound),N+1);
figure;
for ii=1:L
    snippets_rec(ii,:) = ifft(snippets_f(ii,:));
    subplot(L,1,ii);
    plot(t,abs(snippets_rec(ii,:)))
    %xlim([0 50])
end



%% Welch
pwelch(data_ds(1,:),N,0,N,Fs,"onesided","psd")
xlim([0 50])