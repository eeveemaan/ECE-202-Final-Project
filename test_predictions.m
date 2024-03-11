prediction = zeros(L,1); 

for ii=1:L
    prediction(ii) =predict_alpha(snippets_d(ii,:,:));   
end

correct_issound = sum(snippets_issound==prediction)/L*100;
   
