% data_anova=NaN(max([lcount rcount scount]),2,3);
% data_anova(1:lcount,:,1)=SigPower_l;data_anova(1:rcount,:,2)=SigPower_r;data_anova(1:scount,:,3)=SigPower_s;
% aov=anova(A);

%events=[string(char(ones(lcount,1)*'left')); string(char(ones(rcount,1)*'right')); string(char(ones(scount,1)*'silence'))];
%events=[repmat("Left",lcount,1);repmat("Right",rcount,1);repmat("Silence",scount,1)];

%A = table(events,features);
%aov=anova({events},features,FactorNames=['Event']);