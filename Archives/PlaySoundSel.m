% Selections: 1-Blackman filtered sine, 2-Blackman filtered gaussian
% 3-Plain gaussian 4-Homophasic-Antiphasic,

function WhatSound = PlaySoundSel(sel)
global y_bfs
global y_bfw
global y_w
global y_homo
global y_anti

Fs = 44100;
ii = randi(2);

if(sel==1)
    if(ii==1)
        sound(y_bfs,Fs);
    else
        sound(flip(y_bfs,2),Fs);
    end    
elseif(sel==2)
    if(ii==1)
        sound(y_bfw,Fs);
    else
        sound(flip(y_bfw,2),Fs);
    end        
elseif(sel==3)
    if(ii==1)
        sound(y_w,Fs);
    else
        sound(flip(y_w,2),Fs);
    end    
else    
    % -1: Homo, 1: Anti
    if(ii==1)
        sound(y_homo,Fs);
    else
        sound(y_anti,Fs);
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