function [] = plot_Failed_QC_data(app,Data,filename1, filename2)

fig = figure('visible','off');

fig.Units = 'centimeters';
fig.Position = [0 0 21.0 29.7];
fig.PaperUnits = 'centimeters';
fig.PaperSize = [21.0 29.7];
fig.PaperUnits = 'normalized';
fig.PaperPosition = [0 0 1 1];

td = tiledlayout(16,3,"TileSpacing","compact","Padding","compact");

res = 256;
Bins.time = linspace(min(Data.time),max(Data.time),res);
Bins.diam = linspace(0,400,res);
Bins.ttime = linspace(0,100,res);

%% raw data plotting
nexttile(4,[3,1])
histogram2(Data.time,Data.non_norm_d,'XBinEdges',Bins.time,"YBinEdges",Bins.diam,"DisplayStyle","tile")
set(gca,'GridLineStyle','none')
xlabel('Time (seconds)')
ylabel('Output Diameter (nm)')

nexttile(5,[3,1])
histogram2(Data.ttime,Data.non_norm_d,'XBinEdges',Bins.ttime,"YBinEdges",Bins.diam,"DisplayStyle","tile")
set(gca,'GridLineStyle','none')
xlabel('Transit Time (µs)')
ylabel('Output Diameter (nm)')

nexttile(6,[3,1])
histogram(Data.non_norm_d,Bins.diam,'DisplayStyle','stairs','LineWidth',2)
xlabel('Output Diameter (nm)')

%% diam calibration data plotting
nexttile(16,[3,1])
% histogram2(Data.time,Data.diam,'XBinEdges',Bins.time,"YBinEdges",Bins.diam,"DisplayStyle","tile")
set(gca,'GridLineStyle','none')
xlabel('Time (seconds)')
ylabel('RPS_{PASS} Diameter (nm)')

nexttile(17,[3,1])
% histogram2(Data.ttime,Data.diam,'XBinEdges',Bins.ttime,"YBinEdges",Bins.diam,"DisplayStyle","tile")
set(gca,'GridLineStyle','none')
xlabel('Transit Time (µs)')
ylabel('RPS_{PASS} Diameter (nm)')

nexttile(18,[3,1])
% histogram(Data.diam,Bins.diam,'DisplayStyle','stairs','LineWidth',2)
xlabel('RPS_{PASS} Diameter (nm)')

%% outlierremoval data plotting
nexttile(28,[3,1])
% histogram2(Data.time(~Data.outliers),Data.diam(~Data.outliers),'XBinEdges',Bins.time,"YBinEdges",Bins.diam,"DisplayStyle","tile")
set(gca,'GridLineStyle','none')
xlabel('Time (seconds)')
ylabel('RPS_{PASS} Diameter (nm)')

nexttile(29,[3,1])
% histogram2(Data.ttime(~Data.outliers),Data.diam(~Data.outliers),'XBinEdges',Bins.ttime,"YBinEdges",Bins.diam,"DisplayStyle","tile")
set(gca,'GridLineStyle','none')
xlabel('Transit Time (µs)')
ylabel('RPS_{PASS} Diameter (nm)')

nexttile(30,[3,1])
% histogram(Data.diam(~Data.outliers),Bins.diam,'DisplayStyle','stairs','LineWidth',2)
xlabel('RPS_{PASS} Diameter (nm)')

%% noise/spike in removal data plotting

% ind = and(~Data.outliers,QC_gate);
% TimeData = Data.time(ind);
% TTimeData = Data.ttime(ind);
% DiamData = Data.diam(ind);

nexttile(40,[3,1])
% histogram2(TimeData,DiamData,'XBinEdges',Bins.time,"YBinEdges",Bins.diam,"DisplayStyle","tile")
set(gca,'GridLineStyle','none')
xlabel('Time (seconds)')
ylabel('RPS_{PASS} Diameter (nm)')

nexttile(41,[3,1])
% histogram2(TTimeData,DiamData,'XBinEdges',Bins.ttime,"YBinEdges",Bins.diam,"DisplayStyle","tile")
set(gca,'GridLineStyle','none')
xlabel('Transit Time (µs)')
ylabel('RPS_{PASS} Diameter (nm)')

nexttile(42,[3,1])
% [N] = histcounts(DiamData,Bins.diam);
% bin_cent = Bins.diam(2:end) - (diff(Bins.diam)/2);
% plot(bin_cent, N,'-k','linewidth',2)
% 
% switch Data.RPSPASS.SpikeInUsed
%     case 'Yes'
%         hold on
%         SpikeInGateInd = bin_cent > Data.SpikeInGateMinNorm & bin_cent < Data.SpikeInGateMaxNorm;
%         plot(bin_cent(SpikeInGateInd), N(SpikeInGateInd),'-r','linewidth',2)
%         legend({'Sample data','Spike-in data'},'box','off')
% end

xlabel('RPS_{PASS} Diameter (nm)')


LabelSubplots(td)

print(fig,filename1, '-dpng', '-r300');
print(fig,filename2, '-dpng', '-r300');

close(fig)



end

