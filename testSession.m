function out = testSession(idx)

fprintf('Running session testing, index %n.\n', idx)

m = MatlabDriver;

% Test demo.data table

nSensors = 3;
nMeasurementsPerSensor = 5;
for i = 1:nSensors
    for j = 1:nMeasurementsPerSensor
        
        s = [];
        s.sensor_id = int32(10 + i);
        s.collected_at = java.util.Date;
        s.volts = 10*rand;
        
        r = struct2row(s);
        
        m.insert('data', r);
        
    end
end

out = m.select('data');

m.close;