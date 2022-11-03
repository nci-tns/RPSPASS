
function [SelectedData, Bin, Scale, Label, Lims] = getAxisParameter(app, Selection, Data)

switch Selection
    case 'Diameter'
        % if spike-in is being used, swtich to calibrated data
        switch Data.RPSPASS.SpikeInUsed
            case 'On'
                SelectedData = Data.diam;
            case 'Off'
                SelectedData = Data.non_norm_d;
        end
        Bin = app.DiamEdges;
        Scale = 'linear';
        Label = 'Diameter (nm)';
        Lims = [min(app.DiamEdges),max(app.DiamEdges)];
    case 'S2N/TT'
        SelectedData = Data.TT2SN;
        Bin = app.S2NTTEdges;
        Scale = 'log';
        Label = 'S2N / TT';
        Lims = [min(app.S2NTTEdges),max(app.S2NTTEdges)];
    case 'Transit Time'
        SelectedData = Data.ttime;
        Bin = app.TTimeEdges;
        Scale = 'linear';
        Label = 'Transit Time (µs)';
        Lims = [min(app.TTimeEdges),max(app.TTimeEdges)];
    case 'Time'
        % update the maximum time
        if app.TimeMax < max(Data.time)
            app.TimeMax = max(Data.time);
        elseif app.TimeMax > max(Data.time)
            if max(Data.time) > 100
                app.TimeMax = max(Data.time);
            else
                app.TimeMax = 100;
            end
        end
        SelectedData = Data.time;
        Bin = linspace(min(app.TimeEdges), app.TimeMax, app.Resolution);
        Scale = 'linear';
        Label = 'Time (secs)';
        Lims = [min(app.TimeEdges), app.TimeMax];
    case 'FL1'
        SelectedData = Data.FL1;
        Bin = logspace(-3,1,app.Resolution);
        Scale = 'log';
        Label = 'FL1';
        Lims = [min(Bin) max(Bin)];
    case 'FL2'
        SelectedData = Data.FL2;
        Bin = logspace(-3,1,app.Resolution);
        Scale = 'log';
        Label = 'FL2';
        Lims = [min(Bin) max(Bin)];
    case 'FL3'
        SelectedData = Data.FL3;
        Bin = logspace(-3,1,app.Resolution);
        Scale = 'log';
        Label = 'FL3';
        Lims = [min(Bin) max(Bin)];
end

end