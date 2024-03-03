% Plot overlay
figure('Position',[0 10 1200 600]);
subplot(2,4,1);
plot(t*1e3,mean(snippets_d(:,:,1),1),'Color',[0.2 0.5 0.9 1],'LineWidth',2); hold on;
plot(t*1e3,snippets_d(:,:,1),'Color',[0.2 0.5 0.9 0.1])
ax = gca; ax.LineWidth = 2; ax.FontName = 'Arial'; ax.FontSize = 12;
ylim([-60 60]);
text(Tsnip/2*1000+1,0.8*ax.YLim(1),"Sound","FontSize",8,"FontWeight",'bold',"FontName",'Arial')
rectangle('Position',[Tsnip*(1-after)*1000 ax.YLim(1) 18 ax.YLim(2)-ax.YLim(1)],'FaceColor',[0.6 0.6 0.2 0.1],'EdgeColor',[0.6 0.6 0.1 0.3]);
title('All Channel 19'); xlabel('Time (ms)'); ylabel('Potential (\muV)');
legend('Average','Individual')

subplot(2,4,5);
plot(t*1e3,mean(snippets_d(:,:,2),1),'Color',[0.2 0.5 0.9 1],'LineWidth',2); hold on;
plot(t*1e3,snippets_d(:,:,2),'Color',[0.2 0.5 0.9 0.1])
ax = gca; ax.LineWidth = 2; ax.FontName = 'Arial'; ax.FontSize = 12;
ylim([-60 60]);
rectangle('Position',[Tsnip*(1-after)*1000 ax.YLim(1) 18 ax.YLim(2)-ax.YLim(1)],'FaceColor',[0.6 0.6 0.2 0.1],'EdgeColor',[0.6 0.6 0.1 0.3]);
text(Tsnip/2*1000+1,0.8*ax.YLim(1),"Sound","FontSize",8,"FontWeight",'bold',"FontName",'Arial')
title('All Channel 20'); xlabel('Time (ms)'); ylabel('Potential (\muV)');
legend('Average','Individual')

subplot(2,4,2);
plot(t*1e3,mean(snippets_l(:,:,1),1),'Color',[0.2 0.5 0.9 1],'LineWidth',2); hold on;
plot(t*1e3,snippets_l(:,:,1),'Color',[0.2 0.5 0.9 0.1])
ax = gca; ax.LineWidth = 2; ax.FontName = 'Arial'; ax.FontSize = 12;
ylim([-60 60]);
text(Tsnip/2*1000+1,0.8*ax.YLim(1),"Sound","FontSize",8,"FontWeight",'bold',"FontName",'Arial')
rectangle('Position',[Tsnip*(1-after)*1000 ax.YLim(1) 18 ax.YLim(2)-ax.YLim(1)],'FaceColor',[0.6 0.6 0.2 0.1],'EdgeColor',[0.6 0.6 0.1 0.3]);
title('Left Channel 19'); xlabel('Time (ms)'); ylabel('Potential (\muV)');
legend('Average','Individual')

subplot(2,4,6);
plot(t*1e3,mean(snippets_l(:,:,2),1),'Color',[0.2 0.5 0.9 1],'LineWidth',2); hold on;
plot(t*1e3,snippets_l(:,:,2),'Color',[0.2 0.5 0.9 0.1])
ax = gca; ax.LineWidth = 2; ax.FontName = 'Arial'; ax.FontSize = 12;
ylim([-60 60]);
rectangle('Position',[Tsnip*(1-after)*1000 ax.YLim(1) 18 ax.YLim(2)-ax.YLim(1)],'FaceColor',[0.6 0.6 0.2 0.1],'EdgeColor',[0.6 0.6 0.1 0.3]);
text(Tsnip/2*1000+1,0.8*ax.YLim(1),"Sound","FontSize",8,"FontWeight",'bold',"FontName",'Arial')
title('Left Channel 20'); xlabel('Time (ms)'); ylabel('Potential (\muV)');
legend('Average','Individual')

subplot(2,4,3);
plot(t*1e3,mean(snippets_r(:,:,1),1),'Color',[0.2 0.5 0.9 1],'LineWidth',2); hold on;
plot(t*1e3,snippets_r(:,:,1),'Color',[0.2 0.5 0.9 0.1])
ax = gca; ax.LineWidth = 2; ax.FontName = 'Arial'; ax.FontSize = 12;
ylim([-60 60]);
text(Tsnip/2*1000+1,0.8*ax.YLim(1),"Sound","FontSize",8,"FontWeight",'bold',"FontName",'Arial')
rectangle('Position',[Tsnip*(1-after)*1000 ax.YLim(1) 18 ax.YLim(2)-ax.YLim(1)],'FaceColor',[0.6 0.6 0.2 0.1],'EdgeColor',[0.6 0.6 0.1 0.3]);
title('Right Channel 19'); xlabel('Time (ms)'); ylabel('Potential (\muV)');
legend('Average','Individual')

subplot(2,4,7);
plot(t*1e3,mean(snippets_r(:,:,2),1),'Color',[0.2 0.5 0.9 1],'LineWidth',2); hold on;
plot(t*1e3,snippets_r(:,:,2),'Color',[0.2 0.5 0.9 0.1])
ax = gca; ax.LineWidth = 2; ax.FontName = 'Arial'; ax.FontSize = 12;
ylim([-60 60]);
rectangle('Position',[Tsnip*(1-after)*1000 ax.YLim(1) 18 ax.YLim(2)-ax.YLim(1)],'FaceColor',[0.6 0.6 0.2 0.1],'EdgeColor',[0.6 0.6 0.1 0.3]);
text(Tsnip/2*1000+1,0.8*ax.YLim(1),"Sound","FontSize",8,"FontWeight",'bold',"FontName",'Arial')
title('Right Channel 20'); xlabel('Time (ms)'); ylabel('Potential (\muV)');
legend('Average','Individual')

subplot(2,4,4);
plot(t*1e3,mean(snippets_s(:,:,1),1),'Color',[0.2 0.5 0.9 1],'LineWidth',2); hold on;
plot(t*1e3,snippets_s(:,:,1),'Color',[0.2 0.5 0.9 0.1])
ax = gca; ax.LineWidth = 2; ax.FontName = 'Arial'; ax.FontSize = 12;
ylim([-60 60]);
text(Tsnip/2*1000+1,0.8*ax.YLim(1),"Sound","FontSize",8,"FontWeight",'bold',"FontName",'Arial')
rectangle('Position',[Tsnip*(1-after)*1000 ax.YLim(1) 18 ax.YLim(2)-ax.YLim(1)],'FaceColor',[0.6 0.6 0.2 0.1],'EdgeColor',[0.6 0.6 0.1 0.3]);
title('Silence Channel 19'); xlabel('Time (ms)'); ylabel('Potential (\muV)');
legend('Average','Individual')

subplot(2,4,8);
plot(t*1e3,mean(snippets_s(:,:,2),1),'Color',[0.2 0.5 0.9 1],'LineWidth',2); hold on;
plot(t*1e3,snippets_s(:,:,2),'Color',[0.2 0.5 0.9 0.1])
ax = gca; ax.LineWidth = 2; ax.FontName = 'Arial'; ax.FontSize = 12;
ylim([-60 60]);
rectangle('Position',[Tsnip*(1-after)*1000 ax.YLim(1) 18 ax.YLim(2)-ax.YLim(1)],'FaceColor',[0.6 0.6 0.2 0.1],'EdgeColor',[0.6 0.6 0.1 0.3]);
text(Tsnip/2*1000+1,0.8*ax.YLim(1),"Sound","FontSize",8,"FontWeight",'bold',"FontName",'Arial')
title('Silence Channel 20'); xlabel('Time (ms)'); ylabel('Potential (\muV)');
legend('Average','Individual')

sgtitle("sound centered epochs overlayed")