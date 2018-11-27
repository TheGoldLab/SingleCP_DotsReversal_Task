function topNode =  configure_task(varargin)
%% function topNode =  SingleCPReversingDots_configure(varargin)
%
% This function sets up a Single change point reversing dots experiment. 
% It follows the organization of the DBSconfigure.m script.
%
% Arguments:
%  varargin  ... optional <property>, <value> pairs for settings variables
%                 note that <property> can be a cell array for nested
%                 property structures in the task object
%
% Returns:
%  mainTreeNode ... the topsTreeNode at the top of the hierarchy
%
% 10/30/18   aer wrote it

%% ---- Parse arguments for configuration settings
%
% Name of the experiment, which determines where data are stored
name = 'SingleCPDotsReversal';

% Other defaults
settings = { ...
   'taskSpecs',                  {'Quest' 1 'CP' 1}, ...
   'runGUIname',                 [], ...
   'databaseGUIname',            [], ...
   'remoteDrawing',              true, ...
   'instructionDuration',        10.0, ...
   'displayIndex',               1, ... % 0=small, 1=main
   'readables',                  {'dotsReadableEyePupilLabs'}, ...
   'doCalibration',              true, ...
   'doRecording',                true, ...
   'queryDuringCalibration',     false, ...
   'sendTTLs',                   false, ...
   'targetDistance',             10, ...
   'gazeWindowSize',             6, ...
   'gazeWindowDuration',         0.15, ...
   'saccadeDirections',          0:90:270, ...
   'dotDirections',              [0 180], ...
   'dotCoherences',              50, ...
   'trialTimes',                 .1:.1:.5, ...
   'changePointProb',            .5, ...
   'referenceRT',                500, ... % for speed feedback  
   'showFeedback',               true, ...
   'smiley',                     {'smiley.jpg'}, ... % feedback
   'goodJob',                    {'GoodJob.jpg'}, ...
   };

% Update from argument list (property/value pairs)
for ii = 1:2:nargin
   settings{find(strcmp(varargin{ii}, settings),1) + 1} = varargin{ii+1};
end

%% ---- Create topsTreeNodeTopNode to control the experiment
%
% Make the topsTreeNodeTopNode
topNode = topsTreeNodeTopNode(name);

% Add a topsGroupedList as the nodeData, plus other fields, then configure
topNode.nodeData = topsGroupedList.createGroupFromList('Settings', settings);

% Add GUIS. The first is the "run gui" that has some buttons to start/stop
% running and some real-time output of eye position. The "database gui" is
% a series of dialogs that execute at the beginning to collect subject/task
% information and store it in a standard format.
topNode.addGUIs('run', topNode.nodeData{'Settings'}{'runGUIname'}, ...
   'database', topNode.nodeData{'Settings'}{'databaseGUIname'});


% ------- OLD SYNTAX
% Add the screen and feedback drawable ensemble
%
%topNode.addSharedDrawables( ...
%   topNode.nodeData{'Settings'}{'displayIndex'}, ...
%   topNode.nodeData{'Settings'}{'remoteDrawing'}, ...
%   {'dotsDrawableText', 'dotsDrawableText', 'dotsDrawableImages', 'dotsDrawableImages'}, ...
%   {{'isVisible', false}, {'isVisible', false}, ...
%   {'isVisible', false, 'height', 2, 'fileNames', topNode.nodeData{'Settings'}{'smiley'}}, ...
%   {'isVisible', false, 'height', 10, 'fileNames', topNode.nodeData{'Settings'}{'goodJob'}}}, ...
%   true, true);
         
% Add the user interface device(s) with default settings
% is it here that  I should define the mapping from button/key presses to
% events?
%topNode.addSharedReadables(topNode.nodeData{'Settings'}{'uiList'}, [], ...
%   topNode.nodeData{'Settings'}{'doCalibration'}, ...
%   topNode.nodeData{'Settings'}{'doRecording'});
% ------- OLD SYNTAX

% Add the screen ensemble as a "helper" object. See
% topsTaskHelperScreenEnsemble for details
topNode.addHelpers('screenEnsemble',  ...
   topNode.nodeData{'Settings'}{'displayIndex'}, ...
   topNode.nodeData{'Settings'}{'remoteDrawing'}, ...
   topNode);

% Add a basic feedback helper object, which includes text, images,
% and sounds. See topsTaskHelperFeedback for details.
topNode.addHelpers('feedback');

% Add readable(s). See topsTaskHelperReadable for details.
readables = topNode.nodeData{'Settings'}{'readables'};
for ii = 1:length(readables)
   topNode.addHelpers('readable', readables{ii}, topNode);

   % Possibly set default gaze window size, duration
   if isa(topNode.helpers.(readables{ii}).theObject, 'dotsReadableEye')
      topNode.helpers.(readables{ii}).theObject.setGazeWindows( ...
         topNode.nodeData{'Settings'}{'gazeWindowSize'}, ...
         topNode.nodeData{'Settings'}{'gazeWindowDuration'});
   end
end



% Add playables (feedback sounds)
%topNode.addSharedPlayables( ...
%   topNode.nodeData{'Settings'}{'playables'}, ...
%   {'isBlocking', false});

% %% ---- Make call lists to show text/images between tasks
% %
% %  Use the sharedHelper drwawableEnsemble
% %
% % Welcome call list
% welcome = topsCallList();
% welcome.alwaysRunning = false;
% paceStr = 'Work at your own pace.';
% strs = { ...
%    'dotsReadableEye',         paceStr, 'Each trial starts by fixating the central cross.'; ...
%    'dotsReadableHIDButtons',  paceStr, 'Each trial starts by pushing either button.'; ...
%    'dotsReadableHIDKeyboard', paceStr, 'Each trial starts by pressing the space bar.'; ...
%    'default',                 'Each trial starts automatically.',      ''};
% strind = size(strs,1);
% if ~isempty(topNode.sharedHelpers.readables)
%     strind = find(cellfun(@(x) isa(topNode.sharedHelpers.readables{1}, x), strs(1:end-1,1)));
% end    
% welcome.addCall({@dotsDrawableText.drawEnsemble, ...
%    topNode.sharedHelpers.drawables, strs(strind, 2:3), true, 2}, 'Welcome');
% 
% % Countdown call list
% countdown = topsCallList();
% countdown.alwaysRunning = false;
% countdown.addCall({@dotsDrawable.drawEnsemble, ...
%       topNode.sharedHelpers.drawables, { ...
%       {'isVisible', true, 'y', -9}, ...
%       {'isVisible', false,}, ...
%       {'isVisible', false}, ...
%       {'isVisible', true, 'y', 1, 'height', 13, ...
%       'width', [], 'fileNames', topNode.nodeData{'Settings'}{'goodJob'}}}, ...
%       true}, 'set');
% for ii = 1:10
%    countdown.addCall({@dotsDrawable.drawEnsemble, ...
%       topNode.sharedHelpers.drawables, { ...
%       {'string', sprintf('Next task starts in: %d', 10-ii+1)}}, ...
%       false, 1, 0}, sprintf('text%d', ii));
% end
%    



%% ---- Make call lists to show text/images between tasks
%
%  Use the sharedHelper screenEnsemble
%
% Welcome call list
paceStr = 'Work at your own pace.';
strs = { ...
   'dotsReadableEye',         paceStr, 'Each trial starts by fixating the central cross.'; ...
   'dotsReadableHIDGamepad',  paceStr, 'Each trial starts by pulling either trigger.'; ...
   'dotsReadableHIDButtons',  paceStr, 'Each trial starts by pushing either button.'; ...
   'dotsReadableHIDKeyboard', paceStr, 'Each trial starts by pressing the space bar.'; ...
   'default',                 'Each trial starts automatically.', ''};
for index = 1:size(strs,1)
   if ~isempty(topNode.getHelperByClassName(strs{index,1}))
      break;
   end
end
welcome = {@show, topNode.helpers.feedback, 'text', strs(index, 2:3), ...
   'showDuration', topNode.nodeData{'Settings'}{'instructionDuration'}};

% Countdown call list
callStrings = cell(10, 1);
for ii = 1:10
   callStrings{ii} = {'string', sprintf('Next task starts in: %d', 10-ii+1), 'y', -9};
end
countdown = {@showMultiple, topNode.helpers.feedback, ...
   'text', callStrings, 'image', {2, 'y', 4, 'height', 13}, ...
   'showDuration', 1.0, 'pauseDuration', 0.0, 'blank', false};



%% ---- Loop through the task specs array, making tasks with appropriate arg lists
%
taskSpecs = topNode.nodeData{'Settings'}{'taskSpecs'};
QuestTask = [];
noDots    = true;
for ii = 1:2:length(taskSpecs)
   
   % Make list of properties to send
   args = {taskSpecs{ii:ii+1}, ...
      {'settings',  'targetDistance'},       topNode.nodeData{'Settings'}{'targetDistance'}, ...
      {'settings',  'gazeWindowSize'},       topNode.nodeData{'Settings'}{'gazeWindowSize'}, ...
      {'settings',  'gazeWindowDuration'}, 	topNode.nodeData{'Settings'}{'gazeWindowDuration'}, ...
      {'timing',    'showInstructions_shi'},	topNode.nodeData{'Settings'}{'instructionDuration'}, ...
      'sendTTLs',                            topNode.nodeData{'Settings'}{'sendTTLs'}, ...
      'taskID',                              (ii+1)/2, ...
      'taskTypeID',  find(strcmp(taskSpecs{ii}, {'Quest' 'CP'}),1)};
   
   switch taskSpecs{ii}
      
      case {'VGS' 'MGS'}
         
         % Make Single CP reversing dots task with args
         task = topsTreeNodeTaskSingleCPDotsReversal.getStandardConfiguration( ...
            taskSpecs{ii}, taskSpecs{ii+1}, ...
            {'direction', {'values', topNode.nodeData{'Settings'}{'dotsDirections'}}}, ...
            args{:});
         
      otherwise
         
         % If there was a Quest task, use to update coherences in other tasks
         if ~isempty(QuestTask)
            args = cat(2, args, ...
               {{'settings' 'useQuest'},   QuestTask, ...
               {'settings' 'referenceRT'}, QuestTask});
         end
         
         % Make SingleCPDotsReversal task with args
         task = topsTreeNodeTaskSingleCPDotsReversal.getStandardConfiguration( ...
            taskSpecs{ii}, taskSpecs{ii+1}, ...
            {'direction', {'values', topNode.nodeData{'Settings'}{'dotDirections'}}, ...
            'coherence', {'values', topNode.nodeData{'Settings'}{'dotCoherences'}}, ...
            'TrialTimes', {'values', topNode.nodeData{'Settings'}{'trialTimes'}}, ...
            'CPP', {'values', topNode.nodeData{'Settings'}{'changePointProb'}}}, ...
            args{:});
         
         % Add special instructions for first dots task
         if noDots
            task.settings.textStrings = cat(1, ...
               {'When flickering dots appear, decide their overall direction', ...
               'of motion, then look at the target in that direction'}, ...
               task.settings.textStrings);
            noDots = false;
         end
         
         % Special case of quest ... use output as coh/RT refs
         if strcmp(taskSpecs{ii}, 'Quest')
            QuestTask = task;
         end
   end
   
   % Add some fevalables to show instructions/feedback before/after tasks
   if ii == 1
      task.addCall = {'start', welcome};
   else
      task.addCall = {'start', countdown};
   end
   
   % Add as child to the maintask.
   topNode.addChild(task);
end
