function []=Debug_Plots(Data, PlotType)

% check debug field exists
if isfield(Data, 'Debug')
    switch PlotType
        case 'PeakFind'
            % check if debug data exists
            if isfield(Data.Debug, 'PeakFind')

                fig = figure('visible','off');
                fig.Units = 'centimeters';
                fig.Position = [0 0 42 59.4];
                fig.PaperUnits = 'centimeters';
                fig.PaperSize = [42 59.4];
                fig.PaperUnits = 'normalized';
                fig.PaperPosition = [0 0 1 1];

                t = tiledlayout('flow','TileSpacing','compact','Padding','compact');

                for i = 1:numel(Data.Debug.PeakFind.bincent)

                    nexttile
                    xData = Data.Debug.PeakFind.bincent{i};
                    yData = Data.Debug.PeakFind.M{i};

                    if ~isempty(xData) || ~isempty(yData)
                        PeakPos = Data.Debug.PeakFind.lk{i};
                        Threshold = Data.Debug.PeakFind.CountThreshold{i};
                        SelectPeak = Data.Debug.PeakFind.SelectedPeak{i};

                        plot(xData, yData,'-k','linewidth',2)
                        hold on
                        plot(xData(PeakPos), yData(PeakPos),'ob','linewidth',2,'markerfacecolor','b','MarkerEdgeColor','none')
                        plot(xData(SelectPeak), yData(SelectPeak),'or','linewidth',2,'markerfacecolor','r','MarkerEdgeColor','none')
                        plot([min(xData) max(xData)], [Threshold Threshold],':r','linewidth',2)

                        xlim([min(xData) max(xData)])
                        set(gca,'fontsize',14,'box','on','linewidth',2)
                        xtickangle(90)
                    else

                    end
                end

                xlabel(t,'diameter [nm]')
                ylabel(t,'count [nm]')
            end

        case 'OutlierRemoval'
            % check if debug data exists
            if isfield(Data.Debug, 'OutlierRemoval')

                OutlierRemoval = Data.Debug.OutlierRemoval;
                Best = Data.Debug.OutlierRemoval.Best;

                fig = figure('visible','off');
                fig.Units = 'centimeters';
                fig.Position = [0 0 21 29.7];
                fig.PaperUnits = 'centimeters';
                fig.PaperSize = [21 29.7];
                fig.PaperUnits = 'normalized';
                fig.PaperPosition = [0 0 1 1];


                res = 256;
                Bins.time = linspace(min(Data.time),max(Data.time),res);
                Bins.diam = linspace(0,400,res);
                Bins.ttime = linspace(0,100,res);
                Bins.TTSN = logspace(-2,2,res);

                t = tiledlayout(3,2,'TileSpacing','compact','Padding','compact');
                xData = cumsum(Data.acq_int) - (Data.acq_int/2);

                %% remove data based on separation index
                nexttile
                plot(xData, OutlierRemoval.SI, '-k') % show raw data

                if ~Best.num == 0
                    hold on
                    plot(xData(~Best.index), OutlierRemoval.SI(~Best.index), 'o','markerfacecolor','r','MarkerEdgeColor','none','Color','k') % show outliers
                    plot(xData(Best.index), OutlierRemoval.SI(Best.index), 'o','markerfacecolor','b','MarkerEdgeColor','none','Color','k') % show kept events
                    fill([0 0 max(Bins.time) max(Bins.time)],[min(Best.SI) max(Best.SI) max(Best.SI) min(Best.SI)],'g','facealpha',0.1) % show SI gate
                end

                formatPlot('Interval Separation Index',[], Bins.time)

                %% remove data based on spike-in CV changes
                nexttile
                plot(xData, OutlierRemoval.CV, '-k') % show raw data

                if ~Best.num == 0
                    hold on
                    plot(xData(~Best.index), OutlierRemoval.CV(~Best.index), 'o','markerfacecolor','r','MarkerEdgeColor','none','Color','k') % show outliers
                    plot(xData(Best.index), OutlierRemoval.CV(Best.index), 'o','markerfacecolor','b','MarkerEdgeColor','none') % show kept events
                    fill([0 0 max(Bins.time) max(Bins.time)],[min(Best.CV) max(Best.CV) max(Best.CV) min(Best.CV)],'g','facealpha',0.1) % show SI gate
                end

                formatPlot('% Spike-in % CV',[],Bins.time)

                %% remove data based on spike-in / noise ratio changes
                nexttile
                plot(xData, OutlierRemoval.NoiseSpikeInRatio, '-k') % show raw data

                if ~Best.num == 0
                    hold on
                    plot(xData(~Best.index), OutlierRemoval.NoiseSpikeInRatio(~Best.index), 'o','markerfacecolor','r','MarkerEdgeColor','none','Color','k') % show outliers
                    plot(xData(Best.index), OutlierRemoval.NoiseSpikeInRatio(Best.index), 'o','markerfacecolor','b','MarkerEdgeColor','none') % show kept events
                end

                formatPlot('Particle Events / Spike-in events',[], Bins.time)

                %% remove data based on spike-in transit time changes

                nexttile
                colororder({'k','k'})
                yyaxis left
                plot(xData, OutlierRemoval.SpikeInTT, '-k') % show raw data
                if ~Best.num == 0
                    hold on
                    plot(xData(~Best.index), OutlierRemoval.SpikeInTT(~Best.index), 'o','markerfacecolor','r','MarkerEdgeColor','none','Color','k') % show outliers
                    plot(xData(Best.index), OutlierRemoval.SpikeInTT(Best.index), 'o','markerfacecolor','b','MarkerEdgeColor','none') % show kept events
                    fill([0 0 max(Bins.time) max(Bins.time)],[min(Best.TT) max(Best.TT) max(Best.TT) min(Best.TT)],'g','facealpha',0.1) % show SI gate
                end

                formatPlot('Spike-in Transit Time (µs)',[], Bins.time)

                yyaxis right
                % remove data based on P1 set pressure changes
                plot(xData, Data.SetPs(:,1), '-k') % show raw data
                if ~Best.num == 0
                    hold on
                    plot(xData(~Best.index), Data.SetPs(~Best.index,1), 'o','markeredgecolor','r') % show outliers
                    plot(xData(Best.index), Data.SetPs(Best.index,1), 'o','markeredgecolor','k')
                end

                formatPlot('P1 Pressure', [0 ceil(max(Data.SetPs(:,1)))], Bins.time)

                %% show noise event removal gate
                nexttile
                histogram2(Data.TT2SN,Data.diam,'XBinEdges',Bins.TTSN,"YBinEdges",Bins.diam,"DisplayStyle","tile")
                hold on
                fill(10.^[-2 -2 0 0],...
                    [min(Bins.diam) max(Bins.diam) max(Bins.diam) min(Bins.diam)], [0.5 0 0], 'facealpha',0.2,'EdgeColor','none')
                
                fill(10.^([0 0 2 2]),...
                    [min(Bins.diam) max(Bins.diam) max(Bins.diam) min(Bins.diam)], [0 0.5 0], 'facealpha',0.2,'EdgeColor','none')
                formatPlot('',[],Bins.TTSN)
                set(gca,'xscale','log')
                ylabel('RPS_{PASS} Diameter (nm)')
                xlabel('Signal:Noise / Transit Time')

                %% show raw events with overlay of keep/remove gates
                nexttile
                histogram2(Data.time(~Data.NoiseInd),Data.diam(~Data.NoiseInd),'XBinEdges',Bins.time,"YBinEdges",Bins.diam,"DisplayStyle","tile")
                hold on
                for i = 1:Data.RPSPASS.MaxInt
                    if Best.index(i) == 1
                        col = [0 0.5 0];
                    else
                        col = [0.5 0 0];
                    end
                    fill([Data.RPSPASS.AcqInt(i) Data.RPSPASS.AcqInt(i) Data.RPSPASS.AcqInt(i+1) Data.RPSPASS.AcqInt(i+1)],...
                        [min(Bins.diam) max(Bins.diam) max(Bins.diam) min(Bins.diam) ], col, 'facealpha',0.2,'EdgeColor','none')
                end

                formatPlot('RPS_{PASS} Diameter (nm)',[],Bins.time)

            end
    end
end

% if figure exists
if exist('fig','var') == 1

    % get output directory and filename information
    outputDir = getprefRPSPASS('RPSPASS','OutputDir');
    outputPath = fullfile(outputDir,'Debug',PlotType);
    Filename = getprefRPSPASS('RPSPASS','CurrFile');

    % make export directory if it does not exist
    if ~isfolder(outputPath)
        mkdir(outputPath)
    end

    % export figure
    print(fig,fullfile(outputPath,[Filename,'.png']), '-dpng', '-r300');

    % close figure
    close(fig)
end

end

function formatPlot(ylabelStr,ylims, Bins)
xlabel('Time (seconds)')
ylabel(ylabelStr)
xlim([0 max(Bins)])
if ~isempty(ylims)
    ylim(ylims)
end

set(gca, 'fontsize',14, 'linewidth',2, 'box','on','GridLineStyle','none')


end