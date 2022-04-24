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

% plot time vs. diameter plot
histogram2(app.DiamTimePlot, Data.time, Data.non_norm_d,...
    'XBinEdges',app.TimeEdges, 'YBinEdges',app.DiamEdges,...
    'DisplayStyle','tile')
colormap(app.DiamTimePlot,app.Colormap) % update colormap
set(app.DiamTimePlot,'ColorScale',app.Colorscaling) % update colorscaling

% plot transit time vs. diameter plot
histogram2(app.DiamTTimePlot, Data.ttime, Data.non_norm_d,...
    'XBinEdges',app.TTimeEdges, 'YBinEdges',app.DiamEdges,...
    'DisplayStyle','tile')
colormap(app.DiamTTimePlot,app.Colormap) % update colormap
set(app.DiamTTimePlot,'ColorScale',app.Colorscaling) % update colorscaling


plot(app.TimeStatPlot, nan, nan)

Sets = unique(Data.AcqID);
xData = (Sets.*Data.acq_int)-(Data.acq_int./2);
Label = [];
hold(app.TimeStatPlot,'on')
plots = [];
switch app.TotalEventsMenu.Checked
    case 'on'

        Events = nan(1,numel(Sets));
        for i = 1:numel(Sets)
            Events(i) = sum(Data.AcqID==Sets(i));
        end
        Label = [Label,{'Total Count'}];
        plots = [plots, plot(app.TimeStatPlot, xData(:), Events(:),'o-k','linewidth',2)];

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

legend(app.TimeStatPlot,plots, Label,'box','on','location','southeast');
hold(app.TimeStatPlot,'off')

end