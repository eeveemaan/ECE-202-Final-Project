Trt = 1; Fs=5000;
Nrt = Fs*Trt;

% global savedata
% curr_block = savedata(:,end-Nrt:end);
curr_block=snippets_d(randi(60),1:end-1,:);

alphaBand = [8 12]; 
betaBand = [13 20];

alphaPower = [bandpower(curr_block(1,:), Fs, alphaBand); bandpower(curr_block(2,:), Fs, alphaBand)];
betaPower  = [bandpower(curr_block(1,:), Fs, betaBand); bandpower(curr_block(2,:), Fs, betaBand)];

global Ball    
prob = mnrval(Ball, [alphaPower; betaPower]');
confsound = 1-prob(1);

if(prob(2)>prob(3))
    dirsound=1;
else
    dirsound=-1;
end
    
%tg=randi(180)*pi/180;
tg = pi/2*(1+confsound*dirsound);

global ts
subplot(2,2,[2 4]);
disp_arrows;