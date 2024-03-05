figure;
subplot(2,1,1);
plot(savetime,savedata(1,:));
subplot(2,1,2);
plot(savetime,savesound(1:length(savetime)));