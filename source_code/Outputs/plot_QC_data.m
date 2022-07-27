function [] = plot_QC_data(app,Data,filename, QC_gate)

% plot spacing properties
PlotGroups = 5;
GroupLabels = {'Raw Data','Noise Removal','Diameter Calibration','Outlier & Spike-In Removal','RPS_{PASS} Data'};
Spacer = 0.1;
TotalRow = PlotGroups/Spacer;
ColumnNo = 3;
plotheight = (TotalRow/PlotGroups)*(1-Spacer);
plotInd = ColumnNo+1:ColumnNo*(TotalRow/PlotGroups):TotalRow*ColumnNo;
titleInd = linspace(PlotGroups*ColumnNo,ColumnNo,PlotGroups);


fig = figure('visible','off');

fig.Units = 'centimeters';
fig.Position = [0 0 21.0 29.7];
fig.PaperUnits = 'centimeters';
fig.PaperSize = [21.0 29.7];
fig.PaperUnits = 'normalized';
fig.PaperPosition = [0 0 1 1];

td = tiledlayout(TotalRow,3,"TileSpacing","compact","Padding","compact");

res = 256;
Bins.time = linspace(min(Data.time),max(Data.time),res);
Bins.diam = linspace(0,400,res);
Bins.ttime = linspace(0,100,res);


ind = and(~Data.outliers,~Data.NoiseInd);
TimeData = Data.time(ind);
TTimeData = Data.ttime(ind);
DiamData = Data.diam(ind);


%% raw data plotting
nexttile(plotInd(1),[plotheight,1])
histogram2(Data.time,Data.non_norm_d,'XBinEdges',Bins.time,"YBinEdges",Bins.diam,"DisplayStyle","tile")
set(gca,'GridLineStyle','none')
xlabel('Time (seconds)')
ylabel('Output Diameter (nm)')

nexttile(plotInd(1)+1,[plotheight,1])
histogram2(Data.ttime,Data.non_norm_d,'XBinEdges',Bins.ttime,"YBinEdges",Bins.diam,"DisplayStyle","tile")
set(gca,'GridLineStyle','none')
xlabel('Transit Time (µs)')
ylabel('Output Diameter (nm)')

nexttile(plotInd(1)+2,[plotheight,1])
histogram(Data.non_norm_d,Bins.diam,'DisplayStyle','stairs','LineWidth',2)
xlabel('Output Diameter (nm)')

%% raw data plotting
nexttile(plotInd(2),[plotheight,1])
histogram2(Data.time(~Data.NoiseInd),Data.non_norm_d(~Data.NoiseInd),'XBinEdges',Bins.time,"YBinEdges",Bins.diam,"DisplayStyle","tile")
set(gca,'GridLineStyle','none')
xlabel('Time (seconds)')
ylabel('Output Diameter (nm)')

nexttile(plotInd(2)+1,[plotheight,1])
histogram2(Data.ttime(~Data.NoiseInd),Data.non_norm_d(~Data.NoiseInd),'XBinEdges',Bins.ttime,"YBinEdges",Bins.diam,"DisplayStyle","tile")
set(gca,'GridLineStyle','none')
xlabel('Transit Time (µs)')
ylabel('Output Diameter (nm)')

nexttile(plotInd(2)+2,[plotheight,1])
histogram(Data.non_norm_d(~Data.NoiseInd),Bins.diam,'DisplayStyle','stairs','LineWidth',2)
xlabel('Output Diameter (nm)')

%% diam calibration data plotting
nexttile(plotInd(3),[plotheight,1])
histogram2(Data.time(~Data.NoiseInd),Data.diam(~Data.NoiseInd),'XBinEdges',Bins.time,"YBinEdges",Bins.diam,"DisplayStyle","tile")
set(gca,'GridLineStyle','none')
xlabel('Time (seconds)')
ylabel('RPS_{PASS} Diameter (nm)')

nexttile(plotInd(3)+1,[plotheight,1])
histogram2(Data.ttime(~Data.NoiseInd),Data.diam(~Data.NoiseInd),'XBinEdges',Bins.ttime,"YBinEdges",Bins.diam,"DisplayStyle","tile")
set(gca,'GridLineStyle','none')
xlabel('Transit Time (µs)')
ylabel('RPS_{PASS} Diameter (nm)')

nexttile(plotInd(3)+2,[plotheight,1])
histogram(Data.diam(~Data.NoiseInd),Bins.diam,'DisplayStyle','stairs','LineWidth',2)
xlabel('RPS_{PASS} Diameter (nm)')

%% outlier & spike-in removal data plotting
nexttile(plotInd(4),[plotheight,1])
histogram2(Data.time(~Data.outliers),Data.diam(~Data.outliers),'XBinEdges',Bins.time,"YBinEdges",Bins.diam,"DisplayStyle","tile")
set(gca,'GridLineStyle','none')
xlabel('Time (seconds)')
ylabel('RPS_{PASS} Diameter (nm)')

nexttile(plotInd(4)+1,[plotheight,1])
histogram2(Data.ttime(~Data.outliers),Data.diam(~Data.outliers),'XBinEdges',Bins.ttime,"YBinEdges",Bins.diam,"DisplayStyle","tile")
set(gca,'GridLineStyle','none')
xlabel('Transit Time (µs)')
ylabel('RPS_{PASS} Diameter (nm)')

nexttile(plotInd(4)+2,[plotheight,1])

[N] = histcounts(DiamData,Bins.diam);
bin_cent = Bins.diam(2:end) - (diff(Bins.diam)/2);
plot(bin_cent, N,'-k','linewidth',2)

switch Data.RPSPASS.SpikeInUsed
    case 'Yes'
        hold on
        SpikeInGateInd = bin_cent > Data.SpikeInGateMinNorm & bin_cent < Data.SpikeInGateMaxNorm;
        plot(bin_cent(SpikeInGateInd), N(SpikeInGateInd),'-r','linewidth',2)
        legend({'Sample data','Spike-in data'},'box','off')
end

xlabel('RPS_{PASS} Diameter (nm)')
ylabel('Count')

%% final resulting data


nexttile(plotInd(5),[plotheight,1])
histogram2(TimeData,DiamData,'XBinEdges',Bins.time,"YBinEdges",Bins.diam,"DisplayStyle","tile")
set(gca,'GridLineStyle','none')
xlabel('Time (seconds)')
ylabel('RPS_{PASS} Diameter (nm)')

nexttile(plotInd(5)+1,[plotheight,1])
histogram2(TTimeData,DiamData,'XBinEdges',Bins.ttime,"YBinEdges",Bins.diam,"DisplayStyle","tile")
set(gca,'GridLineStyle','none')
xlabel('Transit Time (µs)')
ylabel('RPS_{PASS} Diameter (nm)')

nexttile(plotInd(5)+2,[plotheight,1])
histogram(Data.diam(~Data.outliers),Bins.diam,'DisplayStyle','stairs','LineWidth',2)
xlabel('RPS_{PASS} Diameter (nm)')
ylabel('Count')

LabelSubplots(td, titleInd, GroupLabels)

print(fig,filename, '-dpng', '-r300');

close(fig)



end

