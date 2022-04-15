function [app] = getSpikeInInfo(app, Output)

app.SpikeInUsed = Output.spikein_used;
app.SpikeInDiam = Output.beaddiam;

if isnan(Output.beadconc)
    app.SpikeInConc = [];
else
    app.SpikeInConc = Output.beadconc;
end

end