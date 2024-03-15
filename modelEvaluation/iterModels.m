%THIS CODE NEEDS TO BE RUN FROM THE MODELFITTING FOLDER
fList = {'1','2','3','4','5','6','7'};
%filenames = {'f1MNR','f2MNR','f3MNR','f4MNR','f5MNR','f6MNR','f7MNR'};
filenames = {'f1SVM','f2SVM','f3SVM','f4SVM','f5SVM','f6SVM','f7SVM'};
accuracies = zeros(10,7);
% for q=1:length(fList) 
%     for m = 1:10
%         [acc, coeffs,predictions,prob,stat] = TestTrainMNR(fList{q});
%         save("C:\Users\rairo\ECE-202-Final-Project\predict\modelEvaluation\"+filenames{q}+string(m),'coeffs','predictions','prob','stat')
%         accuracies(m,q) = acc;
%     end
%      
% end
   
for q=1:length(fList) 
    for m = 1:10
        [acc, labels,scores] = TestTrainSVM(fList{q});
        save("C:\Users\rairo\ECE-202-Final-Project\predict\modelEvaluation\"+filenames{q}+string(m),'labels','scores')
        accuracies(m,q) = acc;
    end
     
end