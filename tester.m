% Test driver
clear; close all; clc

m = MatlabDriver;

% m.execute('INSERT INTO users (lastname, age, city, email, firstname) VALUES (''Jones'', 35, ''Austin'', ''bob@example.com'', ''Bob'')')
% 
% r1 = m.execute('SELECT * FROM users WHERE lastname=''Jones''');
% 
% m.execute('update users set age = 36 where lastname = ''Jones''');
% 
% r2 = m.execute('select * from users where lastname=''Jones''');
% 
% m.execute('DELETE FROM users WHERE lastname = ''Jones''');
% 
% r3 = m.execute('SELECT * FROM users');

% r1 = m.execute('SELECT * FROM data');

r2 = m.select('data', 'sensor_id', 11);

% r11 = r1.next;
% 
% r1i = r11;
% r1i.cols{3} = 5.7;
% m.insert('data', r1i);
% 
% r1uKeys = {r1i.colNames{1}, r1i.colNames{2}};
% r1uVals = {r1i.cols{1}, r1i.cols{2}};
% u.volts = 9.9;
% m.update('data', r1uKeys, r1uVals, u);
% 
% m.remove('data', r1uKeys, r1uVals);