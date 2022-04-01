%MATLAB Main Code For Worker Scheduling;;

clc;
clear;
close all;
%% 1. Read Problem Requirements & Constraints
 
disp("Reading problem requirements...")
filename = 'scheduling.xlsx';
staff_table = readtable(filename);
requirements = xlsread(filename,2); %Minimum staff requirements have been read from the second sheet of scheduling.xlsx
disp("Reading successful.")
disp("Problem requirements: ")
disp('Required staffing (hourly from 0:00 - 24:00): ');
disp(mat2str(requirements(2,:)));
 
%% 2. Define Lin. Problem Elements % Solve
 
% f,A,b are the input values for our MILP problem.
% staffNumberVector is going to be needed in interpreting.
% at this point, please look into makeMILPMatrices function to further
% understand what steps were utilized.
% A matrix will store every instance and eliminate the impossible ones.
% b array will store the requirements and will have a part in comparing constraints.
% f array is going to store the objective.
[f,A,b,staffIDVector] = makeMILPMatrices(staff_table,requirements); 
 
nVars = numel(f);       % Number of variables are determined.
lb = zeros(nVars,1);    % The upper bound and lower bound are set 0 and 1.
ub = ones(nVars,1);
[x, cost, EXITFLAG] = intlinprog(f,1:nVars,A,b,[],[],lb,ub);
 
% There have been a problem in our ninth instance of sensitivity analysis. 
% This was caused by thefact that the intlinprog have been accepting 
% values as double. Because of this, the values which were very very close 
% to our needed actual valuehave been picked (by 0.2096*10^-10). Because 
% of this, we had to make this arrangement. After rounding, the integer 
% values will be implemented as it was planned on the schedule.
 
x = round(x); 
 
%% 10. Determination of the solution quality by EXITFLAG values
 
if     EXITFLAG==1
    %optimal solution found.
    disp("Since EXITFLAG value was equal to 1, it is shown that we have the optimal solution without any complications.")
elseif EXITFLAG==2
    %solver stopped prematurely. Integer feasible point found.
    disp("This EXITFLAG value means that the solver encountered a feasible integer point prematurely before reaching the end of program. This means that the solver was having unnecessary actions.")
elseif EXITFLAG==3
    %optimal solution found with poor constraint feasibility.
    disp("EXITFLAG value was equal to 3, so feasibility according to these constraints were low. There was not much choices to be made according to this output.")
elseif EXITFLAG==0
    %solver stopped prematurely. No integer feasible point found.
    disp("Solved has been stopped prematurely for any reason, but there was no integer points which was feasible so far.")
elseif EXITFLAG==-1
    %solver stopped by an output function or plot function.
    disp("The solver has been terminated from within the code.")
elseif EXITFLAG==-2
    %no feasible point fou5nd.
    disp("There was no feasible point found, in this case workers can not handle the constraints. Try again with different parameters.")
elseif EXITFLAG==-3
    %root LP problem is unbounded.
    disp("The values of the objective function value can take are unbounded, since the solution goes into infinity. Try again with different constraints.")
elseif EXITFLAG==-9
    %solver lost feasibility probably due to ill-conditioned matrix.
    disp("Perhaps there is a matrix boundary mistake, these matrices are getting too big to handle by the solver. Solver lost feasibility.")
else
    disp("No valid EXITFLAG value have been read. Most likely, there is a technical problem.")
end
 
%% 11. Decode Problem outcome to original components
 
numStaff = size(staff_table,1); % Total number of staff available
 
% Convert from indices in x to employee and shift information
 
 
selectedInstances = find(x); % This is going to find every instance that has had a logical 1 value 
staffSchedule = zeros(numStaff,24); % schedule is being created
 
for n = 1:numel(selectedInstances) % For every selected worker;
    selectedInstance = selectedInstances(n);   
    staffID = staffIDVector(selectedInstance); % Kept info from the function.
    staffDailySchedule = -A(1:24,selectedInstance); % Takes - values because of the constraints
    staffSchedule(staffID,:) = staffDailySchedule; % Daily schedule has been made
end
selectedworkercount = length(selectedInstances);
if selectedworkercount > 0 && selectedworkercount < 46
fprintf('The selected worker count is %d. \n',selectedworkercount);
elseif selectedworkercount == 0
    disp('Workers count not be scheduled with these settings.');
end
 
    %% 12. Plot Figures
 
% Make a figure in a suitable location
hf = figure('units','pixel','position',[380 50 700 700]);  % Position, length and width
 
% Drawing the employee work schedule matrix.
subplot(2,1,1);
imagesc(0.5:23.5,1:numStaff,staffSchedule) %Plot is getting implemented in schedule
set(gca,'xtick',0:24);
set(gca,'ytick',1:numStaff,'yticklabel',staff_table.Employee_Name,'FontSize',5);
hold all;
xlabel('Time of the day','fontsize',12);
ylabel('Employee Name','FontSize',12);
 
% Grid lines have caused us a lot of problems because of the colors, colors
% make grid lines almost invisible and they just go from the center. This
% is not what we want so we will just put some space in for the y axis.
for n = 0.5:numStaff+0.5
    plot(xlim,[n n],'k');
end
for n = 0:24
    plot([n n], ylim,'k');
end
% This is to make the title to be 2 lined.
title(['Employee shift schedule' 10 ...
       'Total wages over 24 hours: $' num2str(cost)],'FontSize',16);
   
% Drawing the required and actual staff comparison
subplot(2,1,2);
% Making a blue line for requirements
plot(0.5:23.5,requirements(2,:),'b.-','linewidth',3,'markersize',30);
hold on;
% Normal crossed matrix, this will essentially keep all the 1 values and
% cross it with x's values to get the total number of hourly working
% workers' times
actualHours = -A(1:24,:)*x;
% Next one will be more narrow than the first one so we can see. It's going
% to be red.
plot(0.5:23.5,actualHours,'r:.','linewidth',2,'markersize',16);
xlim([0 24]);
set(gca,'xtick',0:24,'ytick',0:20);
ylim([0 20]);
grid on;
title(['Hourly Staff Count'],'FontSize',16);
legend({'Employees Required', 'Employees Scheduled'});
xlabel('Time of the day','fontsize',12);
ylabel('Employee count','fontsize',12);
