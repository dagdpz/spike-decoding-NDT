function  dateOfRecording = filelist_of_days_from_Simultaneous_dPul_PPC_recordings(monkey, injection, typeOfSessions)
% Choose which set of dates to use:

% Experiment 1:
% Functional interactions between the dorsal pulvinar and LIP during spatial target selection and oculomotor planning
if strcmp(injection , '2') && strcmp(typeOfSessions, ' ')
    
    if strcmp(monkey, 'Linus')
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
        
    elseif strcmp(monkey, 'Bacchus')
        dateOfRecording = {
            '20200325'
            '20200409'
            '20200423'
            '20200513'
            '20200522'
            '20200530'
            '20200619'
            '20200624'
            '20200626'
            };
    end
    
    % Experiment 2:
    % The effect of unilateral dorsal pulvinar inactivation on bi-hemispheric LIP activity
elseif strcmp(injection, '1') % '1' means 'injection sessions'
    
    if strcmp(monkey, 'Linus')
        
        if strcmp(typeOfSessions, 'right')
            dateOfRecording = { % - right dPul injection (7 sessions)
                '20210520'
                '20210610'
                '20210616'
                '20210709' % only one post-inj block !
                '20210901'
                '20211006'
                '20211021'
                };
            
        elseif strcmp(typeOfSessions, 'left')
            dateOfRecording = { % - left dPul injection (3 sessions)
                '20211126'
                '20211201'
                '20211208'
                };
            
        elseif strcmp(typeOfSessions, 'all')
            dateOfRecording = transpose([ ...  % Include both right and left dPul inj sessions
                {'20210520', '20210610', '20210616', '20210709', '20210901', '20211006', '20211021'}, ... % right dPul inj
                {'20211126', '20211201', '20211208'}]); % left dPul inj
        else
            error('Invalid selection. Use ''right'', ''left'', or ''all'' for type.');
        end
        
        
    elseif strcmp(monkey, 'Bacchus')
        
        if strcmp(typeOfSessions, 'right')
            dateOfRecording = { % - right dPul injection (7 sessions)
                '20201112'
                '20201119'
                '20201126'
                '20201203'
                '20201217'
                '20210225'
                '20210304'
                % '20210311' - doesn't exist in folder /dPul_inj_LIP_Bac_8s_paired/
                };
        else
            error('Invalid selection. Use only ''right'' for type for Bacchus.');
        end
    end
    
elseif strcmp(injection, '0') && strcmp(typeOfSessions, ' ') % '0' means 'control sessions'
    
    if strcmp(monkey, 'Linus')
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
        
    elseif strcmp(monkey, 'Bacchus')
        dateOfRecording = {
            '20201209'
            '20210127'
            '20210203'
            '20210205'
            '20210317'
            '20210325'
            '20210401'
            };
    end
else
    error('Invalid selection. Use ''control'' or ''injection'' for selectedSet.');
end
end
