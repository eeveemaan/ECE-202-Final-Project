% Get baseline for current user
global Ball

% Set snipping parameters
Tsnip=1; after=1;

% Take data measured so far, filter and save. 
Fs = 5000; N = Fs*Tsnip; t = 0:1/Fs:Tsnip;
lsave = length(savedata(1,:));
idx_filt=int32(50/Fs*lsave); % Sets the freq after which you want to set to 0. 
data_f = [fft(savedata(1,:)); fft(savedata(2,:))]; data_f(:,idx_filt:end-idx_filt)=0;
data_filt = real([ifft(data_f(1,:)); ifft(data_f(2,:))]);
% data_filt = savedata(:,:);

discard_sf=1000;
  
idx_sound = find(savesound); L=length(idx_sound);                
snippets_labels = zeros(L,1); snippets_issound = zeros(L,1);

dcount=0; lcounter=1; rcounter=1; scounter=1;

% Split out snippets
for ii=1:L
    for jj=1:2
        temp(:,jj)=data_filt(jj,idx_sound(ii)-round(N*(1-after),0):idx_sound(ii)+round(N*after,0));        
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

lcount=lcounter-1; rcount=rcounter-1; scount=scounter-1;

seconds = size(snippets_d,1);
alphaBand = [8 12]; 
betaBand = [13 20];
alphaPower = zeros(seconds, 2); %two channels
betaPower = zeros(seconds, 2);

for ii = 1:seconds
    for jj=1:2
    % Calculate alpha power for each channel
    alphaPower(ii, jj) = bandpower(snippets_d(ii,:,jj), Fs, alphaBand);
    betaPower(ii, jj) = bandpower(snippets_d(ii,:,jj), Fs, betaBand);    
    end
end
    
features = [alphaPower, betaPower];

% INSERT TRAINING CODE
[Ball_new,dev,stat] = mnrfit(features, snippets_labels);


% OUTCOME: IT SHOULD SET / OVERWRITE BALL
Ball = Ball_new;