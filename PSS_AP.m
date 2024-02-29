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

% CHANGING TO ACCOMODATE PLAYING SILENCE: randi(2) -> randi(3), 
% if ii==3, simply return WhatSound = 3. 
% New convention, 1 = left, 2 = right, 3 = silence (when sound expected)

ii = randi(3);

if(ii==3)
    disp("Silence");
    WhatSound=3;
    return;
end

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
    %WhatSound=-1;  % Old
else
    disp("right/anti");
    %WhatSound=+1;  % Old
end
WhatSound=ii; % NEW
end