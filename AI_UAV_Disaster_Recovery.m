%% AI-Based Dynamic UAV Deployment for Emergency Communication
%  Fully Dynamic Asynchronous Event-Driven Dispatch & Repositioning
%  Designed for MATLAB Online (https://matlab.mathworks.com)
%
%  HOW IT WORKS:
%    1. User enters: Total Base Stations, Destroyed Towers, Number of UAVs
%    2. Number of disaster zones = Number of destroyed towers
%    3. SOS demand per zone is computed dynamically from RF propagation model
%    4. Zones are sorted by SOS demand (descending)
%    5. Top-N drones dispatched to Top-N highest-demand zones
%    6. When a drone's zone clears, it flies ALONE to the next unserved zone

clear; clc; close all;

% =====================================================================
%  1. INTERACTIVE INPUTS
% =====================================================================
fprintf('============================================================\n');
fprintf('  AI-POWERED EMERGENCY COMMUNICATION COMMAND CENTER\n');
fprintf('  Asynchronous Event-Driven Dynamic UAV Dispatch\n');
fprintf('============================================================\n\n');

in_ant = input('Total Base Stations in City (Default 6): ');
if isempty(in_ant), nAntennas = 6; else, nAntennas = max(1, round(in_ant)); end

in_des = input(sprintf('Number of Towers destroyed (Default 4, max %d): ', nAntennas));
if isempty(in_des), nDestroyed = min(4, nAntennas); else, nDestroyed = min(round(in_des), nAntennas); end

in_uav = input('Number of UAVs available (Default 3): ');
if isempty(in_uav), nUAVs = 3; else, nUAVs = max(1, round(in_uav)); end

% Number of disaster zones = number of destroyed towers
nZones = nDestroyed;

fprintf('\n>> Configuration: %d Base Stations, %d Destroyed, %d UAVs, %d Disaster Zones\n\n', ...
    nAntennas, nDestroyed, nUAVs, nZones);

% =====================================================================
%  2. SYSTEM PARAMETERS & DYNAMIC SOS COMPUTATION
% =====================================================================
gridSize = 1000; res = 40;
numUsers = 120;

[X, Y] = meshgrid(0:res:gridSize, 0:res:gridSize);

% RF propagation model parameters
pt = 35; threshold = -90; n_path = 4;
f = 2.4e9; c = 3e8; d0 = 1;
L0 = 20*log10(4*pi*d0*f/c);

% Place base stations randomly
rng(42);
antPos = gridSize * rand(nAntennas, 2);
shuffledIdx = randperm(nAntennas);
destroyedIdx = shuffledIdx(1:nDestroyed);
survivedIdx  = shuffledIdx(nDestroyed+1:end);
survivedPos  = antPos(survivedIdx, :);
destroyedPos = antPos(destroyedIdx, :);

% --- ZONE CENTERS = DESTROYED TOWER POSITIONS ---
% Each disaster zone is centered on a destroyed tower
zoneCentres = destroyedPos;

% Distribute users across zones (scatter around each destroyed tower)
usersPerZone = floor(numUsers / nZones);
userPos = zeros(numUsers, 2);
userZone = zeros(numUsers, 1);
u_idx = 1;
for z = 1:nZones
    if z == nZones
        n_in_z = numUsers - u_idx + 1;
    else
        n_in_z = usersPerZone;
    end
    cx = zoneCentres(z,1); cy = zoneCentres(z,2);
    for i = 1:n_in_z
        if u_idx <= numUsers
            userPos(u_idx, :) = [cx + 260*(rand-0.5), cy + 260*(rand-0.5)];
            userPos(u_idx, :) = max(10, min(gridSize-10, userPos(u_idx, :)));
            userZone(u_idx) = z;
            u_idx = u_idx + 1;
        end
    end
end

% Compute SOS per zone using RF propagation model
if isempty(survivedPos)
    isDisconnected = true(numUsers, 1);
else
    dx = userPos(:,1) - survivedPos(:,1)';
    dy = userPos(:,2) - survivedPos(:,2)';
    d_surv = sqrt(dx.^2 + dy.^2);
    pr_surv = pt - (L0 + 10*n_path*log10(max(d_surv, d0)/d0));
    isDisconnected = ~any(pr_surv > threshold, 2);
end

% Count disconnected users per zone = base SOS demand
sos_initial = zeros(1, nZones);
for z = 1:nZones
    sos_initial(z) = sum(isDisconnected & (userZone == z));
end

% Add severity-based component from PPT formula:
%   m = 3 + pop/150 + 8*severity + 18*exp(-(z-h)^2/1.5)
for z = 1:nZones
    pop_factor = sos_initial(z) / 150;
    severity = 0.3 + 0.7 * rand;
    height_factor = 18 * exp(-(z - (nZones+1)/2)^2 / max(1.5, nZones/4));
    sos_initial(z) = round(sos_initial(z) + 3 + pop_factor + 8*severity + height_factor);
end

% Ensure minimum SOS of 2 per zone
sos_initial = max(sos_initial, 2);
current_sos = sos_initial;
maxSOS = max(sos_initial) + 10;

fprintf('  Computed SOS Demand per Zone:\n');
for z = 1:nZones
    fprintf('    Zone %d: %d SOS  (centered at %.0f, %.0f)\n', z, sos_initial(z), zoneCentres(z,1), zoneCentres(z,2));
end
fprintf('\n');

% --- BUILD DISPATCH PLAN ---
[~, sortOrder] = sort(sos_initial, 'descend');
nInitial = min(nUAVs, nZones);
initialZones = sortOrder(1:nInitial);
waitingQueue = sortOrder(nInitial+1:end);

fprintf('  Dispatch Plan (sorted by demand):\n');
for j = 1:nInitial
    fprintf('    UAV %d -> Zone %d (%d SOS)\n', j, initialZones(j), sos_initial(initialZones(j)));
end
if ~isempty(waitingQueue)
    fprintf('  Waiting Queue: ');
    for w = 1:length(waitingQueue)
        fprintf('Z%d(%d) ', waitingQueue(w), sos_initial(waitingQueue(w)));
    end
    fprintf('\n');
end
fprintf('\n');

% --- UAV COLORS ---
baseColors = [
    0.2 0.8 1.0;   % Cyan
    0.2 1.0 0.5;   % Green
    1.0 0.8 0.2;   % Gold
    1.0 0.4 0.4;   % Red
    0.8 0.4 1.0;   % Purple
    1.0 0.6 0.2;   % Orange
    0.4 1.0 1.0;   % Teal
    1.0 0.2 0.6;   % Pink
];
nBaseColors = size(baseColors, 1);
uavColors = baseColors(mod((1:nUAVs)-1, nBaseColors)+1, :);

% Zone tick labels (dynamic)
zoneTickLabels = cell(1, nZones);
for z = 1:nZones
    zoneTickLabels{z} = sprintf('Z%d', z);
end

% =====================================================================
%  3. SINGLE UNIFIED DASHBOARD SETUP
% =====================================================================
fig = figure(1);
clf(fig);
set(fig, 'Name', 'AI-UAV Disaster Response Command Center', ...
         'Color', 'k', ...
         'Units', 'normalized', ...
         'Position', [0.04, 0.06, 0.92, 0.84]);

% --- LEFT PANEL: DISASTER SPATIAL MAP ---
axMap = axes('Parent', fig, 'Position', [0.06, 0.10, 0.52, 0.80]);
set(axMap, 'Color', 'k', 'XColor', [0.7 0.7 0.7], 'YColor', [0.7 0.7 0.7], ...
           'GridColor', [0.25 0.25 0.25]);
hold(axMap, 'on'); grid(axMap, 'on');
axis(axMap, [0 gridSize 0 gridSize]);
axis(axMap, 'square');
xlabel(axMap, 'East-West (m)', 'Color', 'w', 'FontSize', 11);
ylabel(axMap, 'North-South (m)', 'Color', 'w', 'FontSize', 11);

% Draw disaster zones as circles around each destroyed tower
zoneRadius = min(180, gridSize / (nZones + 1));
for z = 1:nZones
    cx = zoneCentres(z,1); cy = zoneCentres(z,2);
    th = linspace(0, 2*pi, 60);
    plot(axMap, cx + zoneRadius*cos(th), cy + zoneRadius*sin(th), ...
         '--', 'Color', [0.4 0.4 0.4], 'LineWidth', 1);
    text(axMap, cx, cy + zoneRadius + 20, sprintf('Z%d', z), ...
        'Color', [0.85 0.85 0.85], 'FontSize', 10, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
end

% --- TOP-RIGHT PANEL: LIVE SOS DEMAND BAR CHART ---
axPred = axes('Parent', fig, 'Position', [0.64, 0.55, 0.32, 0.35]);
set(axPred, 'Color', 'k', 'XColor', 'w', 'YColor', 'w');

% --- BOTTOM-RIGHT PANEL: EVENT LOG ---
axComp = axes('Parent', fig, 'Position', [0.64, 0.10, 0.32, 0.35]);
set(axComp, 'Color', 'k', 'XColor', 'w', 'YColor', 'w');

% =====================================================================
%  PHASE 1: STABLE CELLULAR NETWORK
% =====================================================================
title(axMap, 'PHASE 1: STABLE NETWORK OPERATIONS', 'Color', 'g', 'FontSize', 13, 'FontWeight', 'bold');

tPlot = plot(axMap, antPos(:,1), antPos(:,2), '^', ...
    'MarkerSize', 11, 'MarkerFaceColor', 'y', 'MarkerEdgeColor', 'w', 'LineWidth', 1.2);

uPlot = scatter(axMap, userPos(:,1), userPos(:,2), 26, 'g', 'filled');

cla(axPred); set(axPred, 'Color', 'k'); axis(axPred, 'off');
text(axPred, 0.5, 0.85, 'NORMAL NETWORK STATUS', 'Color', 'g', 'FontSize', 12, ...
    'FontWeight', 'bold', 'HorizontalAlignment', 'center');
text(axPred, 0.05, 0.65, sprintf('Active Base Stations:  %d / %d', nAntennas, nAntennas), 'Color', 'w', 'FontSize', 11);
text(axPred, 0.05, 0.48, sprintf('Total Connected Users: %d', numUsers), 'Color', 'w', 'FontSize', 11);
text(axPred, 0.05, 0.31, sprintf('UAV Relays Standby:    %d drone(s)', nUAVs), 'Color', 'c', 'FontSize', 11);
text(axPred, 0.05, 0.14, 'System Health: 100% ONLINE', 'Color', 'g', 'FontSize', 11, 'FontWeight', 'bold');

cla(axComp); set(axComp, 'Color', 'k'); axis(axComp, 'off');
text(axComp, 0.5, 0.85, 'SYSTEM INITIALIZATION', 'Color', 'c', 'FontSize', 12, ...
    'FontWeight', 'bold', 'HorizontalAlignment', 'center');
text(axComp, 0.05, 0.65, sprintf('Configuration: %d towers, %d destroyed, %d UAVs', nAntennas, nDestroyed, nUAVs), 'Color', 'w', 'FontSize', 10);
text(axComp, 0.05, 0.48, sprintf('Disaster Zones: %d (one per destroyed tower)', nZones), 'Color', 'w', 'FontSize', 10);
text(axComp, 0.05, 0.31, 'Drones relocate independently on completion', 'Color', 'y', 'FontSize', 10);
text(axComp, 0.05, 0.14, 'Carrier: 2.4 GHz | Power: 35 dBm', 'Color', [0.7 0.7 0.7], 'FontSize', 10);

drawnow;
pause(2.0);

% =====================================================================
%  PHASE 2: DISASTER STRIKES
% =====================================================================
title(axMap, sprintf('PHASE 2: DISASTER — %d OF %d TOWERS DESTROYED', nDestroyed, nAntennas), ...
    'Color', 'r', 'FontSize', 13, 'FontWeight', 'bold');

delete(tPlot);

plot(axMap, destroyedPos(:,1), destroyedPos(:,2), 'rx', 'MarkerSize', 14, 'LineWidth', 2.5);

if ~isempty(survivedPos)
    plot(axMap, survivedPos(:,1), survivedPos(:,2), '^', ...
        'MarkerSize', 11, 'MarkerFaceColor', 'y', 'MarkerEdgeColor', 'w', 'LineWidth', 1.2);
end

set(uPlot, 'CData', [0 1 0] .* ~isDisconnected + [1 0 0] .* isDisconnected);

% Live Bar Chart
cla(axPred); set(axPred, 'Color', 'k', 'XColor', 'w', 'YColor', 'w');
axis(axPred, 'on'); hold(axPred, 'on');
bar(axPred, 1:nZones, current_sos, 0.55, 'FaceColor', [0.8 0.2 0.2], 'EdgeColor', 'w', 'LineWidth', 1);
for z = 1:nZones
    text(axPred, z, current_sos(z)+1.5, sprintf('%d', current_sos(z)), ...
        'Color', 'w', 'FontSize', 8, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
end
set(axPred, 'XTick', 1:nZones, 'XTickLabel', zoneTickLabels, 'FontSize', 9);
ylabel(axPred, 'Pending SOS Calls', 'Color', 'w', 'FontSize', 9);
title(axPred, sprintf('SOS DEMAND ACROSS %d DISASTER ZONES', nZones), 'Color', 'r', 'FontSize', 10, 'FontWeight', 'bold');
ylim(axPred, [0 maxSOS]);

% Build demand summary strings dynamically
[~, demandOrder] = sort(sos_initial, 'descend');
demandStr1 = '';
demandStr2 = '';
for idx = 1:nZones
    zz = demandOrder(idx);
    entry = sprintf('Z%d:%d ', zz, sos_initial(zz));
    if idx <= ceil(nZones/2)
        demandStr1 = [demandStr1, entry];
    else
        demandStr2 = [demandStr2, entry];
    end
end

assignStr = sprintf('Assign %d Drone(s) -> Top %d Zone(s) (', nUAVs, nInitial);
for j = 1:nInitial
    if j > 1, assignStr = [assignStr, ', ']; end
    assignStr = [assignStr, sprintf('Z%d', initialZones(j))];
end
assignStr = [assignStr, ')'];

cla(axComp); set(axComp, 'Color', 'k'); axis(axComp, 'off');
text(axComp, 0.5, 0.85, 'SOS DEMAND RECEIVED', 'Color', 'r', 'FontSize', 12, ...
    'FontWeight', 'bold', 'HorizontalAlignment', 'center');
text(axComp, 0.05, 0.68, demandStr1, 'Color', 'y', 'FontSize', 10, 'FontWeight', 'bold');
if ~isempty(demandStr2)
    text(axComp, 0.05, 0.50, demandStr2, 'Color', 'w', 'FontSize', 10);
end
text(axComp, 0.05, 0.30, 'Strategy: Sort by Highest Demand First', 'Color', 'c', 'FontSize', 10);
text(axComp, 0.05, 0.12, assignStr, 'Color', 'g', 'FontSize', 10, 'FontWeight', 'bold');

drawnow;
pause(2.5);

% =====================================================================
%  PHASE 3: INITIAL DISPATCH (Dynamic)
% =====================================================================
dispatchTitle = 'PHASE 3: DISPATCHING ';
for j = 1:nInitial
    if j > 1, dispatchTitle = [dispatchTitle, ', ']; end
    dispatchTitle = [dispatchTitle, sprintf('UAV%d->Z%d', j, initialZones(j))];
end
title(axMap, dispatchTitle, 'Color', 'y', 'FontSize', 11, 'FontWeight', 'bold');

% Create UAV markers
uavPlots = gobjects(nUAVs, 1);
uavText  = gobjects(nUAVs, 1);

for j = 1:nUAVs
    uavPlots(j) = plot(axMap, 0, 0, 'D', ...
        'MarkerSize', 14, 'LineWidth', 2, ...
        'MarkerFaceColor', 'b', 'MarkerEdgeColor', uavColors(j,:));
    uavText(j) = text(axMap, 0, 0, sprintf('UAV %d', j), ...
        'Color', uavColors(j,:), 'FontSize', 10, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center', 'BackgroundColor', [0 0 0 0.75], 'Margin', 2);
end

% Track positions
uavCurrentPos = zeros(nUAVs, 2);
uavCurrentZone = zeros(nUAVs, 1);

% Animate initial flight from base (0,0) to assigned zones
initialTargets = zeros(nInitial, 2);
for j = 1:nInitial
    initialTargets(j,:) = zoneCentres(initialZones(j), :);
end

for k = 1:25
    for j = 1:nInitial
        currX = (initialTargets(j,1)/25) * k;
        currY = (initialTargets(j,2)/25) * k;
        set(uavPlots(j), 'XData', currX, 'YData', currY);
        set(uavText(j),  'Position', [currX, currY + 45, 0], ...
                         'String', sprintf('UAV %d', j));
    end
    drawnow;
    pause(0.03);
end

for j = 1:nInitial
    uavCurrentPos(j,:) = initialTargets(j,:);
    uavCurrentZone(j) = initialZones(j);
end

% Heatmap at initial deployment
Z = -150 * ones(size(X));
for s = 1:size(survivedPos, 1)
    dist = sqrt((X-survivedPos(s,1)).^2 + (Y-survivedPos(s,2)).^2);
    Z = max(Z, pt - (L0 + 10*n_path*log10(max(dist,d0)/d0)));
end
for j = 1:nInitial
    distU = sqrt((X-initialTargets(j,1)).^2 + (Y-initialTargets(j,2)).^2);
    Z = max(Z, pt - (L0 + 10*n_path*log10(max(distU,d0)/d0)));
end
[~, hMap] = contourf(axMap, X, Y, Z, 14, 'LineColor', 'none');
uistack(hMap, 'bottom');
colormap(axMap, hot);

% Bar chart with active zone highlights
cla(axPred); set(axPred, 'Color', 'k', 'XColor', 'w', 'YColor', 'w');
axis(axPred, 'on'); hold(axPred, 'on');
barCols = repmat([0.7 0.2 0.2], nZones, 1);
for j = 1:nInitial
    barCols(initialZones(j), :) = uavColors(j, :);
end
for z = 1:nZones
    bar(axPred, z, current_sos(z), 0.55, 'FaceColor', barCols(z,:), 'EdgeColor', 'w', 'LineWidth', 1);
    text(axPred, z, current_sos(z)+1.5, sprintf('%d', current_sos(z)), ...
        'Color', 'w', 'FontSize', 8, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
end
for j = 1:nInitial
    zIdx = initialZones(j);
    text(axPred, zIdx, current_sos(zIdx)+6.0, sprintf('\\downarrow UAV %d', j), ...
        'Color', uavColors(j,:), 'FontSize', 8, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
end
set(axPred, 'XTick', 1:nZones, 'XTickLabel', zoneTickLabels, 'FontSize', 9);
ylabel(axPred, 'Pending SOS Calls', 'Color', 'w', 'FontSize', 9);
title(axPred, 'ACTIVE DISPATCH: INITIAL DEPLOYMENT', 'Color', 'y', 'FontSize', 10, 'FontWeight', 'bold');
ylim(axPred, [0 maxSOS]);

% Status panel
cla(axComp); set(axComp, 'Color', 'k'); axis(axComp, 'off');
text(axComp, 0.5, 0.90, 'DRONE POSITIONS (ROUND 1)', 'Color', 'c', 'FontSize', 11, ...
    'FontWeight', 'bold', 'HorizontalAlignment', 'center');
yPos = 0.72;
for j = 1:nInitial
    zIdx = initialZones(j);
    text(axComp, 0.05, yPos, sprintf('UAV %d -> Zone %d', j, zIdx), ...
        'Color', uavColors(j,:), 'FontSize', 10, 'FontWeight', 'bold');
    yPos = yPos - 0.18;
end
if ~isempty(waitingQueue)
    text(axComp, 0.05, max(0.05, yPos), sprintf('Queue: %d zone(s) waiting', length(waitingQueue)), ...
        'Color', 'y', 'FontSize', 10);
end

drawnow;
pause(2.5);

% =====================================================================
%  ASYNCHRONOUS EVENT LOOP
% =====================================================================
servedZones = false(1, nZones);
remaining_sos = sos_initial;
steps = 30;

droneActive = false(1, nUAVs);
droneZone = zeros(1, nUAVs);
for j = 1:nInitial
    droneActive(j) = true;
    droneZone(j) = initialZones(j);
end

eventNum = 0;

while ~all(servedZones)
    % Find which active drone finishes first (lowest remaining SOS)
    minSOS = Inf;
    finishDrone = 0;
    for j = 1:nUAVs
        if droneActive(j) && remaining_sos(droneZone(j)) < minSOS
            minSOS = remaining_sos(droneZone(j));
            finishDrone = j;
        end
    end

    if finishDrone == 0
        break;
    end

    finishZone = droneZone(finishDrone);

    % Reduce SOS proportionally for all active drones
    reduction = minSOS;
    for j = 1:nUAVs
        if droneActive(j)
            remaining_sos(droneZone(j)) = remaining_sos(droneZone(j)) - reduction;
        end
    end

    servedZones(finishZone) = true;
    remaining_sos(finishZone) = 0;
    current_sos = remaining_sos;

    eventNum = eventNum + 1;

    if ~isempty(waitingQueue)
        nextZone = waitingQueue(1);
        waitingQueue(1) = [];

        % --- ANIMATE ---
        title(axMap, sprintf('EVENT %d: Z%d CLEARED! UAV %d: Z%d -> Z%d', ...
            eventNum, finishZone, finishDrone, finishZone, nextZone), ...
            'Color', uavColors(finishDrone,:), 'FontSize', 11, 'FontWeight', 'bold');

        % Update bar chart
        cla(axPred); set(axPred, 'Color', 'k', 'XColor', 'w', 'YColor', 'w');
        axis(axPred, 'on'); hold(axPred, 'on');
        for z = 1:nZones
            if servedZones(z)
                bc = [0.2 0.7 0.7];
            else
                bc = [0.7 0.2 0.2];
                for jj = 1:nUAVs
                    if droneActive(jj) && droneZone(jj) == z
                        bc = uavColors(jj,:);
                        break;
                    end
                end
            end
            bar(axPred, z, current_sos(z), 0.55, 'FaceColor', bc, 'EdgeColor', 'w', 'LineWidth', 1);
            if servedZones(z)
                text(axPred, z, 3, 'CLEARED!', 'Color', 'c', 'FontSize', 7, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
            else
                text(axPred, z, current_sos(z)+1.5, sprintf('%d', round(current_sos(z))), ...
                    'Color', 'w', 'FontSize', 8, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
            end
        end
        bar(axPred, nextZone, current_sos(nextZone), 0.55, 'FaceColor', uavColors(finishDrone,:), 'EdgeColor', 'w', 'LineWidth', 1);
        set(axPred, 'XTick', 1:nZones, 'XTickLabel', zoneTickLabels, 'FontSize', 9);
        ylabel(axPred, 'Pending SOS Calls', 'Color', 'w', 'FontSize', 9);
        title(axPred, sprintf('Z%d CLEARED -> UAV %d -> Z%d', finishZone, finishDrone, nextZone), ...
            'Color', uavColors(finishDrone,:), 'FontSize', 10, 'FontWeight', 'bold');
        ylim(axPred, [0 maxSOS]);

        % Status panel
        cla(axComp); set(axComp, 'Color', 'k'); axis(axComp, 'off');
        text(axComp, 0.5, 0.88, sprintf('EVENT %d: UAV %d REASSIGNMENT', eventNum, finishDrone), ...
            'Color', uavColors(finishDrone,:), 'FontSize', 11, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
        text(axComp, 0.05, 0.70, sprintf('UAV %d: Z%d -> Z%d', finishDrone, finishZone, nextZone), ...
            'Color', uavColors(finishDrone,:), 'FontSize', 10, 'FontWeight', 'bold');
        yPos = 0.52;
        for j = 1:nUAVs
            if droneActive(j) && j ~= finishDrone
                text(axComp, 0.05, yPos, sprintf('UAV %d: STATIONARY in Z%d', j, droneZone(j)), ...
                    'Color', uavColors(j,:), 'FontSize', 10);
                yPos = yPos - 0.18;
            end
        end
        drawnow;
        pause(1.5);

        % Draw trajectory line
        plot(axMap, [zoneCentres(finishZone,1), zoneCentres(nextZone,1)], ...
                    [zoneCentres(finishZone,2), zoneCentres(nextZone,2)], ...
             '--', 'Color', uavColors(finishDrone,:), 'LineWidth', 2);
        midX = (zoneCentres(finishZone,1) + zoneCentres(nextZone,1))/2;
        midY = (zoneCentres(finishZone,2) + zoneCentres(nextZone,2))/2;
        text(axMap, midX, midY - 30, sprintf('UAV %d', finishDrone), ...
             'Color', uavColors(finishDrone,:), 'FontSize', 8, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

        % Stamp cleared zone
        text(axMap, zoneCentres(finishZone,1), zoneCentres(finishZone,2)-40, ...
             sprintf('[Z%d Cleared]', finishZone), ...
             'Color', 'c', 'FontSize', 8, 'HorizontalAlignment', 'center', 'BackgroundColor', [0 0 0 0.6]);

        % Animate UAV flight
        startPos = zoneCentres(finishZone, :);
        endPos   = zoneCentres(nextZone, :);

        for k = 1:steps
            frac = k / steps;
            currX = startPos(1) + (endPos(1) - startPos(1)) * frac;
            currY = startPos(2) + (endPos(2) - startPos(2)) * frac;
            set(uavPlots(finishDrone), 'XData', currX, 'YData', currY);
            set(uavText(finishDrone),  'Position', [currX, currY + 45, 0], ...
                'String', sprintf('UAV %d (->Z%d)', finishDrone, nextZone));

            % Update heatmap
            Z = -150 * ones(size(X));
            for s = 1:size(survivedPos, 1)
                dist = sqrt((X-survivedPos(s,1)).^2 + (Y-survivedPos(s,2)).^2);
                Z = max(Z, pt - (L0 + 10*n_path*log10(max(dist,d0)/d0)));
            end
            for j = 1:nUAVs
                if j == finishDrone
                    dj = sqrt((X-currX).^2 + (Y-currY).^2);
                elseif droneActive(j)
                    dj = sqrt((X-uavCurrentPos(j,1)).^2 + (Y-uavCurrentPos(j,2)).^2);
                else
                    continue;
                end
                Z = max(Z, pt - (L0 + 10*n_path*log10(max(dj,d0)/d0)));
            end
            if exist('hMap', 'var') && isvalid(hMap), delete(hMap); end
            [~, hMap] = contourf(axMap, X, Y, Z, 14, 'LineColor', 'none');
            uistack(hMap, 'bottom');
            colormap(axMap, hot);

            drawnow;
            pause(0.04);
        end

        % Update drone state
        uavCurrentPos(finishDrone, :) = endPos;
        droneZone(finishDrone) = nextZone;
        set(uavText(finishDrone), 'String', sprintf('UAV %d (Z%d)', finishDrone, nextZone));

        pause(1.5);
    else
        % No more zones in queue — drone becomes idle
        droneActive(finishDrone) = false;

        text(axMap, zoneCentres(finishZone,1), zoneCentres(finishZone,2)-40, ...
             sprintf('[Z%d Cleared]', finishZone), ...
             'Color', 'c', 'FontSize', 8, 'HorizontalAlignment', 'center', 'BackgroundColor', [0 0 0 0.6]);

        set(uavText(finishDrone), 'String', sprintf('UAV %d (IDLE)', finishDrone));

        if all(servedZones)
            break;
        end
    end
end

% =====================================================================
%  FINAL: 100% RECOVERY
% =====================================================================
current_sos(:) = 0;
set(uPlot, 'CData', repmat([0 1 0.3], numUsers, 1));

title(axMap, sprintf('MISSION COMPLETE: 100%% RECOVERY (%d ZONES, %d DRONES)', nZones, nUAVs), ...
    'Color', 'g', 'FontSize', 12, 'FontWeight', 'bold');

% Final Bar Chart
cla(axPred); set(axPred, 'Color', 'k', 'XColor', 'w', 'YColor', 'w');
axis(axPred, 'on'); hold(axPred, 'on');
bar(axPred, 1:nZones, zeros(nZones, 1), 0.55, 'FaceColor', [0.2 0.8 0.8], 'EdgeColor', 'w', 'LineWidth', 1);
for z = 1:nZones
    text(axPred, z, 3, 'CLEARED!', 'Color', 'c', 'FontSize', 8, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
end
set(axPred, 'XTick', 1:nZones, 'XTickLabel', zoneTickLabels, 'FontSize', 9);
ylabel(axPred, 'Pending SOS Calls', 'Color', 'w', 'FontSize', 9);
title(axPred, sprintf('ALL %d ZONES RECOVERED (0 PENDING)', nZones), 'Color', 'g', 'FontSize', 10, 'FontWeight', 'bold');
ylim(axPred, [0 maxSOS]);

% Final Summary
cla(axComp); set(axComp, 'Color', 'k'); axis(axComp, 'off');
text(axComp, 0.5, 0.90, 'MISSION SUMMARY', 'Color', 'g', 'FontSize', 12, ...
    'FontWeight', 'bold', 'HorizontalAlignment', 'center');
yPos = 0.72;
for j = 1:nUAVs
    if droneZone(j) > 0
        text(axComp, 0.05, yPos, sprintf('UAV %d -> Zone %d (final)', j, droneZone(j)), ...
            'Color', uavColors(j,:), 'FontSize', 10, 'FontWeight', 'bold');
    else
        text(axComp, 0.05, yPos, sprintf('UAV %d -> at base (unused)', j), ...
            'Color', uavColors(j,:), 'FontSize', 10, 'FontWeight', 'bold');
    end
    yPos = yPos - 0.14;
    if yPos < 0.05, break; end
end
text(axComp, 0.05, 0.02, sprintf('%d zone(s) cleared, %d event(s), 100%% rescued!', nZones, eventNum), ...
    'Color', 'y', 'FontSize', 9, 'FontWeight', 'bold');

drawnow;

% =====================================================================
%  COMMAND WINDOW LOG
% =====================================================================
fprintf('\n============================================================\n');
fprintf('  MISSION LOG\n');
fprintf('============================================================\n');
fprintf('  Config: %d stations, %d destroyed, %d UAV(s), %d zone(s)\n', nAntennas, nDestroyed, nUAVs, nZones);
fprintf('  SOS: ');
for z = 1:nZones
    fprintf('Z%d:%d ', z, sos_initial(z));
end
fprintf('\n');
fprintf('  Initial: ');
for j = 1:nInitial
    fprintf('UAV%d->Z%d ', j, initialZones(j));
end
fprintf('\n');
fprintf('  Events: %d reassignment(s)\n', eventNum);
fprintf('  RESULT: 100%% recovered!\n');
fprintf('============================================================\n');
