function UpdateLivePlots(app, Data)

% update axis plotting preferences
% UpdatePlottingPrefs(app)

% create gate for noise
switch app.RemovenoiseMenu.Checked
    case "off"
        noiseGate = true(size(Data.diam));
    case "on"
        noiseGate = Data.TT2SN > 1;
end


% plot 1 (by default time vs. diameter plot)
[xData, xBin, xScale, xLabel, xLims] = getAxisParameter(app, app.Plot1_Xaxis.Value, Data);
[yData, yBin, yScale, yLabel, yLims] = getAxisParameter(app, app.Plot1_Yaxis.Value, Data);

histogram2(app.DiamTimePlot, xData(noiseGate), yData(noiseGate),...
    'XBinEdges',xBin, 'YBinEdges',yBin,...
    'DisplayStyle','tile')
colormap(app.DiamTimePlot,app.Colormap) % update colormap
set(app.DiamTimePlot,'ColorScale',app.Colorscaling,...
    'xscale',xScale,'yscale',yScale) % update colorscaling
xlabel(app.DiamTimePlot, xLabel)
ylabel(app.DiamTimePlot, yLabel)
xlim(app.DiamTimePlot, xLims)
ylim(app.DiamTimePlot, yLims)
ylim(app.DiamTimePlot,'auto');
xticks(app.DiamTimePlot,'auto')
yticks(app.DiamTimePlot,'auto')
app.DiamTimePlot.Toolbar.Visible = 'off';
app.DiamTimePlot.XGrid = app.XMajorMenu.Checked;
app.DiamTimePlot.XMinorGrid = app.XMinorMenu.Checked;
app.DiamTimePlot.YGrid = app.YMajorMenu.Checked;
app.DiamTimePlot.YMinorGrid = app.YMinorMenu.Checked;

% plot S2N/transit time vs. diameter plot
[xData, xBin, xScale, xLabel, xLims] = getAxisParameter(app, app.Plot2_Xaxis.Value, Data);
[yData, yBin, yScale, yLabel, yLims] = getAxisParameter(app, app.Plot2_Yaxis.Value, Data);

histogram2(app.DiamTTimePlot, xData(noiseGate), yData(noiseGate),...
    'XBinEdges',xBin, 'YBinEdges',yBin,...
    'DisplayStyle','tile')
colormap(app.DiamTTimePlot,app.Colormap) % update colormap
set(app.DiamTTimePlot,'ColorScale',app.Colorscaling,...
    'xscale',xScale,'yscale',yScale) % update colorscaling
xlabel(app.DiamTTimePlot, xLabel)
ylabel(app.DiamTTimePlot, yLabel)
xlim(app.DiamTTimePlot, xLims)
ylim(app.DiamTTimePlot, yLims)
xticks(app.DiamTTimePlot,'auto')
yticks(app.DiamTTimePlot,'auto')
app.DiamTTimePlot.Toolbar.Visible = 'off';
app.DiamTTimePlot.XGrid = app.XMajorMenu.Checked;
app.DiamTTimePlot.XMinorGrid = app.XMinorMenu.Checked;
app.DiamTTimePlot.YGrid = app.YMajorMenu.Checked;
app.DiamTTimePlot.YMinorGrid = app.YMinorMenu.Checked;

% plot transit time vs. diameter plot
[xData, xBin, xScale, xLabel, xLims] = getAxisParameter(app, app.Plot3_Xaxis.Value, Data);
[yData, yBin, yScale, yLabel, yLims] = getAxisParameter(app, app.Plot3_Yaxis.Value, Data);

histogram2(app.S2NTT_Diam, xData(noiseGate), yData(noiseGate),...
    'XBinEdges',xBin, 'YBinEdges',yBin,...
    'DisplayStyle','tile')
colormap(app.S2NTT_Diam,app.Colormap) % update colormap
set(app.S2NTT_Diam,'ColorScale',app.Colorscaling,...
    'xscale',xScale,'yscale',yScale) % update colorscaling
xlabel(app.S2NTT_Diam, xLabel)
ylabel(app.S2NTT_Diam, yLabel)
xlim(app.S2NTT_Diam, xLims)
ylim(app.S2NTT_Diam, yLims)
xticks(app.S2NTT_Diam,'auto')
yticks(app.S2NTT_Diam,'auto')
app.S2NTT_Diam.Toolbar.Visible = 'off';
app.S2NTT_Diam.XGrid = app.XMajorMenu.Checked;
app.S2NTT_Diam.XMinorGrid = app.XMinorMenu.Checked;
app.S2NTT_Diam.YGrid = app.YMajorMenu.Checked;
app.S2NTT_Diam.YMinorGrid = app.YMinorMenu.Checked;

% plot diameter histogram
[xData] = getAxisParameter(app, 'Diameter', Data);
histogram(app.DiamHist, xData(noiseGate), app.DiamEdges, 'linewidth',2,...
    'DisplayStyle','stairs','edgecolor','k')
set(app.DiamHist,'xscale','linear') % update colorscaling


% plot time vs. spike-in transit time
switch Data.RPSPASS.SpikeInUsed
    case 'On'
        xData = cumsum(Data.acq_int) - (Data.acq_int/2);
        plot(app.TTTimePlot, xData, Data.SpikeInTT,'-ok','linewidth',2)
        plot(app.CVTimePlot, xData, Data.CV,'-ok','linewidth',2)
    case 'Off'
        plot(app.TTTimePlot, nan, nan)
        plot(app.CVTimePlot, nan, nan)
end

% clear plot
plot(app.TimeStatPlot, nan, nan)

xData = Data.Acqtime(2:end) - diff(Data.Acqtime)/2;
Label = [];
hold(app.TimeStatPlot,'on')
plots = [];
Sets = unique(Data.AcqID);
switch app.TotalEventsMenu.Checked
    case 'on'

        Events = nan(1,numel(Sets));
        for i = 1:numel(Sets)
            Events(i) = sum(Data.AcqID==Sets(i));
        end
        Label = [Label,{'Total Count'}];
        plots = [plots, plot(app.TimeStatPlot, xData, Events(:),'o-k','linewidth',2)];

end
switch app.MeanTotalEventsMenu.Checked
    case 'on'
        switch app.TotalEventsMenu.Checked
            case 'off'

                Sets = unique(Data.AcqID);
                Events = nan(1,numel(Sets));
                for i = 1:numel(Sets)
                    Events(i) = sum(Data.AcqID==Sets(i));
                end
        end
        yData2 = movmean(Events,ceil(sqrt(numel(Events))));
        Label = [Label,{'Moving Mean Total Count'}];
        plots = [plots, plot(app.TimeStatPlot, xData(:), yData2(:),'-r','linewidth',2)];
end

switch app.AcqVolumeMenu.Checked
    case 'on'
        Label = [Label,{'Acquisition Volume (pL)'}];
        plots = [plots, plot(app.TimeStatPlot, xData(:), Data.acqvol(:),'-b','linewidth',2)];
end

switch app.MeanAcqVolumeMenu.Checked
    case 'on'
        Label = [Label,{'Mean Acquisition Volume (pL)'}];
        yData2 = movmean(Data.acqvol(:),ceil(sqrt(numel(Data.acqvol(:)))));
        plots = [plots, plot(app.TimeStatPlot, xData(:), yData2,':r','linewidth',2)];
end

if ~isempty(plots)
    legend(app.TimeStatPlot,plots, Label,'box','on','location','southeast');
    hold(app.TimeStatPlot,'off')
end

[~, TimeBins] = getAxisParameter(app, 'Time', Data);

% time vs. stat
app.TimeStatPlot.XLim = [min(TimeBins),max(TimeBins)];
ylim(app.TimeStatPlot,'auto');
xticks(app.TimeStatPlot,'auto')
yticks(app.TimeStatPlot,'auto')
app.TimeStatPlot.Toolbar.Visible = 'off';
app.TimeStatPlot.XGrid = app.XMajorMenu.Checked;
app.TimeStatPlot.XMinorGrid = app.XMinorMenu.Checked;
app.TimeStatPlot.YGrid = app.YMajorMenu.Checked;
app.TimeStatPlot.YMinorGrid = app.YMinorMenu.Checked;

% time vs. transit time
app.TTTimePlot.XLim =  [min(TimeBins),max(TimeBins)];
ylim(app.TTTimePlot,'auto');
xticks(app.TTTimePlot,'auto')
yticks(app.TTTimePlot,'auto')
app.TTTimePlot.Toolbar.Visible = 'off';
app.TTTimePlot.XGrid = app.XMajorMenu.Checked;
app.TTTimePlot.XMinorGrid = app.XMinorMenu.Checked;
app.TTTimePlot.YGrid = app.YMajorMenu.Checked;
app.TTTimePlot.YMinorGrid = app.YMinorMenu.Checked;

% time vs. % CV
app.CVTimePlot.XLim =  [min(TimeBins),max(TimeBins)];
ylim(app.CVTimePlot,'auto');
xticks(app.CVTimePlot,'auto')
yticks(app.CVTimePlot,'auto')
app.CVTimePlot.Toolbar.Visible = 'off';
app.CVTimePlot.XGrid = app.XMajorMenu.Checked;
app.CVTimePlot.XMinorGrid = app.XMinorMenu.Checked;
app.CVTimePlot.YGrid = app.YMajorMenu.Checked;
app.CVTimePlot.YMinorGrid = app.YMinorMenu.Checked;

% SN/TT vs. % diam
app.S2NTT_Diam.XLim = [min(TimeBins),max(TimeBins)];
ylim(app.S2NTT_Diam,'auto');
xticks(app.S2NTT_Diam,'auto')
yticks(app.S2NTT_Diam,'auto')
app.S2NTT_Diam.Toolbar.Visible = 'off';
app.S2NTT_Diam.XGrid = app.XMajorMenu.Checked;
app.S2NTT_Diam.XMinorGrid = app.XMinorMenu.Checked;
app.S2NTT_Diam.YGrid = app.YMajorMenu.Checked;
app.S2NTT_Diam.YMinorGrid = app.YMinorMenu.Checked;

%  diam hist
app.DiamHist.XLim = [min(app.DiamEdges),max(app.DiamEdges)];
ylim(app.DiamHist,'auto');
xticks(app.DiamHist,'auto')
yticks(app.DiamHist,'auto')
app.DiamHist.Toolbar.Visible = 'off';
app.DiamHist.XGrid = app.XMajorMenu.Checked;
app.DiamHist.XMinorGrid = app.XMinorMenu.Checked;
app.DiamHist.YGrid = app.YMajorMenu.Checked;
app.DiamHist.YMinorGrid = app.YMinorMenu.Checked;
end