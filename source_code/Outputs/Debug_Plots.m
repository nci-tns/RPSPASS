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

                OutlierRemoval.NoiseSpikeInRatio(isinf(OutlierRemoval.NoiseSpikeInRatio)) = nan;

                t = tiledlayout(3,2,'TileSpacing','compact','Padding','compact');
                xData = cumsum(Data.acq_int) - (Data.acq_int/2);

                %% remove data based on separation index
                nexttile
                plot(xData, OutlierRemoval.SI, 'o','markerfacecolor','r','MarkerEdgeColor','none','Color','k')
                hold on
                plot(xData(OutlierRemoval.SI_thresh), OutlierRemoval.SI(OutlierRemoval.SI_thresh), 'o','markerfacecolor','b','MarkerEdgeColor','none')
                plot(xData, movmean(OutlierRemoval.SI,5), '-k','linewidth',2)
                %                 fill([0 0 max(Bins.time) max(Bins.time)],[max(yData)*Threshold.SI max(yData) max(yData) max(yData)*Threshold.SI],'g','facealpha',0.1)

                xlabel('Time (secs)')
                ylabel('Interval Separation Index')
                xlim([0 max(Bins.time)])
                set(gca, 'fontsize',14, 'linewidth',2, 'box','on')


                NoiseDiam = sort(OutlierRemoval.Noise,'ascend');
                NoiseDiamThresh = (1.1*mean(NoiseDiam(1:3)));
                NoiseDiamInd = OutlierRemoval.Noise>NoiseDiamThresh;

                nexttile
                plot(xData, OutlierRemoval.Noise, '-k','markerfacecolor','none','linewidth',2)
                hold on
                plot(xData(NoiseDiamInd), OutlierRemoval.Noise(NoiseDiamInd), '.','markerfacecolor','r')
                plot([0 max(Bins.time)],[NoiseDiamThresh NoiseDiamThresh],':r','linewidth',2)
                xlabel('Time (secs)')
                ylabel('Median Noise (nm)')
                xlim([0 max(Bins.time)])
                set(gca, 'fontsize',14, 'linewidth',2, 'box','on')

                %% remove data based on spike-in CV changes
                nexttile
                plot(xData, OutlierRemoval.CV, '-o','markerfacecolor','r','MarkerEdgeColor','none','Color','k')
                hold on
                plot(xData(OutlierRemoval.CV_thresh), OutlierRemoval.CV(OutlierRemoval.CV_thresh), 'o','markerfacecolor','b','MarkerEdgeColor','none')
                fill([0 0 max(Bins.time) max(Bins.time)],...
                    [OutlierRemoval.CV_min OutlierRemoval.CV_max OutlierRemoval.CV_max OutlierRemoval.CV_min ],...
                    'g','facealpha',0.1)

                xlim([0 max(Bins.time)])
                xlabel('Time (secs)')
                ylabel('% Spike-in % CV')
                set(gca, 'fontsize',14, 'linewidth',2, 'box','on')

                nexttile
                plot(xData, OutlierRemoval.NoiseSpikeInRatio, '-o','markerfacecolor','k','MarkerEdgeColor','none','Color','k')
                hold on
                plot(xData, movmean(OutlierRemoval.NoiseSpikeInRatio,5), '-r','Color','r','linewidth',2)
                legend({'Raw Events','Moving Mean Events'},'location','northeast','box','off')
                xlim([0 max(Bins.time)])

                maxY = round(max([OutlierRemoval.NoiseSpikeInRatio]) / 0.8, -floor(log10(max([OutlierRemoval.NoiseSpikeInRatio]))));
                minY = round(floor(min([OutlierRemoval.NoiseSpikeInRatio]) / 1.2), -floor(log10(min([OutlierRemoval.NoiseSpikeInRatio]))));
                ylim([minY maxY])
                xlabel('Time (secs)')
                ylabel('Noise / Spike In Events')
                set(gca, 'fontsize',14, 'linewidth',2, 'box','on')

                nexttile
                colororder({'k','k'})
                yyaxis left
                plot(xData, OutlierRemoval.SpikeInTT, '-ok','markerfacecolor','none','linewidth',2)
                xlabel('Time (secs)')
                ylabel('Spike-in Transit Time (µs)')
                xlim([0 max(Bins.time)])
                set(gca, 'fontsize',14, 'linewidth',2, 'box','on')
                yyaxis right
                plot(xData, Data.SetPs(:,1), '-ob','markerfacecolor','none','linewidth',2)
                ylabel('P1 Pressure')


                nexttile
                histogram2(Data.time,Data.diam,'XBinEdges',Bins.time,"YBinEdges",Bins.diam,"DisplayStyle","tile")
                hold on
                for i = 1:Data.RPSPASS.MaxInt
                    if Data.RPSPASS.FailedAcq(i) == 1
                        col = [0.5 0 0];
                    else
                        col = [0 0.5 0];
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