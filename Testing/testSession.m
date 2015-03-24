function out = testSession(idx)

fprintf('Running test session, index %d.\n', idx)

fprintf('Creating driver...\n')
m = MatlabDriver;
fprintf('Driver created.\n')

% Test demo.data table
fprintf('Testing demo.data table...\n')

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

% r = m.select('data');
r = m.select('data', 'sensor_id', 11, {'collected_at', 'DESC'}, 20);

while ~r.exhausted
    x = row2struct(r.next);
    fprintf('Sensor %d at %s has %f volts\n', x.sensor_id, char(x.collected_at), x.volts)
end

m.close;

out = 'it worked';