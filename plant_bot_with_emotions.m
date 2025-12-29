function plant_bot_thesis_with_emotions()
    % =========================================================================
    % FLORABOT: ADAPTIVE PLANT BOT + EMOTION DISPLAY
    % Features:
    % 1. Adaptive Biology (Snake Plant vs Peace Lily)
    % 2. Emotion Engine (Emojis displayed on robot body)
    % 3. Optimized Physics (3-min runtime, stable FPS)
    % =========================================================================

    %% 1. SYSTEM SETUP (OOBE)
    clc;
    fprintf('=== AUTONOMOUS PLANT BOT CONFIGURATION ===\n');
    fprintf('Select the biological profile to simulate:\n');
    fprintf(' [1] Snake Plant (Sansevieria) - Low Water / Slow Drain\n');
    fprintf(' [2] Golden Pothos (Epipremnum) - Medium Water\n');
    fprintf(' [3] Peace Lily (Spathiphyllum) - High Water / Fast Drain\n');
    choice = input('>> Enter Choice (1-3): ', 's');
    
    % DATABASE: [ThirstThreshold, DrainMultiplier, Name]
    if strcmp(choice, '1')
        PLANT = struct('name', 'Snake Plant', 'thresh', 15, 'drain_mult', 0.5);
    elseif strcmp(choice, '3')
        PLANT = struct('name', 'Peace Lily',  'thresh', 50, 'drain_mult', 1.8);
    else
        PLANT = struct('name', 'Golden Pothos', 'thresh', 30, 'drain_mult', 1.0);
    end
    
    fprintf('\nSystem Armed: Adapting algorithm for [ %s ]...\n', PLANT.name);
    pause(1);

    %% 2. SIMULATION CONFIGURATION
    sim.real_duration_min = 3;             
    sim.target_fps = 30;
    sim.physics_hz = 60;                   
    
    total_real_seconds = sim.real_duration_min * 60;
    total_physics_steps = total_real_seconds * sim.physics_hz;
    render_skip = floor(sim.physics_hz / sim.target_fps); 
    steps_per_virt_hour = total_physics_steps / 24;
    
    % Video Export
    conf.export_video = true; 
    conf.video_name = ['Sim_Run_' strrep(PLANT.name,' ','') '.mp4'];
    
    % Environment
    dock_pos = [1, 9]; water_pos = [9, 9]; bed_pos  = [9, 1];
    human_pos = [5, 5];      
    bot.x = 5; bot.y = 5; bot.theta = 0; bot.radius = 0.3;
    
    % PHYSICS & RATES
    rate.battery = 90 / (16 * steps_per_virt_hour); 
    rate.soil = (50 / (24 * steps_per_virt_hour)) * PLANT.drain_mult; 
    rate.charge = 100 / (2 * steps_per_virt_hour); 
    
    state.battery = 80;    
    state.soil = 70;       
    state.charging = false;
    state.mode_code = 1;
    state.emoji = '(:'; % Default Face
    
    phys.max_speed = 0.8; 
    phys.dt = 1 / sim.physics_hz;

    % LOGS
    log_size = floor(total_physics_steps / render_skip) + 10;
    log.bat = zeros(1, log_size); log.soil = zeros(1, log_size);
    log.mode = zeros(1, log_size); log.x = zeros(1, log_size); log.y = zeros(1, log_size);
    log_idx = 1;

    %% 3. VISUALIZATION SETUP
    f = figure('Color', 'white', 'Name', ['Simulation: ' PLANT.name], ...
               'Position', [50 50 1200 600], 'MenuBar', 'none');
    
    global user_action; user_action = ''; 
    set(f, 'WindowKeyPressFcn', @key_callback);

    v_writer = [];
    if conf.export_video
        v_writer = VideoWriter(conf.video_name, 'MPEG-4');
        v_writer.FrameRate = sim.target_fps;
        open(v_writer);
    end

    % --- SCENE ---
    subplot(1, 4, [1 2 3]); hold on; axis equal; box on;
    axis([0 10 0 10]); set(gca, 'XTick', [], 'YTick', []);
    title(['Running Profile: ' PLANT.name ' (Press "W" to Water)']);
    
    % Static Elements
    rectangle('Position', [0.5, 8.5, 1, 1], 'FaceColor', [1 0.8 1], 'EdgeColor', 'm'); 
    text(1, 9, 'PWR', 'Color', 'm', 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
    rectangle('Position', [8.5, 8.5, 1, 1], 'FaceColor', [0.8 1 1], 'EdgeColor', 'c'); 
    text(9, 9, 'H2O', 'Color', 'b', 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
    rectangle('Position', [8.5, 0.5, 1, 1], 'FaceColor', [0.8 0.8 0.8], 'EdgeColor', 'k'); 
    text(9, 1, 'ZZZ', 'Color', 'k', 'HorizontalAlignment', 'center');
    
    % Dynamic Elements
    h_bot = patch('XData', [], 'YData', [], 'FaceColor', 'g', 'EdgeColor', 'k');
    % THE FACE (MONITOR)
    h_face = text(0, 0, '(:', 'Color', 'w', 'FontWeight', 'bold', 'FontSize', 11, 'HorizontalAlignment', 'center');
    
    h_dir = line([0 0], [0 0], 'Color', 'k', 'LineWidth', 2);
    h_human = plot(human_pos(1), human_pos(2), 'bo', 'MarkerSize', 10, 'MarkerFaceColor', 'b');
    h_night = patch([0 10 10 0], [0 0 10 10], 'k', 'FaceAlpha', 0);
    
    % --- DASHBOARD ---
    subplot(1, 4, 4); axis([0 3 0 100]); axis off;
    text(1.5, 105, 'LIVE TELEMETRY', 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    h_bar_batt = patch([0.5 1.5 1.5 0.5], [0 0 50 50], 'g');
    h_bar_soil = patch([2.0 3.0 3.0 2.0], [0 0 100 100], 'b');
    text(1, -5, 'Bat'); text(2.5, -5, 'Soil');
    h_clock = text(1.5, 85, '00:00', 'FontSize', 20, 'HorizontalAlignment', 'center');
    h_status = text(1.5, 75, 'INIT', 'FontSize', 10, 'HorizontalAlignment', 'center');
    text(1.5, 95, PLANT.name, 'HorizontalAlignment', 'center', 'Color', [0 0.5 0], 'FontWeight', 'bold');

    %% 4. MAIN LOOP
    for t = 1:total_physics_steps
        
        % --- INPUT ---
        if strcmp(user_action, 'w')
            state.soil = 100;
            state.emoji = '<3'; % Love/Thanks Face
            user_action = ''; 
        end
        
        % Time
        virt_hour = mod(t / steps_per_virt_hour, 24);
        is_night = (virt_hour < 6) || (virt_hour > 21);
        
        % --- PHYSICS ---
        if ~state.charging, state.battery = state.battery - rate.battery; end
        state.soil = state.soil - rate.soil;
        
        % --- LOGIC & EMOTION ---
        v_req = 0; target_pos = [];
        dist_dock = norm([bot.x bot.y] - dock_pos);
        
        % 1. CHARGE
        if state.charging
            state.battery = state.battery + rate.charge;
            mode_str = 'CHARGING'; color = 'm'; state.mode_code=4;
            state.emoji = 'zzZ'; % Sleeping while charging
            if state.battery >= 100, state.charging = false; end
        elseif state.battery < 20
            mode_str = 'LOW BATTERY'; color = 'r'; state.mode_code=4;
            state.emoji = '!_!'; % Panic Face
            target_pos = dock_pos; v_req = phys.max_speed;
            if dist_dock < 0.5, state.charging = true; end
            
        % 2. THIRST
        elseif state.soil < PLANT.thresh
            mode_str = 'THIRSTY'; color = 'c'; state.mode_code=2;
            target_pos = water_pos;
            if norm([bot.x bot.y] - water_pos) < 0.5
                v_req = 0; mode_str = 'WAITING...';
                state.emoji = 'O_O'; % Begging Face
            else
                v_req = phys.max_speed * 0.5;
                state.emoji = 'H2O?'; % Searching Face
            end
            
        % 3. SLEEP (NIGHT)
        elseif is_night
            mode_str = 'SLEEPING'; color = [0.3 0.3 0.3]; state.mode_code=3;
            target_pos = bed_pos;
            state.emoji = '-.-'; % Sleepy Face
            if norm([bot.x bot.y] - bed_pos) < 0.5
                v_req = 0; state.emoji = 'zzZ';
            else
                v_req = phys.max_speed;
            end
            
        % 4. PLAY (DAY)
        else
            mode_str = 'HAPPY'; color = 'g'; state.mode_code=1;
            target_pos = human_pos; v_req = phys.max_speed;
            if state.battery < 40
                state.emoji = '(:'; % Normal
            else
                state.emoji = 'xD'; % Energetic
            end
        end
        
        % Clamp
        state.battery = max(0, min(100, state.battery));
        state.soil = max(0, min(100, state.soil));
        
        % --- KINEMATICS ---
        if ~isempty(target_pos)
            des_theta = atan2(target_pos(2)-bot.y, target_pos(1)-bot.x);
            err = angdiff(bot.theta, des_theta);
            bot.theta = bot.theta + max(-3, min(3, 5*err)) * phys.dt;
            bot.x = bot.x + v_req * cos(bot.theta) * phys.dt;
            bot.y = bot.y + v_req * sin(bot.theta) * phys.dt;
        end
        
        if ~is_night && mod(t, 10) == 0
            human_pos = human_pos + [0.3*randn, 0.3*randn];
            human_pos = max(1, min(9, human_pos));
        end

        % --- RENDER ---
        if mod(t, render_skip) == 0
            log.bat(log_idx) = state.battery; 
            log.soil(log_idx) = state.soil;
            log.mode(log_idx) = state.mode_code;
            log.x(log_idx) = bot.x; log.y(log_idx) = bot.y;
            log_idx = log_idx + 1;
            
            th = 0:0.2:2*pi;
            set(h_bot, 'XData', bot.x + bot.radius*cos(th), 'YData', bot.y + bot.radius*sin(th), 'FaceColor', color);
            % UPDATE FACE POSITION AND TEXT
            set(h_face, 'Position', [bot.x, bot.y, 0], 'String', state.emoji);
            
            set(h_dir, 'XData', [bot.x, bot.x+bot.radius*cos(bot.theta)], 'YData', [bot.y, bot.y+bot.radius*sin(bot.theta)]);
            set(h_human, 'XData', human_pos(1), 'YData', human_pos(2));
            set(h_bar_batt, 'YData', [0 0 state.battery state.battery]);
            set(h_bar_soil, 'YData', [0 0 state.soil state.soil]);
            set(h_status, 'String', mode_str, 'Color', color);
            set(h_clock, 'String', sprintf('%02d:%02d', floor(virt_hour), floor(mod(virt_hour*60,60))));
            
            if is_night, set(h_night, 'FaceAlpha', 0.5); else, set(h_night, 'FaceAlpha', 0); end
            
            drawnow limitrate;
            if conf.export_video, writeVideo(v_writer, getframe(f)); end
        end
    end
    
    if conf.export_video, close(v_writer); end
    
    %% 5. ANALYTICS
    log.bat = log.bat(1:log_idx-1); log.soil = log.soil(1:log_idx-1);
    log.mode = log.mode(1:log_idx-1); log.x = log.x(1:log_idx-1); log.y = log.y(1:log_idx-1);
    
    figure('Name', 'Thesis Data Analysis', 'Color', 'white', 'Position', [100 100 1000 600]);
    
    subplot(2, 2, [1 2]);
    x_axis = linspace(0, 24, length(log.bat));
    plot(x_axis, log.bat, 'g', 'LineWidth', 2); hold on;
    plot(x_axis, log.soil, 'b', 'LineWidth', 2);
    yline(20, 'r--', 'Low Battery'); yline(PLANT.thresh, 'b--', 'Thirsty Threshold');
    xlabel('Virtual Hours'); ylabel('% Level'); 
    title(['Resource Cycle: ' PLANT.name]); legend('Battery', 'Soil'); grid on;
    
    subplot(2, 2, 3);
    histogram2(log.x, log.y, [10 10], 'DisplayStyle', 'tile');
    axis equal; axis([0 10 0 10]); title('Spatial Heatmap'); colorbar;
    
    subplot(2, 2, 4);
    counts = [sum(log.mode==1), sum(log.mode==2), sum(log.mode==3), sum(log.mode==4)];
    pie(counts, {'Happy', 'Thirsty', 'Sleeping', 'Charging'});
    title('State Distribution');
    
    disp('Simulation Complete.');
end

function key_callback(~, event)
    global user_action;
    user_action = event.Key;
end

function d = angdiff(a, b)
    d = atan2(sin(b-a), cos(b-a));
end