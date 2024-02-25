%assuming lab computers use intan RHD acquisition software https://intantech.com/RHX_software.html
%data sent to other software via TCP commands 
%see TCP documentation "RHX TCP Control" pdf https://intantech.com/downloads.html?tabSelect=Software&yPos=199.3333282470703
%ConnectTCPWaveformDataOutput
% Open a server TCP socket that another piece of software can connect to, either locally or via
% network, to stream waveform data (raw data from non-headstage channels, and wideband, low-
% pass, high-pass, dc amplifier, and stimulation data from headstage channels; spike data is sent
% separately)
%SEE PAGES 29-31 ON THE RHX SOFTWARE MANUAL PDF 
% Setup TCP Client
tcpObj = tcpclient('YourServerAddress', PortNumber); % Specify your TCP server's address and port number


dlog = zeros(1, 500); 
tic 
while true %or while toc is less than X seconds 
    data = []; 
    for i = 1:500 % Collect 500 samples each epoch
        % Read data from TCP server
        dataString = readline(tcpObj);
        
        % Process the received data
        numStr = strsplit(dataString, ',');
        num = str2double(numStr{1});
        
        % Append data
        data = [data, num];
    end
    
    % alassifier function
    %classificationResult = myPredictFunction(data);
    %disp(['Classification: ', num2str(classificationResult)]);
    
    % Add epoch to the log
    dlog = [dlog; data];
   
    % if Condition
    %     break;
    % end
end
