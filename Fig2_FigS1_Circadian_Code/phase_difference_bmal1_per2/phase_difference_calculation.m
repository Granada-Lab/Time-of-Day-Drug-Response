function phase_difference_calculation

%Carolin Ector, 23.08.2023

%Function utilizes code of the Circular Statistics Toolbox Version 1.21.0.0 by Philipp Berens
%Function calculates phase differences between Bmal1 and Per2 signals per cell line
%replicates stem from the same experiment

%Time-of-Day-Cancer-Drugs Manuscript Fig. S1b

path = 'pyBOAT_ridge_readout_threshold_halfmax/';
reporter = {'BMAL1';'PER2'}; %luciferase reporters
outputfile1 = 'phase_difference_circular_statistics.xlsx';
cellline = 'MDAMB468';

%% load and save data

rep = (1:1:3);
rr = numel(rep);

for r = 1:rr %loop r replicates

    replicate_str = num2str(rep(:,r));
    file = append(cellline,'_',reporter{b},'_',replicate_str,'_ridgeRO.csv');

    pathtofile = append(path,file);
    [table_pyboatdata] = readtable(pathtofile);
    pyboatdata = table2array(table_pyboatdata);

    %load data
    time = pyboatdata(:,1);
    data = pyboatdata(:,3);
    period = pyboatdata(:,2);

    %exclude phases of corresponding periods that are above 32 hours
    indices = find(abs(period)>32);
    data(indices) = [];
    time(indices) = [];

    %exclude phases of corresponding periods after sudden jumps in periods
    ipt = findchangepts(period);
    valuebeforeipt = period(ipt-1,:);
    valuebeafteript = period(ipt,:);
    diff = valuebeafteript - valuebeforeipt;
    rowbeforejump = min(find(period == valuebeforeipt));

    if diff > 1
        time = time(1:rowbeforejump,:);
        data = data(1:rowbeforejump,:);
    end

    %exclude phases after time jumps
    for i=2:length(time)-1 % Exclude first and last values in series so y(i-1) and y(i+1) actually do exist
        timediff = time(i)-time(i-1);
        if timediff > 0.18
            break
        end % Ends the 'if' statement at this point.
    end

    time = time(1:i-1,:);
    data = data(1:i-1,:);

    %process data
    mintime = min(time);
    maxtime = max(time);

    %add NaN to missing time points
    if mintime ~= 0
        coltoadd1 = numel(0:0.1666666667:mintime);
        emptycols1(1:coltoadd1,:) = NaN;
        data = [emptycols1;data];
        clear coltoadd1
        clear emptycols1
    end

    %exclude timepoints longer than 120h
    if maxtime < 120
        coltoadd2 = numel(maxtime:0.1666666667:120);
        emptycols2(1:coltoadd2,:) = NaN;
        data = [data;emptycols2];
        clear coltoadd2
        clear emptycols2
    end

    allcols = size(data,1);

    if allcols > 720
        data = data(1:720,:);
    end

    if b == 1
        phases_bmal(:,r) = data;
    elseif b == 2
        phases_per(:,r) = data;
    end

    vars = {'data','period','time'};
    clear(vars{:})

end %loop r replicates

end %loop b reporter

%% process and plot data

combi = rr*rr; %possible phase difference combinations
plotID = (1:1:combi);

for rp = 1:rr %loop per2
    nr_per = num2str(rep(:,rp)); %number of replicate per
    for rb = 1:rr %loop bmal1
        nr_bmal = num2str(rep(:,rb)); %number of replicate bmal
        combinations{rp,rb} = append('PER2(',nr_per,')-BMAL1(',nr_bmal,')');
        diff_rel{rp,rb} = (phases_per(:,rp)-phases_bmal(:,rb));
    end
end

%organize diff_rel array to one column
if rr > 1
    diff_rel_organized = [diff_rel(:,1);diff_rel(:,2)];
    combinations_organized = [combinations(:,1);combinations(:,2)];
    if rr > 2
        diff_rel_organized = [diff_rel_organized(:,1);diff_rel(:,3)];
        combinations_organized = [combinations_organized(:,1);combinations(:,3)];
        if rr > 3
            diff_rel_organized = [diff_rel_organized(:,1);diff_rel(:,4)];
            combinations_organized = [combinations_organized(:,1);combinations(:,4)];
            if rr > 4
                diff_rel_organized = [diff_rel_organized(:,1);diff_rel(:,5)];
                combinations_organized = [combinations_organized(:,1);combinations(:,5)];
                if rr > 5
                    diff_rel_organized = [diff_rel_organized(:,1);diff_rel(:,6)];
                    combinations_organized = [combinations_organized(:,1);combinations(:,6)];
                end
            end
        end
    end
else
    diff_rel_organized = diff_rel;
    combinations_organized = combinations;
end

fig1 = figure;%('visible','off');

for p = 1:combi
    phdiff(:,p)=atan2(sin(cell2mat(diff_rel_organized(p,:))),cos(cell2mat(diff_rel_organized(p,:))));
    subplot(rr,rr,plotID(:,p));
    y1 = rmmissing(phdiff(:,p));
    plot(y1,'LineWidth',2);
    ax = gca;
    subtitletext = append(combinations_organized(p,:));
    title(subtitletext,'FontSize',10,'FontName','Helvetica Neue');
    xlim([0 720]); xticks(0:144:720); xticklabels({'0','1','2','3','4','5'});
    ylim([-pi pi]);yticks(-pi:pi:pi); yticklabels({'-π','0','π'});
    set(ax,'XLimitMethod', 'padded','YLimitMethod', 'padded','linewidth',1.5,'YGrid','off',...
        'XGrid','off','Box','on','Color','none','FontSize',11,'FontName','Helvetica Neue');
end

han=axes(fig1,'visible','off');
han.XLabel.Visible='on';
han.YLabel.Visible='on';
xlabel(han,'Time [days]','FontSize',12,'FontName','Helvetica Neue');
ylabel(han,'Phase [rad]','FontSize',12,'FontName','Helvetica Neue');

fig = figure;
fig.Position = [1,66,1440,731];

for e = 1:combi
    subplot(rr,rr,plotID(:,e));
    data_array = cell2mat(diff_rel_organized(e,:));
    alpha = rmmissing(data_array);
    polarhistogram(alpha, 20, 'Normalization', 'pdf','FaceAlpha',0.4); hold all;
    R = circ_r(alpha);
    c_mean(e,c) = circ_mean(alpha);
    c_median(e,c) = circ_median(alpha);
    c_var(e,c) = circ_var(alpha);
    polarplot(circ_median(alpha),R,'o','MarkerSize',7,'Color','b','LineWidth',2);
    medianstring = string(round(circ_median(alpha),3));
    polarplot(circ_mean(alpha),R,'*','MarkerSize',7,'Color','r','LineWidth',1); hold all
    meanstring = string(round(circ_mean(alpha),3));
    varstring = string(round(circ_var(alpha),3));
    if isnan(c_var(e,c))
        varstring = 'NaN';
    end
    pax = gca;
    pax.ThetaAxisUnits = 'radians';
    legend(varstring,medianstring,meanstring,'Location','eastoutside','FontSize',8,'FontName','Helvetica Neue');
    subtitletext = append(combinations_organized(e,:));
    title(subtitletext,'FontSize',10,'FontName','Helvetica Neue');
    set(gca,'linewidth',1.5,'FontSize',10,'FontName','Helvetica Neue');
    vars2 = {'data_array','alpha'};
    clear(vars2{:});
end

disp(cellline);

hold off

han=axes(fig,'visible','off');

han.Title.Visible='on';
titletext = append(cellline);
title(han,titletext,'FontSize',12,'FontName','Helvetica Neue');

%save figure
filetext = append('phdiff_over_time_',cellline,'.svg');
saveas(fig1, filetext);

clf(fig1)

end

c_mean(c_mean == 0) = NaN;
c_median(c_median == 0) = NaN;
c_var(c_var == 0) = NaN;

c_mean_exp1 = c_mean;
c_median_exp1 = c_median;
c_var_exp1 = c_var;

clear c_mean
clear c_median
clear c_var

for s = 1:cc

    %% mean per experiment

    for f = 1:3 %loop values
        if f == 1
            x = rmmissing(c_mean_exp1(:,s));
        elseif f == 2
            x = rmmissing(c_median_exp1(:,s));
        elseif f == 3
            x = rmmissing(c_var_exp1(:,s));
        end
        mean_exp1(f,s) = mean(x,1,'omitnan');
        std_exp1(f,s) = std(x,[],1,'omitnan');
        disp(cellline{s});
        clear x
    end
end

outputsheet3 = {'mean_phdiff';'median_phdiff';'coeffvar_phdiff'};
variables3 = {c_mean_exp1,c_median_exp1,c_var_exp1};

for q = 1:3
    table3 = array2table(variables3{q},'VariableNames',transpose(cellline));
    writetable(table3,outputfile1,'sheet',outputsheet3{q});
    clear table3
end

%export mean per experiment

allreplicates = {'mean_phdiff';'median_phdiff';'coeffvar_phdiff'};

table2 = array2table((mean_exp1),'VariableNames',transpose(cellline));
t_varnames2 = cell2table(allreplicates);
table2 = [t_varnames2,table2];
writetable(table2,outputfile1,'sheet','phdifference');
clear table2
end