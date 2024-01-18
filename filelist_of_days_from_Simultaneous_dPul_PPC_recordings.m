function dateOfRecording = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(injection)
    % Choose which set of dates to use: 'control' or 'injection'
    if strcmp(injection , '0') % '0' means 'control'
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
    elseif strcmp(injection, '1') % '1' means 'injection'
        % Injection dates
        dateOfRecording = {
            '20210520'
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