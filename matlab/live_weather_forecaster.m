%% Wireless Pico W + Enviro Indoor Weather Station & Forecaster
clear; clc; close all;

% --- 1. CONFIGURATION ---
pico_ip = '192.168.1.8'; % <-- REPLACE WITH YOUR PICO W IP ADDRESS
url = ['http://', pico_ip, '/data'];

sample_interval = 2;       % Seconds between readings
max_points = 100;          % Rolling window size (100 samples = ~3.3 mins)
filter_window = 5;         % Moving average window to smooth sensor noise
forecast_steps = 15;       % Predict 15 steps (30 seconds) into the future
min_samples_for_fit = 10;  % Minimum points required before forecasting

% Data storage arrays
time_sec = [];
temp_raw = [];
temp_smooth = [];
humidity_data = [];
pressure_data = [];
gas_data = [];

% --- 2. SETUP LIVE DASHBOARD FIGURE ---
fig = figure('Name', 'Pico W Wireless Weather Station', ...
             'NumberTitle', 'off', 'Color', 'w', 'Position', [100, 100, 1000, 650]);

% Subplot 1: Temperature (Raw, Filtered & Linear Regression Forecast)
ax1 = subplot(3, 1, 1);
hold(ax1, 'on'); grid(ax1, 'on');
h_raw = plot(ax1, NaN, NaN, 'o', 'Color', [0.7 0.7 0.7], 'MarkerSize', 4, 'DisplayName', 'Raw Sensor');
h_smooth = plot(ax1, NaN, NaN, '-', 'Color', [0.85 0.33 0.10], 'LineWidth', 2, 'DisplayName', 'Moving Avg Filter');
h_forecast = plot(ax1, NaN, NaN, '--', 'Color', [0 0.45 0.74], 'LineWidth', 2, 'DisplayName', 'Trend Forecast');
title(ax1, 'Temperature & Linear Trend Forecast (°C)');
ylabel(ax1, 'Temp (°C)');
legend(ax1, 'Location', 'northwest');

% Subplot 2: Relative Humidity
ax2 = subplot(3, 1, 2);
grid(ax2, 'on');
h_hum = plot(ax2, NaN, NaN, '-b', 'LineWidth', 1.8);
title(ax2, 'Relative Humidity (%)');
ylabel(ax2, 'Humidity (%)');

% Subplot 3: Barometric Pressure
ax3 = subplot(3, 1, 3);
grid(ax3, 'on');
h_press = plot(ax3, NaN, NaN, '-g', 'Color', [0.13 0.55 0.13], 'LineWidth', 1.8);
title(ax3, 'Atmospheric Pressure (hPa)');
xlabel(ax3, 'Elapsed Time (seconds)');
ylabel(ax3, 'Pressure (hPa)');

% --- 3. ACQUISITION, FILTERING & FORECASTING LOOP ---
disp('Starting wireless acquisition... Close the figure window to stop and save CSV.');
start_tic = tic;
options = weboptions('Timeout', 5);

while ishandle(fig)
    try
        % Fetch JSON payload from Pico W
        data = webread(url, options);
        t_now = toc(start_tic);
        
        % Append new measurements
        time_sec(end+1) = t_now;
        temp_raw(end+1) = data.temperature_c;
        humidity_data(end+1) = data.humidity_pct;
        pressure_data(end+1) = data.pressure_hpa;
        gas_data(end+1) = data.gas_ohms;
        
        % Keep only the latest 'max_points' for clean rolling visualization
        if length(time_sec) > max_points
            time_sec = time_sec(end-max_points+1:end);
            temp_raw = temp_raw(end-max_points+1:end);
            humidity_data = humidity_data(end-max_points+1:end);
            pressure_data = pressure_data(end-max_points+1:end);
            gas_data = gas_data(end-max_points+1:end);
        end
        
        % Apply Moving Average Digital Filter to smooth temperature quantization noise
        temp_smooth = movmean(temp_raw, min(filter_window, length(temp_raw)));
        
        % Update Plots
        set(h_raw, 'XData', time_sec, 'YData', temp_raw);
        set(h_smooth, 'XData', time_sec, 'YData', temp_smooth);
        set(h_hum, 'XData', time_sec, 'YData', humidity_data);
        set(h_press, 'XData', time_sec, 'YData', pressure_data);
        
        % Linear Regression Trend Forecast (polyfit degree 1)
        if length(time_sec) >= min_samples_for_fit
            p = polyfit(time_sec, temp_smooth, 1); % p(1) = slope (°C/sec), p(2) = intercept
            t_future = t_now + (1:forecast_steps) * sample_interval;
            temp_pred = polyval(p, t_future);
            
            set(h_forecast, 'XData', [t_now, t_future], 'YData', [temp_smooth(end), temp_pred]);
            
            % Display live rate of change in the title
            rate_per_min = p(1) * 60;
            title(ax1, sprintf('Temperature: %.2f °C | Trend: %+.3f °C/min | Predicted (+30s): %.2f °C', ...
                  temp_smooth(end), rate_per_min, temp_pred(end)));
        end
        
        drawnow;
        pause(sample_interval);
        
    catch ME
        warning('Connection hiccup: %s. Retrying...', ME.message);
        pause(1);
    end
end

% --- 4. AUTO-SAVE LOGGED DATA ON EXIT ---
if ~isempty(time_sec)
    T = table(time_sec', temp_raw', temp_smooth', humidity_data', pressure_data', gas_data', ...
        'VariableNames', {'Time_s', 'Temp_Raw_C', 'Temp_Filtered_C', 'Humidity_Pct', 'Pressure_hPa', 'Gas_Ohms'});
    writetable(T, 'weather_session_log.csv');
    disp('Session saved to weather_session_log.csv!');
end