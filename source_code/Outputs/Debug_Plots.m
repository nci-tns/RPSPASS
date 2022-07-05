function []=Debug_Plots(Data, PlotType, FileID)

switch PlotType

    case 'PeakFind'
        fig = figure('visible','off');

        fig.Units = 'centimeters';
        fig.Position = [0 0 42 59.4];
        fig.PaperUnits = 'centimeters';
        fig.PaperSize = [42 59.4];
        fig.PaperUnits = 'normalized';
        fig.PaperPosition = [0 0 1 1];

        t = tiledlayout('flow','TileSpacing','compact','Padding','compact');

        for i = 1:Data.RPSPASS.MaxInt
            nexttile
            xData = Data.Debug.PeakFind.bincent{i};
            yData = Data.Debug.PeakFind.M{i};
            PeakPos = Data.Debug.PeakFind.lk{i};
            Threshold = Data.Debug.PeakFind.CountThreshold{i};

            plot(xData, yData,'-k','linewidth',2)
            hold on
            plot(xData(PeakPos), yData(PeakPos),'ob','linewidth',2)
            plot([min(xData) max(xData)], [Threshold Threshold],':r','linewidth',2)

            xlim([min(xData) max(xData)])
            set(gca,'fontsize',14,'box','on','linewidth',2)
            xtickangle(90)
        end

        xlabel(t,'diameter [nm]')
        ylabel(t,'count [nm]')

end




outputDir = getprefRPSPASS('RPSPASS','OutputDir');
outputPath = fullfile(outputDir,'Debug',PlotType);
Filename = getprefRPSPASS('RPSPASS','CurrFile');


if ~isfolder(outputPath)
    mkdir(outputPath)
end

print(fig,fullfile(outputPath,[Filename,'.png']), '-dpng', '-r300');

close(fig)
end