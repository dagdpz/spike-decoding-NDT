function [hp1 hp2] = ig_errorband(x,y,e,type,varargin)
%IG_ERRORBAND		- errorband plot
% ig_errorband(1:100,rand(1,100),randn(1,100)/5,0,'LineWidth',2,'Color',[0 0 1])

if nargin < 4,
        type = 0; % 0-patch, 1-line, 2-errorbar
end

if size(x,1) > 1,
        x = x';
end

if size(y,1) > 1,
        y = y';
end

if size(e,1) > 1,
        e = e';
end


switch type
        
        case 0,
                hp2 = patch([x fliplr(x)],[y+e fliplr(y-e)],'k','EdgeColor','none','FaceColor',[0 0 0],'FaceAlpha',0.5); hold on;
                hp1 = plot(x,y,'k',varargin{:});
                set(hp2,'FaceColor',get(hp1,'Color'));
        case 1,
                hp2 = line([x NaN fliplr(x)],[y+e NaN fliplr(y-e)],varargin{:},'LineStyle','-','LineWidth',0.5); hold on;
                hp1 = plot(x,y,'k',varargin{:});
        case 2,
                hp1 = errorbar(x,y,e); hold on;
                set(he,varargin{:});
		hp2 = [];
end