function dateOfRecording = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(injection)
% Choose which set of dates to use: 'control' or 'injection'

% for the 1 experiment: Functrional interactions between dPul and LIP
if strcmp(injection , '0') % '0' means experiment 1 
    % Control dates
    dateOfRecording = {
        '20211109'
        '20211110'
        '20211111'
        '20211112'
        '20211117'
        '20211118'
        '20211119'
        '20211124'
        };
    
% for the 2 experiment: inactivation of dPul
elseif strcmp(injection, '1') % '1' means 'injection'
    % Injection dates
    dateOfRecording = { % - these files are missing in the population-file format in the : \dPul_control_LIP_Lin_8sL
        '20210520' % - right dPul inj
        '20210610' % - right dPul inj
        '20210616' % - right dPul inj
        '20210709' % - right dPul inj
        '20210901' % - right dPul inj
        '20211006' % - right dPul inj
        '20211021' % - right dPul inj
%         '20211126' % - left dPul inj
%         '20211201' % - left dPul inj
%         '20211208' % - left dPul inj
        };
elseif strcmp(injection, '2') % '0' means 'control'
    % Injection dates
    dateOfRecording = {
        '20210623'
        '20210729'
        '20210910'
        '20211013'
        '20211028'
        '20211029'
        '20211203'
        '20211210'
        };
else
    error('Invalid selection. Use ''control'' or ''injection'' for selectedSet.');
end
end
