% MATLAB Code of Function Named makeMILPMatrices;;

function [f,A,b,staffIDVector] = makeMILPMatrices(staff_table,requirements)
%% 3. Conversion into intlinprog
% Staff information and requirements get converted for intlinprog.
 
numStaff = size(staff_table,1);% Available staff number has been read.
level_req = requirements(3,:)';
% Initializing some variables.
totalHourMatrix = [];
staffIDVector = [];
staffIDEntryCount = [];
f = []; % Cost vector is being created for the linear programming.
%% 4. Generating working hour instance possibilities
 
for n = 1:numStaff % For each worker...
    Minimum_Hours = staff_table.Minimum_Hours(n); % Minimum and maximum hour values are being read here.
    Maximum_Hours = staff_table.Maximum_Hours(n);
    hourMatrix = [];
    
    for hours = Minimum_Hours:Maximum_Hours % ...generating all possible working hours.
        hourVector = zeros(1,24);
        hourVector(1:hours) = 1;
        
        % Gallery function makes a circulant matrix so that the hourvector
        % can loop back into the morning if needed. If any worker will be
        % working after 22 for instance, and need to work for 6 hours this
        % will help the system to read from 0 after midnight. 
        % So it will be like 22, 23, 0, 1, 2, 3
        
        newHourMatrix = (gallery('circul',hourVector)');
        hourMatrix = [hourMatrix newHourMatrix];
    end
    
%% 5. Filtering out the non available worker situations from all possibilities.
    
    % If needed, we must filter out entry values that are not in range of
    % availability_times.
    availableTimes = staff_table.availability_times(n);
    if iscell(availableTimes)
        availableTimes = availableTimes{1};
        % This is producing a cell for available times.
    end
    if ~isnan(availableTimes)
        available = false(24,1);
        % Conversion starts here from text (ex: "6-12") here...
        availableTimes = regexp(availableTimes,'\d+-\d+','match');
        for k = 1:numel(availableTimes)
            % ...to numerical MATLAB values here. (ex: [6 12])
            startStopTimes = sscanf(availableTimes{k},'%d-%d');  
            available(startStopTimes(1)+1:startStopTimes(2)) = true;
            % Now the available times get implemented onto arrays to
            % evaluate to see the possibilities with a limited availability
            % worker.
        end
        % On this one if a worker is unavailable logical values get 0 on that time for that worker.
        hourMatrix = hourMatrix(:,~any(bsxfun(@and,~available,hourMatrix)));
    end
    
%% 6. Filtering out the non sufficient worker skill situations from all possibilities.
 
    skill_level = staff_table.skill_level(n);
     sufficient = false(24,1);
        for m = 1:24
            if skill_level>=level_req(m)
                sufficient(m)=true;
            end
        end
        % Likewise, if skill levels are insufficient for a task for each
        % individual worker, logical values get set to 0.
    hourMatrix = hourMatrix(:,~any(bsxfun(@and,~sufficient,hourMatrix)));
 
    %totalhourmatrix will collect every possibility.
    totalHourMatrix = [totalHourMatrix hourMatrix];
    
%% 7. Keeping the choices made in the memory and getting the optimum solution for this generation.
    
    % Keeping the track of the columns that are for every employee. This will help us
    % us to draw the plots with the information.
    staffIDEntryCount(n) = size(hourMatrix,2);
    staffIDVector = [staffIDVector repmat(n,1,staffIDEntryCount(n))];
    
    % Wages are total hours worked * hourly wage
    f = [f sum(hourMatrix)*staff_table.Hourly_Worker_Wage(n)];
end
%% 8. Setting constraints
 
% Constraint: The total working hours has to be greater than or equal to the required hours.
A_hours = totalHourMatrix;
b_hours = requirements(2,:)';
 
 
% Constraint: Any worker can only go to work once a day.
A_oneTime = arrayfun(@(n)ones(1,n), staffIDEntryCount,'UniformOutput',false);
A_oneTime = blkdiag(A_oneTime{:});  % blkdiag will have every possible outcome together in a matrix to compare.
b_oneTime = ones(numStaff,1);       % now, we see the ones which means after the comparison, the instances where a worker goes to work more than once will be eliminated.
 
%% 9. Combine both of the constraints into one A and b matrix
 
% These are the constraints after eliminated values.
% We apply a (-) to the Hours constraint, because Ax >= b means -Ax <= -b.
A = [-A_hours; A_oneTime];
b = [-b_hours; b_oneTime];
% A is the matrix that in which every column represents a working schedule
% for every worker.
% In A matrix, the first rows represent the time values, and the first
% columns represent the individual workers. For every worker situation it
% gets repeated and in the end the selection is made from this matrix.
 
end

