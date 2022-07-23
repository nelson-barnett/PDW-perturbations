% pert_dist
% 
% Attempt to find a visualization/metric for
% perturbation magnitude using 4d Euclidian distance 
% 
% Generates a tiled figure of frequency against distance from 0 in histograms.

addpath('../Brewermap colors');

%% Load data

P_all = load('../Data/Data n50000g0.014p0.5d03-Jun22/perturbationPercent.csv');
M = load('../Data/Data n50000g0.014p0.5d03-Jun22/metrics.csv');
y = M(:,1);

P_all(end+1:end+4,:) = load('../Data/Data n50000g0.016p0.5d04-Jun22/perturbationPercent.csv');
M = load('../Data/Data n50000g0.016p0.5d04-Jun22/metrics.csv');
y(:,end+1) = M(:,1);

P_all(end+1:end+4,:) = load('../Data/Data n50000g0.019p0.5d05-Jun22/perturbationPercent.csv');
M = load('../Data/Data n50000g0.019p0.5d05-Jun22/metrics.csv');
y(:,end+1) = M(:,1);

%% Distance

d = zeros(size(y));
w = zeros(4,1);
pind = (1:4:size(P_all,1));

for i = 1:size(y,2)
    P = P_all(pind(i):pind(i)+3,:);   
    
    for j = 1:length(P)
        v = P(:,j);        
        d(j,i) = sqrt((v-w)'*(v-w));
    end 
    
end

%% Viz

x = (1:length(d))';
map = brewermap(2,'Set1');
gam = [0.014 0.016 0.019];

figure
tiledlayout('flow')
for i = 1:size(d,2)
    data = d(:,i);
%     nexttile
%     hold on
%     scatter(x(y(:,i)==0),data(y(:,i)==0),'b')
%     scatter(x(y(:,i)==1),data(y(:,i)==1),'r')
%     title(['Gamma = ', num2str(gam(i))],'Fontsize',18)
    
    nexttile
    hold on
    histogram(data(y(:,i)==0),'FaceColor',map(2,:),'facealpha',.5,'edgecolor','none')
    histogram(data(y(:,i)==1),'FaceColor',map(1,:),'facealpha',.5,'edgecolor','none')
    title(['Gamma = ', num2str(gam(i))],'Fontsize',18)
    xlabel('Distance','Fontsize',14);
    ylabel('Frequency','Fontsize',14);
    legend('non-falls','falls','Location','northeast')
end
