function UpdateLivePlots(app, Data)

% update the maximum time
if app.TimeMax < max(Data.time)
    app.TimeMax = max(Data.time);
elseif app.TimeMax > max(Data.time)
    if max(Data.time) > 100
        app.TimeMax = max(Data.time);
    else
        app.TimeMax = 100;
    end

end

% update axis plotting preferences
UpdatePlottingPrefs(app)

% create gate for noise
switch app.RemovenoiseMenu.Checked
    case "off"
        noiseGate = true(size(Data.diam));
    case "on"
        noiseGate = Data.TT2SN > 1;
end

% if spike-in is being used, swtich to calibrated data
switch Data.RPSPASS.SpikeInUsed
    case 'On'
        DiamData = Data.diam(noiseGate);
    case 'Off'
        DiamData = Data.non_norm_d(noiseGate);
end

% plot time vs. diameter plot
histogram2(app.DiamTimePlot, Data.time(noiseGate), DiamData,...
    'XBinEdges',app.TimeEdges, 'YBinEdges',app.DiamEdges,...
    'DisplayStyle','tile')
colormap(app.DiamTimePlot,app.Colormap) % update colormap
set(app.DiamTimePlot,'ColorScale',app.Colorscaling) % update colorscaling


% plot S2N/transit time vs. diameter plot
histogram2(app.DiamTTimePlot, Data.ttime(noiseGate), DiamData,...
    'XBinEdges',app.TTimeEdges, 'YBinEdges',app.DiamEdges,...
    'DisplayStyle','tile')
colormap(app.DiamTTimePlot,app.Colormap) % update colormap
set(app.DiamTTimePlot,'ColorScale',app.Colorscaling) % update colorscaling

% plot transit time vs. diameter plot
histogram2(app.S2NTT_Diam, Data.TT2SN(noiseGate), DiamData,...
    'XBinEdges',app.S2NTTEdges, 'YBinEdges',app.DiamEdges,...
    'DisplayStyle','tile')
colormap(app.S2NTT_Diam,app.Colormap) % update colormap
set(app.S2NTT_Diam,'ColorScale',app.Colorscaling,'xscale','log') % update colorscaling

% plot diameter histogram
histogram(app.DiamHist, DiamData,app.DiamEdges, 'linewidth',2,...
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

end