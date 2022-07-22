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


                t = tiledlayout(3,2,'TileSpacing','compact','Padding','compact');
                xData = cumsum(Data.acq_int) - (Data.acq_int/2);

                %% remove data based on separation index
                nexttile
                plot(xData, OutlierRemoval.SI, '-k')
                hold on
                plot(xData(~Best.index), OutlierRemoval.SI(~Best.index), 'o','markerfacecolor','r','MarkerEdgeColor','none','Color','k')
                plot(xData(Best.index), OutlierRemoval.SI(Best.index), 'o','markerfacecolor','b','MarkerEdgeColor','none','Color','k')
                fill([0 0 max(Bins.time) max(Bins.time)],[Best.SI(1) Best.SI(2) Best.SI(2) Best.SI(1)],'g','facealpha',0.1)
                xlabel('Time (secs)')
                ylabel('Interval Separation Index')
                xlim([0 max(Bins.time)])
                set(gca, 'fontsize',14, 'linewidth',2, 'box','on')


                %% remove data based on spike-in CV changes
                nexttile
                plot(xData, OutlierRemoval.CV, '-k')
                hold on
                plot(xData(~Best.index), OutlierRemoval.CV(~Best.index), 'o','markerfacecolor','r','MarkerEdgeColor','none','Color','k')
                plot(xData(Best.index), OutlierRemoval.CV(Best.index), 'o','markerfacecolor','b','MarkerEdgeColor','none')
                fill([0 0 max(Bins.time) max(Bins.time)],...
                    [Best.CV(1) Best.CV(2) Best.CV(2) Best.CV(1)],...
                    'g','facealpha',0.1)

                xlim([0 max(Bins.time)])
                xlabel('Time (secs)')
                ylabel('% Spike-in % CV')
                set(gca, 'fontsize',14, 'linewidth',2, 'box','on')


                nexttile
                plot(xData, OutlierRemoval.NoiseSpikeInRatio, '-k')
                hold on
                plot(xData(~Best.index), OutlierRemoval.NoiseSpikeInRatio(~Best.index), 'o','markerfacecolor','r','MarkerEdgeColor','none','Color','k')
                plot(xData(Best.index), OutlierRemoval.NoiseSpikeInRatio(Best.index), 'o','markerfacecolor','b','MarkerEdgeColor','none')
                set(gca, 'fontsize',14, 'linewidth',2, 'box','on')
                xlim([0 max(Bins.time)])
                ylabel('Noise / Spike-in events')
                xlabel('Time (secs)')

                nexttile
                colororder({'k','k'})
                plot(xData, OutlierRemoval.SpikeInTT, '-k')
                hold on
                plot(xData(~Best.index), OutlierRemoval.SpikeInTT(~Best.index), 'o','markerfacecolor','r','MarkerEdgeColor','none','Color','k')
                plot(xData(Best.index), OutlierRemoval.SpikeInTT(Best.index), 'o','markerfacecolor','b','MarkerEdgeColor','none')
                fill([0 0 max(Bins.time) max(Bins.time)],...
                    [Best.TT(1) Best.TT(2) Best.TT(2) Best.TT(1)],...
                    'g','facealpha',0.1)

                xlabel('Time (secs)')
                ylabel('Spike-in Transit Time (µs)')
                xlim([0 max(Bins.time)])
                set(gca, 'fontsize',14, 'linewidth',2, 'box','on')

                nexttile
                plot(xData, Data.SetPs(:,1), '-k')
                hold on
                plot(xData(~Best.index), Data.SetPs(~Best.index,1), 'o','markeredgecolor','r')
                plot(xData(Best.index), Data.SetPs(Best.index,1), 'o','markeredgecolor','b')
                ylabel('P1 Pressure')
                xlabel('Time (secs)')
                xlim([0 max(Bins.time)])
                ylim([0 ceil(max(Data.SetPs(:,1)))])
                set(gca, 'fontsize',14, 'linewidth',2, 'box','on')

                nexttile
                histogram2(Data.time,Data.diam,'XBinEdges',Bins.time,"YBinEdges",Bins.diam,"DisplayStyle","tile")
                hold on
                for i = 1:Data.RPSPASS.MaxInt
                    if Best.index(i) == 1
                        col = [0 0.5 0];
                    else
                        col = [0.5 0 0];
                    end
                    fill([Data.RPSPASS.AcqInt(i) Data.RPSPASS.AcqInt(i) Data.RPSPASS.AcqInt(i+1) Data.RPSPASS.AcqInt(i+1)],...
                        [min(Bins.diam) max(Bins.diam) max(Bins.diam) min(Bins.diam) ],...
                        col, 'facealpha',0.2,'EdgeColor','none')
                end

                set(gca,'GridLineStyle','none')
                xlabel('Time (seconds)')
                ylabel('RPS_{PASS} Diameter (nm)')
                xlim([0 max(Bins.time)])
                set(gca, 'fontsize',14, 'linewidth',2, 'box','on')


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