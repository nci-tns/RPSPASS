function [CalFactor, CalFailure, diam_norm] = getCaliFactor(app, Data, diam_norm)



if strcmp(app.SpikeInUsed,'No')


elseif strcmp(app.SpikeInUsed,'Yes')


    switch Data.RPSPASS.CalMethod

        case 'Median'

            CalFactor = Data.RPSPASS.SpikeInDiam/median(diam_norm);

        case 'guas'

            [N,xData] = histcounts(diam_norm,0:1:Data.maxDiam);
            xData = (xData(2)-xData(1))/2:xData(2)-xData(1):(xData(end)-(xData(2)-xData(1))/2);
            yData = N;
            f = fit(xData.',yData.','gauss1');
            [~, peak_ind] = max(f(xData));
            CalFactor = Data.RPSPASS.SpikeInDiam/xData(peak_ind);

        otherwise

            xData = 0:1:Data.maxDiam;
            pd = fitdist(diam_norm,Data.RPSPASS.CalMethod);
            y_fit = pdf(pd,xData);
            mu = sum(xData.*y_fit) / sum(y_fit);
            CalFactor = Data.RPSPASS.SpikeInDiam/mu;
    end

    CalFailure = false;

end


end