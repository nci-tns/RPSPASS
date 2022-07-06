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