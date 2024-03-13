%% Loads the following files, merges them and trains a model
% files = string(ls);
% files = files(3:end);

files=split(string(ls));
files=files(1:end-1);

%files = files.name
Fs = 5000; % Sampling frequency

allFeatures = [];
allLabels = [];
Tsnip = 1;
after= 2;
for i = 1:length(files)
    [sl, sr, ss] = snipEEG(files{i},Tsnip,after);
    featl = featEEGsnip(sl);
    featr = featEEGsnip(sr);
    feats = featEEGsnip(ss);
    allFeatures = [allFeatures; featl ;featr ;feats];
    for n = 1:size(sl,1)
        allLabels = [allLabels 1];
    end

    for n = 1:size(sr,1)
        allLabels = [allLabels 2];
    end

    for n = 1:size(ss, 1)
        allLabels = [allLabels 3];
    end
end
allFeatures = allFeatures;
%% Splits the data into training and test sets
cv = cvpartition(length(allLabels), 'HoldOut', 0.2);
idxTrain = training(cv);
idxTest = test(cv);

XTrain = allFeatures(idxTrain,:);
yTrain = allLabels(idxTrain);
XTest = allFeatures(idxTest,:);
yTest = allLabels(idxTest);

%% Fit SVM model
template = templateSVM(...
    'KernelFunction', 'linear', ...
    'PolynomialOrder', [], ...
    'KernelScale', 'auto', ...
    'BoxConstraint', 1, ...
    'Standardize', true);
SVMModel = fitcecoc(XTrain, yTrain, 'Learners', template, ...
    'Coding', 'onevsall',...
    'OptimizeHyperparameters','auto',...
    'HyperparameterOptimizationOptions',...
    struct('AcquisitionFunctionName',...
    'expected-improvement-plus'));

%% Predict using the SVM model
[label, score] = predict(SVMModel, XTest);

%% Calculate and display the model accuracy
accuracy = sum(label == yTest') / length(yTest);
fprintf('Model accuracy: %.2f%%\n', accuracy * 100);


%% Function definitions:
function features = featEEGsnip(snips)
    Fs = 5000;
    seconds = size(snips,1);
    alphaBand = [8 12]; 
    betaBand = [13 20];
    alphaPower = zeros(seconds, 2); %two channels
    betaPower = zeros(seconds, 2);
    diffAlpha = zeros(seconds, 2);
    diffBeta = zeros(seconds, 2);
    for i = 1:seconds
        % Calculate alpha power for each channel
        alphaPower(i, 1) = bandpower(snips(i,:,1), Fs, alphaBand);
        alphaPower(i, 2) = bandpower(snips(i,:,2), Fs, alphaBand);
        betaPower(i, 1) = bandpower(snips(i,:,1), Fs, betaBand);
        betaPower(i, 2) = bandpower(snips(i,:,2), Fs, betaBand);
    end
    for i = 2:seconds
        diffAlpha(i, 1) = alphaPower(i, 1) - alphaPower(i-1,1);
        diffAlpha(i, 2) = alphaPower(i, 2) - alphaPower(i-1,2);
        diffBeta(i, 1) = betaPower(i, 1) - betaPower(i-1,1);
        diffBeta(i, 2) = betaPower(i, 2) - betaPower(i-1,2);
    end
        
    

    features = [alphaPower, betaPower];

end
    
   
function [snippets_l, snippets_r, snippets_s] = snipEEG(file,Tsnip,after)
    load(file)
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
    
end
