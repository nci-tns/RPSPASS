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

                Threshold.SI = 0.75;
                Threshold.CV = 2;

                t = tiledlayout(3,2,'TileSpacing','compact','Padding','compact');
                xData = cumsum(Data.acq_int) - (Data.acq_int/2);
                yData = Data.Debug.OutlierRemoval.SI;

                %% remove data based on separation index
                nexttile
                plot(xData, yData, '-o','markerfacecolor','r','MarkerEdgeColor','none','Color','k')
                hold on

                maxInd = yData==max(yData);
                plot(xData(maxInd), yData(maxInd), 'o','markerfacecolor','r','MarkerEdgeColor','none')


                threshInd = yData>=(max(yData)*Threshold.SI);
                plot(xData(threshInd), yData(threshInd), 'o','markerfacecolor','b','MarkerEdgeColor','none')
                fill([0 0 max(Bins.time) max(Bins.time)],[max(yData)*Threshold.SI max(yData) max(yData) max(yData)*Threshold.SI],'g','facealpha',0.1)


                xlabel('Time (secs)')
                ylabel('Interval Separation Index')
                xlim([0 max(Bins.time)])
                set(gca, 'fontsize',14, 'linewidth',2, 'box','on')

                yData1 = Data.Debug.OutlierRemoval.Noise;
                yData2 = Data.Debug.OutlierRemoval.SpikeIn;

                nexttile
                plot(xData, yData1, '-k','markerfacecolor','none','linewidth',2)
                hold on
                plot(xData, yData2, '-b','markerfacecolor','none','linewidth',2)
                xlabel('Time (secs)')
                ylabel('Diameter')
                xlim([0 max(Bins.time)])
                set(gca, 'fontsize',14, 'linewidth',2, 'box','on')

                %% remove data based on spike-in CV changes

                for i = 1:Data.RPSPASS.MaxInt
                    % isolate data for acquisition
                    TimeGate = Data.time >= Data.RPSPASS.AcqInt(i) & Data.time < Data.RPSPASS.AcqInt(i+1);
                    DiamCalData = Data.diam(TimeGate);

                    SpikeIn = DiamCalData(DiamCalData > Data.SpikeInGateMin(i)*Data.CaliFactor(i) & DiamCalData < Data.SpikeInGateMax(i)*Data.CaliFactor(i));

                    CVs(i) = 100*(std(SpikeIn)/mean(SpikeIn));
                end

                nexttile

                plot(xData, CVs, '-o','markerfacecolor','r','MarkerEdgeColor','none','Color','k')
                hold on
                threshCVind = CVs<=(min(CVs)+Threshold.CV);
                plot(xData(threshCVind), CVs(threshCVind), 'o','markerfacecolor','b','MarkerEdgeColor','none')
                fill([0 0 max(Bins.time) max(Bins.time)],[min(CVs)+Threshold.CV min(CVs) min(CVs) min(CVs)+Threshold.CV ],'g','facealpha',0.1)

                xlim([0 max(Bins.time)])
                xlabel('Time (secs)')
                ylabel('% Spike In CV')
                set(gca, 'fontsize',14, 'linewidth',2, 'box','on')

                nexttile
                axis off


                nexttile
                histogram2(Data.time,Data.diam,'XBinEdges',Bins.time,"YBinEdges",Bins.diam,"DisplayStyle","tile")
                set(gca,'GridLineStyle','none')
                xlabel('Time (seconds)')
                ylabel('RPS_{PASS} Diameter (nm)')
                xlim([0 max(Bins.time)])
                set(gca, 'fontsize',14, 'linewidth',2, 'box','on')

                cumvol = cumsum(Data.acq_int);
                timgate = false(size(Data.AcqID));
                AcqIDind = unique(find(and(threshInd(:), threshCVind(:))));

                for i = 1:numel(AcqIDind)
                    timgate = or(timgate, (Data.AcqID(:)==AcqIDind(i)));
                end

                nexttile
                histogram2(Data.time(timgate),Data.diam(timgate),'XBinEdges',Bins.time,"YBinEdges",Bins.diam,"DisplayStyle","tile")
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