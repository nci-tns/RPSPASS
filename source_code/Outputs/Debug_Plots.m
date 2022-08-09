function []=Debug_Plots(Data, PlotType)
% if debug mode is turned on, create an output directory
switch getprefRPSPASS('RPSPASS','debugSelected')
    case 'on'
        % check debug field exists
        if isfield(Data, 'Debug')
            switch PlotType
                case 'PeakFind'
                    % check if debug data exists
                    if isfield(Data.Debug, 'PeakFind')

                        rows = 9;
                        cols = 5;
                        figNo = ceil(numel(Data.Debug.PeakFind.bincent)/(rows*cols)); % calculate number of figures required
                        fig = gobjects(1,figNo); % prealocate figures
                        t = gobjects(1,figNo); % prealocate tiledlayout
                        for i = 1:figNo
                            % create figure output properties
                            fig(i) = figure('visible','off');
                            fig(i).Units = 'centimeters';
                            fig(i).Position = [0 0 21 29.7];
                            fig(i).PaperUnits = 'centimeters';
                            fig(i).PaperSize = [21 29.7];
                            fig(i).PaperUnits = 'normalized';
                            fig(i).PaperPosition = [0 0 1 1];
                            fig(i).OuterPosition = [0 0 21 29.7];

                            t(i) = tiledlayout(rows,cols,'TileSpacing','compact','Padding','compact');

                        end

                        % create nexttile index to plot across figure
                        % handles
                        plotInd = repmat(1:ceil(numel(Data.Debug.PeakFind.bincent)/(rows*cols)),rows*cols,1);
                        plotInd = plotInd(:);

                        % plot each peak find histogram in loop
                        for i = 1:numel(Data.Debug.PeakFind.bincent)

                            nexttile(t(plotInd(i)))
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
                                set(gca,'box','on','linewidth',2)
                                xtickangle(90)
                            else
                                axis off
                            end

                        end

                        for i = 1:ceil(numel(Data.Debug.PeakFind.bincent)/(rows*cols))

                            xlabel(t(i),'Diameter [nm]','fontsize',14)
                            ylabel(t(i),'Count [nm]','fontsize',14)
                            title(t(i),'Spike-in identification QC','fontsize',14)

                        end

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
                        fig.OuterPosition = [0 0 21 29.7];


                        res = 256;
                        Bins.time = linspace(min(Data.time),max(Data.time),res);
                        Bins.diam = linspace(0,400,res);
                        Bins.ttime = linspace(0,100,res);
                        Bins.TTSN = logspace(-2,2,res);

                        t = tiledlayout(4,3,'TileSpacing','compact','Padding','compact');
                        xData = cumsum(Data.acq_int) - (Data.acq_int/2);

                        %% remove data based on separation index
                        nexttile
                        plot(xData, OutlierRemoval.SI, '-k') % show raw data


                        if ~Best.num == 0
                            hold on
                            plot(xData(~Best.index), OutlierRemoval.SI(~Best.index), 'o','markerfacecolor','r','MarkerEdgeColor','none','Color','k') % show outliers
                            plot(xData(Best.index), OutlierRemoval.SI(Best.index), 'o','markerfacecolor','b','MarkerEdgeColor','none','Color','k') % show kept events
                            % check if SI outlier removal is turned on
                            if getprefRPSPASS('RPSPASS','OutlierRemoval_SI') == 1
                                fill([0 0 max(Bins.time) max(Bins.time)],[Best.SI repmat(Best.SI++getprefRPSPASS('RPSPASS','Threshold_SpikeIn_SI'),1,2) Best.SI],'g','facealpha',0.1) % show SI gate
                            end
                        end

                        formatPlot('Interval Separation Index',[], Bins.time)

                        %% remove data based on spike-in CV changes
                        nexttile
                        plot(xData, OutlierRemoval.CV, '-k') % show raw data

                        if ~Best.num == 0
                            hold on
                            plot(xData(~Best.index), OutlierRemoval.CV(~Best.index), 'o','markerfacecolor','r','MarkerEdgeColor','none','Color','k') % show outliers
                            plot(xData(Best.index), OutlierRemoval.CV(Best.index), 'o','markerfacecolor','b','MarkerEdgeColor','none') % show kept events
                            % check if CV outlier removal is turned on
                            if getprefRPSPASS('RPSPASS','OutlierRemoval_CV') == 1
                                fill([0 0 max(Bins.time) max(Bins.time)],[Best.CV repmat(Best.CV++getprefRPSPASS('RPSPASS','Threshold_SpikeIn_CV'),1,2) Best.CV],'g','facealpha',0.1) % show SI gate
                            end
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

                        formatPlot('Particles No. / Spike-in No.',[], Bins.time)

                        %% remove data based on spike-in transit time changes

                        nexttile
                        plot(xData, OutlierRemoval.SpikeInTT, '-k') % show raw data
                        if ~Best.num == 0
                            hold on
                            plot(xData(~Best.index), OutlierRemoval.SpikeInTT(~Best.index), 'o','markerfacecolor','r','MarkerEdgeColor','none','Color','k') % show outliers
                            plot(xData(Best.index), OutlierRemoval.SpikeInTT(Best.index), 'o','markerfacecolor','b','MarkerEdgeColor','none') % show kept events
                            % check if TT outlier removal is turned on
                            if getprefRPSPASS('RPSPASS','OutlierRemoval_TransitTime') == 1
                                fill([0 0 max(Bins.time) max(Bins.time)],[Best.TT repmat(Best.TT++getprefRPSPASS('RPSPASS','Threshold_SpikeIn_TT'),1,2) Best.TT],'g','facealpha',0.1) % show SI gate
                            end
                        end
                        formatPlot('Spike-in Transit Time (µs)',[], Bins.time)


                        %% remove data based on spike-in transit time / signal 2 noise changes

                        nexttile
                        plot(xData, OutlierRemoval.SpikeInTT2SN, '-k') % show raw data
                        if ~Best.num == 0
                            hold on
                            plot(xData(~Best.index), OutlierRemoval.SpikeInTT2SN(~Best.index), 'o','markerfacecolor','r','MarkerEdgeColor','none','Color','k') % show outliers
                            plot(xData(Best.index), OutlierRemoval.SpikeInTT2SN(Best.index), 'o','markerfacecolor','b','MarkerEdgeColor','none') % show kept events
                            % check if TTSN outlier removal is turned on
                            if getprefRPSPASS('RPSPASS','OutlierRemoval_TTSN') == 1
                                fill([0 0 max(Bins.time) max(Bins.time)],[Best.TTSN repmat(Best.TTSN++getprefRPSPASS('RPSPASS','Threshold_SpikeIn_TTSN'),1,2) Best.TTSN],'g','facealpha',0.1) % show SI gate
                            end
                        end
                        formatPlot('Signal:Noise / Transit Time',[], Bins.time)

                        %% remove data based on P1 set pressure changes
                        nexttile
                        plot(xData, Data.SetPs(:,1), '-k') % show raw data
                        if ~Best.num == 0
                            hold on
                            plot(xData(~Best.index), Data.SetPs(~Best.index,1), 'o','markeredgecolor','r') % show outliers
                            plot(xData(Best.index), Data.SetPs(Best.index,1), 'o','markeredgecolor','k')
                        end

                        % stop default 3.5 pressure data overlapping with
                        % plot label
                        if min(Data.SetPs(:,1)) < 4
                            ylim([0 5])
                        end
                        formatPlot('P1 Pressure', [0 ceil(max(Data.SetPs(:,1)))], Bins.time)

                        %% show raw transit time / signal 2 noise vs diameter
                        nexttile
                        histogram2(Data.TT2SN,Data.diam,'XBinEdges',Bins.TTSN,"YBinEdges",Bins.diam,"DisplayStyle","tile")
                        hold on
                        fill(10.^[-2 -2 0 0],...
                            [min(Bins.diam) max(Bins.diam) max(Bins.diam) min(Bins.diam)], [0.5 0 0], 'facealpha',0.2,'EdgeColor','none')

                        fill(10.^([0 0 2 2]),...
                            [min(Bins.diam) max(Bins.diam) max(Bins.diam) min(Bins.diam)], [0 0.5 0], 'facealpha',0.2,'EdgeColor','none')
                        text(10^(-2+(4*0.95)), (max(Bins.diam)-min(Bins.diam))*0.9,'All Events','FontWeight','bold','HorizontalAlignment','right')
                        formatPlot('',[],Bins.TTSN)
                        set(gca,'xscale','log')
                        ylabel('RPS_{PASS} Diameter (nm)')
                        xlabel('Signal:Noise / Transit Time')

                        %% show outlier removed transit time / signal 2 noise vs diameter
                        nexttile
                        histogram2(Data.TT2SN(~Data.outliers),Data.diam(~Data.outliers),'XBinEdges',Bins.TTSN,"YBinEdges",Bins.diam,"DisplayStyle","tile")
                                                hold on
                        fill(10.^[-2 -2 0 0],...
                            [min(Bins.diam) max(Bins.diam) max(Bins.diam) min(Bins.diam)], [0.5 0 0], 'facealpha',0.2,'EdgeColor','none')
                        fill(10.^([0 0 2 2]),...
                            [min(Bins.diam) max(Bins.diam) max(Bins.diam) min(Bins.diam)], [0 0.5 0], 'facealpha',0.2,'EdgeColor','none')
                        text(10^(-2+(4*0.95)),(max(Bins.diam)-min(Bins.diam))*0.9,'Outlers Removed','FontWeight','bold','HorizontalAlignment','right')
                        formatPlot('',[],Bins.TTSN)
                        set(gca,'xscale','log')
                        ylabel('RPS_{PASS} Diameter (nm)')
                        xlabel('Signal:Noise / Transit Time')

                        %% show histogram of signal 2 noise vs diameter
                        nexttile
                        histogram2(Data.TT2SN(~Data.outliers),Data.diam(~Data.outliers),'XBinEdges',Bins.TTSN,"YBinEdges",Bins.diam,"DisplayStyle","tile")
                                                hold on
                        fill(10.^[-2 -2 2 2],...
                            [min(Bins.diam) Data.Threshold.diam Data.Threshold.diam min(Bins.diam)], [0.5 0 0], 'facealpha',0.2,'EdgeColor','none')
                        
                        fill(10.^[-2 -2 log10([0.5 0.5])],...
                            [Data.Threshold.diam max(Bins.diam) max(Bins.diam) Data.Threshold.diam], [0.5 0 0], 'facealpha',0.2,'EdgeColor','none')
                        
                        fill(10.^([log10([0.5 0.5]) 2 2]),...
                            [Data.Threshold.diam max(Bins.diam) max(Bins.diam) Data.Threshold.diam], [0 0.5 0], 'facealpha',0.2,'EdgeColor','none')
                        
                        text(10^(-2+(4*0.95)),(max(Bins.diam)-min(Bins.diam))*0.9,'Outlers Removed','FontWeight','bold','HorizontalAlignment','right')
                        formatPlot('',[],Bins.TTSN)
                        set(gca,'xscale','log')
                        ylabel('RPS_{PASS} Diameter (nm)')
                        xlabel('Signal:Noise / Transit Time')

                        %% show raw time vs. transit time / signal 2 noise
                        nexttile
                        histogram2(Data.time,Data.TT2SN,'XBinEdges',Bins.time,"YBinEdges",Bins.TTSN,"DisplayStyle","tile")
                        hold on
                        for i = 1:Data.RPSPASS.MaxInt
                            if Best.index(i) == 1
                                fill([Data.RPSPASS.AcqInt(i) Data.RPSPASS.AcqInt(i) Data.RPSPASS.AcqInt(i+1) Data.RPSPASS.AcqInt(i+1)], ...
                                    10.^([0 2 2 0]),[0 0.5 0],'facealpha',0.2,'EdgeColor','none')
                                fill([Data.RPSPASS.AcqInt(i) Data.RPSPASS.AcqInt(i) Data.RPSPASS.AcqInt(i+1) Data.RPSPASS.AcqInt(i+1)], ...
                                    10.^([0 -2 -2 0]),[0.5 0 0],'facealpha',0.2,'EdgeColor','none')
                            else
                                fill([Data.RPSPASS.AcqInt(i) Data.RPSPASS.AcqInt(i) Data.RPSPASS.AcqInt(i+1) Data.RPSPASS.AcqInt(i+1)],...
                                    10.^([2 -2 -2 2]), [0.5 0 0], 'facealpha',0.2,'EdgeColor','none')
                            end
                        end
                        text((Data.RPSPASS.AcqInt(Data.RPSPASS.MaxInt))*.95, 10^(-2+(4*0.9)),'All Events','FontWeight','bold','HorizontalAlignment','right')

                        set(gca,'yscale','log')
                        grid off
                        formatPlot('Signal:Noise / Transit Time',[],Bins.time)


                        %% show raw events with overlay of keep/remove gates
                        nexttile
                        histogram2(Data.time(Data.Indices.NoiseInd),Data.diam(Data.Indices.NoiseInd),'XBinEdges',Bins.time,"YBinEdges",Bins.diam,"DisplayStyle","tile")
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
                        text((Data.RPSPASS.AcqInt(Data.RPSPASS.MaxInt))*.95, (max(Bins.diam)-min(Bins.diam))*0.9,'Noise Events','FontWeight','bold','HorizontalAlignment','right')
                        formatPlot('RPS_{PASS} Diameter (nm)',[],Bins.time)

                        nexttile
                        histogram2(Data.time(~Data.Indices.NoiseInd),Data.diam(~Data.Indices.NoiseInd),'XBinEdges',Bins.time,"YBinEdges",Bins.diam,"DisplayStyle","tile")
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
                        text((Data.RPSPASS.AcqInt(Data.RPSPASS.MaxInt))*.95, (max(Bins.diam)-min(Bins.diam))*0.9,'Noise Removed','FontWeight','bold','HorizontalAlignment','right')
                        formatPlot('RPS_{PASS} Diameter (nm)',[],Bins.time)

                        jf=java.text.DecimalFormat; % comma for thousands, three decimal places
                        IterationStr = char(jf.format(Best.NoCombs));

                        % add title
                        title(t,['Outlier Removal QC, ',IterationStr,' Iterations Tested'],'fontsize',14)

                        LabelSubplots(t, '', '')

                    end
            end
        end 

        % if figure exists
        if exist('fig','var') == 1

            FigNo = numel(fig);
            % get output directory and filename information
            outputDir = getprefRPSPASS('RPSPASS','OutputDir');
            outputPath = fullfile(outputDir,'QC Plots');
            Filename = getprefRPSPASS('RPSPASS','CurrFile');

            % make export directory if it does not exist
            if ~isfolder(outputPath)
                mkdir(outputPath)
            end

            for i = 1:FigNo
                Full_filename = fullfile(outputPath,[replace(Filename,'.','-'),'.pdf']);

                % make export directory if it does not exist
                if ~isfolder(outputPath)
                    mkdir(outputPath)
                end

                % check if a debug export has been written, if it has append the file.
                if ~isfile(Full_filename)
                    exportgraphics(fig(i),Full_filename,'BackgroundColor','white','ContentType','vector','Resolution',300)
                else
                    exportgraphics(fig(i),Full_filename,'BackgroundColor','white','ContentType','vector','append',true,'Resolution',300)
                end
            end

            close(fig)
        end
end
end


function formatPlot(ylabelStr,ylims, Bins)
xlabel('Time (seconds)')
ylabel(ylabelStr)
xlim([0 max(Bins)])
if ~isempty(ylims)
    ylim(ylims)
end

set(gca, 'fontsize',12, 'linewidth',2, 'box','on','GridLineStyle','none')


end