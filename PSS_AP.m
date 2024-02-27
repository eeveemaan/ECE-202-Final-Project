% Selections: 1-Blackman filtered sine, 2-Blackman filtered gaussian
% 3-Plain gaussian 4-Homophasic-Antiphasic,

function WhatSound = PSS_AP(sel)
global y_bfs_L
global y_bfs_R
global y_bfw_L
global y_bfw_R
global y_w_L
global y_w_R
global y_H
global y_A

Fs = 44100;
ii = randi(2);

if(sel==1)
    if(ii==1)
        play(y_bfs_L);
    else
        play(y_bfs_R);
    end    
elseif(sel==2)
    if(ii==1)
        play(y_bfw_L);
    else
        play(y_bfw_R);
    end        
elseif(sel==3)
    if(ii==1)
        play(y_w_L);
    else
        play(y_w_R);
    end    
else    
    % -1: Homo, 1: Anti
    if(ii==1)
        play(y_H);
    else
        play(y_A);
    end
end

if(ii==1)
    disp("left/homo");
    WhatSound=-1;
else
    disp("right/anti");
    WhatSound=+1;
end
end