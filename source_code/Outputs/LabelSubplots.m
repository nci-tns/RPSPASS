function LabelSubplots(td, titleInd, SubplotLabels)

axtype = get(td.Children,'type');
label = strcmp(axtype,'axes');
ChilAx = td.Children(label);

for i = size(ChilAx,1):-1:1

    pos = ChilAx(i).InnerPosition;

    x_pos_dif = (pos(3)+pos(1))-pos(1);
    y_pos_dif = (pos(4)+pos(2))-pos(2);

    x = pos(1) + (x_pos_dif * 0.09);
    y = pos(2) + (y_pos_dif * 0.75);

    annotation('textbox', [x, y, 0 0], 'string', char(65+numel(ChilAx)-i),...
        'FontSize',16,'FontWeight','bold','verticalalignment','baseline','horizontalalignment','center','LineStyle','none', 'FitBoxToText','on')

end

for i = 1:numel(SubplotLabels)

    xPos = ChilAx(titleInd(i)).Position(1);
    yPos = ChilAx(titleInd(i)).Position(2) + (ChilAx(titleInd(i)).Position(4) * 1.03);

    annotation('textbox', [xPos yPos 0 0],...
        'string', SubplotLabels{i},'FontSize',14,'FontWeight','bold','verticalalignment','baseline',...
        'horizontalalignment','left','LineStyle','none','FitBoxToText','on')
end

end