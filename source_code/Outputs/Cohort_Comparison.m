function [] = Cohort_Comparison(app, Set, Filenames)

% create figure
fig = figure('visible','off');
fig.Units = 'centimeters';
fig.Position = [0 0 21.0 29.7];
fig.PaperUnits = 'centimeters';
fig.PaperSize = [21.0 29.7];
fig.PaperUnits = 'normalized';
fig.PaperPosition = [0 0 1 1];

td = tiledlayout(2,1,"TileSpacing","compact","Padding","compact");

SpaceFactor = 10;

% create empty arrays for aggregation
xData = [];
yData = [];
xData_Stat = [];
yData_Stat = [];


for i = 1:numel(Set)
    if isfield(Set{i},'Cohort_Events_OutliersSpikeinRemoved')
        xData = [xData; randn(numel(Set{i}.Cohort_Events_OutliersSpikeinRemoved.Conc.Raw),1) + (i*SpaceFactor)];
        switch app.SpikeInUsed
            case 'Yes'
                % concetratraion reporting
                if isempty(app.SpikeInConc)
                    ConcCalFactor_IndGate = 1; % if spike concentration not used
                else
                    ConcCalFactor_IndGate = Set{i}.SpikeIn_OutlierRemoved.Conc.Mean/app.SpikeInConc;
                end
                temp = Set{i}.Cohort_Events_OutliersSpikeinRemoved.Conc.Raw(:)./ConcCalFactor_IndGate;
                yData = [yData; temp];
            case 'No'
                temp = Set{i}.Cohort_Events_OutliersSpikeinRemoved.Conc.Raw(:);
                yData = [yData; temp];
        end
    end
    temp_stat = mean(temp);
    xData_Stat = [xData_Stat; (i*SpaceFactor)-SpaceFactor; (i*SpaceFactor)-SpaceFactor/4; (i*SpaceFactor)+SpaceFactor/4; (i*SpaceFactor)+SpaceFactor];
    yData_Stat = [yData_Stat; nan; temp_stat; temp_stat; nan];
end

nexttile
plot(xData, yData,'ok','MarkerFaceColor','k')
hold on
plot(xData_Stat, yData_Stat,'-r','linewidth',2)
set(gca,'yscale','log','box','on','linewidth',2,'fontsize',14)
xticks(1*SpaceFactor:SpaceFactor:(i+1)*SpaceFactor)
xticklabels(replace(Filenames,{'_','^'},' '))
xtickangle(90)
ylabel('Concentration (mL^{-1})')

ConcLim.Min = 10^floor(log10(min(yData(yData>0))));
ConcLim.Max = 10^ceil(log10(max(yData)));

ylim([ConcLim.Min ConcLim.Max])
xlim([0 (i+1)*10])


% get output directory and filename information
outputDir = getprefRPSPASS('RPSPASS','OutputDir');
outputPath = fullfile(outputDir);
Full_filename = fullfile(outputPath,['Cohort Comparison','.pdf']);

% make export directory if it does not exist
if ~isfolder(outputPath)
    mkdir(outputPath)
end

% check if a debug export has been written, if it has append the file.
if ~isfile(Full_filename)
    exportgraphics(fig,Full_filename,'BackgroundColor','white','ContentType','vector','Resolution',300)
else
    exportgraphics(fig,Full_filename,'BackgroundColor','white','ContentType','vector','append',true,'Resolution',300)
end


close(fig)

end