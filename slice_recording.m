%% Split out snippets

idx_sound = find(savesound); L=length(idx_sound);

Fs = 5000;
Tsnip = 0.5; N = Fs*Tsnip;
t = 0:1/Fs:Tsnip;

snippets_d = zeros(length(idx_sound),N+1);

figure;
for ii=1:L
    snippets_d(ii,:)=savedata(1,idx_sound(ii)-N/2:idx_sound(ii)+N/2);
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

pwelch(saves(i,:),10000,50,200,1e4)