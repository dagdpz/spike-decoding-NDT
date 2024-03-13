function dateOfRecording = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(injection)
% Choose which set of dates to use: 'control' or 'injection'

% for the 1 experiment: Functrional interactions between dPul and LIP
if strcmp(injection , '2')
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
    dateOfRecording = {
        '20210520' % - these files are missing in the population-file format in the : \dPul_control_LIP_Lin_8sL
        '20210610'
        '20210616'
        '20210709'
        '20210901'
        '20211006'
        '20211021'
        '20211126'
        '20211201'
        '20211208'
        };
elseif strcmp(injection, '0') % '0' means 'control'
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

% % filelist_of_days_from_Simultaneous_dPul_PPC_recordings
%
% %% control
% % dateOfRecording = {
% %     '20211109'
% %     '20211110'
% %     '20211111'
% %     '20211112'
% %     '20211117'
% %     '20211118'
% %     '20211119'
% %     '20211124'
% %     };
% % '20211111'
% % '20211112'
% % '20211117'
% % '20211118'
% % '20211119'
% % '20211124'
%
%
% %% injection
% dateOfRecording = {
%     '20210520'
%     '20210610'
%     '20210616'
%     '20210709'
%     '20210901'
%     '20211006'
%     '20211021'
%     '20211126'
%     '20211201'
%     '20211208'
%     };