function LabelSubplots(td)

axtype = get(td.Children,'type');
label = strcmp(axtype,'axes');
ChilAx = td.Children(label);

for i = size(ChilAx,1):-1:1

    pos = ChilAx(i).InnerPosition;

    x_pos_dif = (pos(3)+pos(1))-pos(1);
    y_pos_dif = (pos(4)+pos(2))-pos(2);

    x = pos(1) + (x_pos_dif * 0.1);
    y = pos(2) + (y_pos_dif * 0.75);

    annotation('textbox', [x, y, 0 0], 'string', char(65+numel(ChilAx)-i),...
        'FontSize',16,'FontWeight','bold','verticalalignment','baseline','horizontalalignment','center','LineStyle','none', 'FitBoxToText','on')

end

SubplotLabels = {'Raw Data','Diameter Calibration','Outlier Removal','Noise & Spike-in Removal'};

axInd = [12, 9 , 6, 3];

for i = 1:numel(axInd)

    xPos = ChilAx(axInd(i)).Position(1);
    yPos = ChilAx(axInd(i)).Position(2) + (ChilAx(axInd(i)).Position(4) * 1.1);

    annotation('textbox', [xPos yPos 0 0],...
        'string', SubplotLabels{i},'FontSize',14,'FontWeight','bold','verticalalignment','baseline',...
        'horizontalalignment','left','LineStyle','none','FitBoxToText','on')
end

end