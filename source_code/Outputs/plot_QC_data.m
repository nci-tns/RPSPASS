function [] = plot_QC_data(Data, type)

% create default plot properties
res = 256;
Bins.time = linspace(min(Data.time),max(Data.time),res);
Bins.diam = linspace(0,400,400);
Bins.ttime = linspace(0,100,res);
Bins.diamcent = Bins.diam(2:end) - diff(Bins.diam)/2;

% create figure
fig = figure('visible','off');
fig.Units = 'centimeters';
fig.Position = [0 0 21.0 29.7];
fig.PaperUnits = 'centimeters';
fig.PaperSize = [21.0 29.7];
fig.PaperUnits = 'normalized';
fig.PaperPosition = [0 0 1 1];

% plot spacing properties
PlotGroups = 5;
GroupLabels = {'Raw Data','Noise Removal','Diameter Calibration','Outlier Removal & Spike-In Identification','Final RPS_{PASS} Data'};
Spacer = 0.1;
TotalRow = PlotGroups/Spacer;
ColumnNo = 3;
plotheight = (TotalRow/PlotGroups)*(1-Spacer);
plotInd = ColumnNo+1:ColumnNo*(TotalRow/PlotGroups):TotalRow*ColumnNo;
titleInd = linspace(PlotGroups*ColumnNo,ColumnNo,PlotGroups);

td = tiledlayout(TotalRow,3,"TileSpacing","compact","Padding","compact");

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
N = histcounts(Data.non_norm_d, Bins.diam);
plot(Bins.diamcent,N,'-k','LineWidth',2)
xlabel('Output Diameter (nm)')
ylabel('Count')
xlim([min(Bins.diam) max(Bins.diam)])

%% noise removal data plotting
switch type
    case 'failed'
        if ~isfield(Data.Indices,'NoiseInd')
            ind = [];
        else
            ind = ~Data.Indices.NoiseInd;
        end
    otherwise
        ind = ~Data.Indices.NoiseInd;
end

nexttile(plotInd(2),[plotheight,1])
histogram2(Data.time(ind), Data.non_norm_d(ind),'XBinEdges',Bins.time,"YBinEdges",Bins.diam,"DisplayStyle","tile")
set(gca,'GridLineStyle','none')
xlabel('Time (seconds)')
ylabel('Output Diameter (nm)')

nexttile(plotInd(2)+1,[plotheight,1])
histogram2(Data.ttime(ind), Data.non_norm_d(ind),'XBinEdges',Bins.ttime,"YBinEdges",Bins.diam,"DisplayStyle","tile")
set(gca,'GridLineStyle','none')
xlabel('Transit Time (µs)')
ylabel('Output Diameter (nm)')

nexttile(plotInd(2)+2,[plotheight,1])
N = histcounts(Data.non_norm_d(ind), Bins.diam);
plot(Bins.diamcent,N,'-k','LineWidth',2)
xlabel('Output Diameter (nm)')
ylabel('Count')
xlim([min(Bins.diam) max(Bins.diam)])

%% diam calibration data plotting
switch type
    case 'failed'
        if ~isfield(Data.Indices,'NoiseInd')
            ind = [];
        else
            ind = ~Data.Indices.NoiseInd;
        end
    otherwise
        ind = ~Data.Indices.NoiseInd;
end

nexttile(plotInd(3),[plotheight,1])
histogram2(Data.time(ind), Data.diam(ind),'XBinEdges',Bins.time,"YBinEdges",Bins.diam,"DisplayStyle","tile")
set(gca,'GridLineStyle','none')
xlabel('Time (seconds)')
ylabel('RPS_{PASS} Diameter (nm)')

nexttile(plotInd(3)+1,[plotheight,1])
histogram2(Data.ttime(ind), Data.diam(ind),'XBinEdges',Bins.ttime,"YBinEdges",Bins.diam,"DisplayStyle","tile")
set(gca,'GridLineStyle','none')
xlabel('Transit Time (µs)')
ylabel('RPS_{PASS} Diameter (nm)')

nexttile(plotInd(3)+2,[plotheight,1])
N = histcounts(Data.diam(ind), Bins.diam);
plot(Bins.diamcent,N,'-k','LineWidth',2)
xlabel('RPS_{PASS} Diameter (nm)')
ylabel('Count')
xlim([min(Bins.diam) max(Bins.diam)])

%% outlier & spike-in removal data plotting
switch type
    case 'failed'
        if ~isfield(Data.Indices,'Events_OutlierRemoved')
            ind = [];
        else
            ind = Data.Indices.Events_OutlierRemoved;
        end
    otherwise
        ind = Data.Indices.Events_OutlierRemoved;
end

nexttile(plotInd(4),[plotheight,1])
histogram2(Data.time(ind), Data.diam(ind),'XBinEdges',Bins.time,"YBinEdges",Bins.diam,"DisplayStyle","tile")
set(gca,'GridLineStyle','none')
xlabel('Time (seconds)')
ylabel('RPS_{PASS} Diameter (nm)')

nexttile(plotInd(4)+1,[plotheight,1])
histogram2(Data.ttime(ind), Data.diam(ind),'XBinEdges',Bins.ttime,"YBinEdges",Bins.diam,"DisplayStyle","tile")
set(gca,'GridLineStyle','none')
xlabel('Transit Time (µs)')
ylabel('RPS_{PASS} Diameter (nm)')

nexttile(plotInd(4)+2,[plotheight,1])
N = histcounts(Data.diam(ind), Bins.diam);
plot(Bins.diamcent,N,'-k','LineWidth',2)
hold on

switch Data.RPSPASS.SpikeInUsed
    case 'Yes'
        ind = Data.Indices.SpikeIn_OutlierRemoved;
        N = histcounts(Data.diam(ind), Bins.diam);
        N(N==0) = nan;
        plot(Bins.diamcent,N,'-r','LineWidth',2)
        xlabel('RPS_{PASS} Diameter (nm)')
        ylabel('Count')
        xlim([min(Bins.diam) max(Bins.diam)])
end
%% final resulting data

switch type
    case 'cohort'
        ind = Data.Indices.Cohort_Events_OutliersSpikeinRemoved;
    case 'individual'
        ind = Data.Indices.Events_OutlierSpikeinRemoved;
    case 'failed'
        ind = [];
end

nexttile(plotInd(5),[plotheight,1])
histogram2(Data.time(ind), Data.diam(ind),'XBinEdges',Bins.time,"YBinEdges",Bins.diam,"DisplayStyle","tile")
set(gca,'GridLineStyle','none')
xlabel('Time (seconds)')
ylabel('RPS_{PASS} Diameter (nm)')

nexttile(plotInd(5)+1,[plotheight,1])
histogram2(Data.ttime(ind), Data.diam(ind),'XBinEdges',Bins.ttime,"YBinEdges",Bins.diam,"DisplayStyle","tile")
set(gca,'GridLineStyle','none')
xlabel('Transit Time (µs)')
ylabel('RPS_{PASS} Diameter (nm)')

nexttile(plotInd(5)+2,[plotheight,1])
N = histcounts(Data.diam(ind), Bins.diam);
plot(Bins.diamcent,N,'-k','LineWidth',2)
xlabel('RPS_{PASS} Diameter (nm)')
ylabel('Count')
xlim([min(Bins.diam) max(Bins.diam)])

%% label and export figure
LabelSubplots(td, titleInd, GroupLabels)
switch type
    case 'cohort'
        title(td, 'Cohort Gating | Passed QC')
    case 'individual'
        title(td, 'Individual Gating | Passed QC')
    case 'failed'
        title(td, 'Failed')
end

% get output directory and filename information
outputDir = getprefRPSPASS('RPSPASS','OutputDir');
outputPath = fullfile(outputDir,'QC Plots');
Filename = getprefRPSPASS('RPSPASS','CurrFile');
Full_filename = fullfile(outputPath,[replace(Filename,'.','-'),'.pdf']);

% make export directory if it does not exist
if ~isfolder(outputPath)
    mkdir(outputPath)
end

% check if a debug export has been written, if it has append the file.
if ~isfile(Full_filename)
    exportgraphics(fig,Full_filename,'BackgroundColor','white','ContentType','vector','Resolution',300)
else
    exportgraphics(fig,Full_filename,'BackgroundColor','white','ContentType','vector','append',true,'Resolution',300)
end


close(fig)

end

