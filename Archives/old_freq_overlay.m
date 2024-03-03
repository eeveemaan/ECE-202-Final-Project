% Plot overlay
% figure('Position',[0 10 600 600]);
% subplot(2,1,1);
% plot(f,mean(abs(snippets_f(:,:,1)),1),'Color',[0.2 0.5 0.9 1],'LineWidth',2); hold on;
% plot(f,abs(snippets_f(:,:,1)),'Color',[0.2 0.5 0.9 0.1]); xlim([0 50]);
% ax = gca; ax.LineWidth = 2; ax.FontName = 'Arial'; ax.FontSize = 12;
% title('Channel 19'); xlabel('Frequency (Hz)'); ylabel('Strength (\muV)');
% legend('Average','Individual')
% 
% subplot(2,1,2);
% plot(f,mean(abs(snippets_f(:,:,2)),1),'Color',[0.2 0.5 0.9 1],'LineWidth',2); hold on;
% plot(f,abs(snippets_f(:,:,2)),'Color',[0.2 0.5 0.9 0.1]); xlim([0 50]);
% ax = gca; ax.LineWidth = 2; ax.FontName = 'Arial'; ax.FontSize = 12;
% title('Channel 20'); xlabel('Frequency (Hz)'); ylabel('Strength (\muV)');
% legend('Average','Individual')