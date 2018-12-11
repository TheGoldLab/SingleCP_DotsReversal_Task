classdef topsTreeNodeTaskSingleCPDotsReversal < topsTreeNodeTask
    % @class topsTreeNodeTaskRTDots
    %
    % Response-time dots (RTD) task
    %
    % For standard configurations, call:
    %  topsTreeNodeTaskRTDots.getStandardConfiguration
    %
    % Otherwise:
    %  1. Create an instance directly:
    %        task = topsTreeNodeTaskRTDots();
    %
    %  2. Set properties. These are required:
    %        task.screenEnsemble
    %        task.helpers.readers.theObject
    %     Others can use defaults
    %
    %  3. Add this as a child to another topsTreeNode
    %
    % 11/28/18 created by aer / reviewed by jig
    
    properties % (SetObservable) % uncomment if adding listeners
        
        % Trial properties.
        %
        % Set useQuest to a handle to a topsTreeNodeTaskSingleCPDotsReversal to use it
        %     to get coherences
        % Possible values of dotsDuration:
        %     [] (default)        ... RT task
        %     [val]               ... use given fixed value
        %     [min mean max]      ... specify as pick from exponential distribution
        %     'indep'             ... specified in self.independentVariables
        settings = struct( ...
            'minTrialsPerCondition',      10,   ...
            'useQuest',                   [],   ...
            'coherencesFromQuest',        [],   ...
            'possibleDirections',         [0 180],   ...
            'directionPriors',            [], ... % change For asymmetric priors
            'referenceRT',                [],   ...
            'fixationRTDim',              0.4,  ...
            'targetDistance',             14,    ...
            'textStrings',                '',   ...
            'correctImageIndex',          1,    ...
            'errorImageIndex',            3,    ...
            'correctPlayableIndex',       1,    ...
            'errorPlayableIndex',         2);
        
        % Timing properties
        timing = struct( ...
            'showInstructions',          10.0, ...
            'waitAfterInstructions',     0.5, ...
            'fixationTimeout',           5.0, ...
            'holdFixation',              0.5, ...
            'showSmileyFace',            0.5, ...
            'showFeedback',              1.0, ...
            'interTrialInterval',        1.0, ...
            'preDots',                   [0.2 0.5 1.0],... % truncated exponential time between fixation and dots onset
            'dotsDuration1',             [],  ...
            'dotsDuration2',             [],  ...
            'dotsTimeout',               5.0, ...
            'choiceTimeout',             3.0);
        
        % Quest properties
        questSettings = struct( ...
            'stimRange',                 20*log10((0:100)/100),   ...
            'thresholdRange',            20*log10((1:99)/100),     ...
            'slopeRange',                1:5,      ...
            'guessRate',                 0.5,      ...
            'lapseRange',                0.00:0.01:0.05, ...
            'recentGuess',               []);
        
        % Fields below are optional but if found with the given names
        %  will be used to automatically configure the task
        
        % Array of structures of independent variables, used by makeTrials
        independentVariables = struct( ...
            'name',        {'initDirection', ...
            'coherence', ...
            'viewingDuration', ...
            'probCP', ...
            'timeCP'}, ...
            'values',      {[0 180], ...           %initDirection
            [6.4 12.8 25.6], ...     %coherence
            .1:.1:.3, ...                          %viewingDuration
            .5, ...                          %probCP
            .2}, ...                        %timeCP
            'priors',      {[], [], [], [], []});
        
        % dataFieldNames are used to set up the trialData structure
        trialDataFields = {'RT', 'choice', 'correct', ...
            'initDirection', 'endDirection', 'presenceCP', ...
            'coherence', ...
            'viewingDuration', ...
            'probCP', ...
            'timeCP', ...
            'randSeedBase', 'fixationOn', 'fixationStart', 'targetOn', ...
            'dotsOn', 'dotsOff', 'choiceTime', 'targetOff', 'fixationOff', 'feedbackOn'};
        
        % Drawables settings
        drawable = struct( ...
            ...
            ...   % Stimulus ensemble and settings
            'stimulusEnsemble',              struct( ...
            ...
            ...   % Fixation drawable settings
            'fixation',                   struct( ...
            'fevalable',                  @dotsDrawableTargets, ...
            'settings',                   struct( ...
            'xCenter',                    0,                ...
            'yCenter',                    0,                ...
            'nSides',                     4,                ...
            'width',                      1.0.*[1.0 0.1],   ...
            'height',                     1.0.*[0.1 1.0],   ...
            'colors',                     [1 1 1])),        ...
            ...
            ...   % Targets drawable settings
            'targets',                    struct( ...
            'fevalable',                  @dotsDrawableTargets, ...
            'settings',                   struct( ...
            'nSides',                     100,              ...
            'width',                      1.5.*[1 1],       ...
            'height',                     1.5.*[1 1])),      ...
            ...
            ...   % Smiley face for feedback
            'smiley',                     struct(  ...
            'fevalable',                  @dotsDrawableImages, ...
            'settings',                   struct( ...
            'fileNames',                  {{'smiley.jpg'}}, ...
            'height',                     2)), ...
            ...
            ...   % Dots drawable settings
            'dots',                       struct( ...
            'fevalable',                  @dotsDrawableDotKinetogram, ...
            'settings',                   struct( ...
            'xCenter',                    0,                ...
            'yCenter',                    0,                ...
            'coherenceSTD',               10,               ...
            'stencilNumber',              1,                ...
            'pixelSize',                  4,                ...
            'diameter',                   10,                ...
            'density',                    90,              ...
            'speed',                      2.1))));
        
        % Readable settings
        readable = struct( ...
            ...
            ...   % The readable object
            'reader',                     struct( ...
            ...
            'copySpecs',                  struct( ...
            ...
            ...   % The gaze windows
            'dotsReadableEye',            struct( ...
            'bindingNames',               'stimulusEnsemble', ...
            'prepare',                    {{@updateGazeWindows}}, ...
            'start',                      {{@defineEventsFromStruct, struct( ...
            'name',                       {'holdFixation', 'breakFixation', 'choseLeft', 'choseRight'}, ...
            'ensemble',                   {'stimulusEnsemble', 'stimulusEnsemble', 'stimulusEnsemble', 'stimulusEnsemble'}, ... % ensemble object to bind to
            'ensembleIndices',            {[1 1], [1 1], [2 1], [2 2]})}}), ...
            ...
            ...   % The keyboard events .. 'uiType' is used to conditinally use these depending on the theObject type
            'dotsReadableHIDKeyboard',    struct( ...
            'start',                      {{@defineEventsFromStruct, struct( ...
            'name',                       {'holdFixation', 'choseLeft', 'choseRight'}, ...
            'component',                  {'KeyboardSpacebar', 'KeyboardLeftArrow', 'KeyboardRightArrow'}, ...
            'isRelease',                  {true, false, false})}}), ...
            ...
            ...   % Gamepad
            'dotsReadableHIDGamepad',     struct( ...
            'start',                      {{@defineEventsFromStruct, struct( ...
            'name',                       {'holdFixation', 'choseLeft', 'choseRight'}, ...
            'component',                  {'Button1', 'Trigger1', 'Trigger2'}, ...
            'isRelease',                  {true, false, false})}}), ...
            ...
            ...   % Ashwin's magic buttons
            'dotsReadableHIDButtons',     struct( ...
            'start',                      {{@defineEventsFromStruct, struct( ...
            'name',                       {'holdFixation', 'choseLeft', 'choseRight'}, ...
            'component',                  {'KeyboardSpacebar', 'KeyboardLeftShift', 'KeyboardRightShift'}, ...
            'isRelease',                  {true, false, false})}}), ...
            ...
            ...   % Dummy to run in demo mode
            'dotsReadableDummy',          struct( ...
            'start',                      {{@defineEventsFromStruct, struct( ...
            'name',                       {'holdFixation'}, ...
            'component',                  {'auto_1'})}}))));
    end
    
    properties (SetAccess = protected)
        
        % The quest object
        quest;
        
        % Boolean flag, whether the specific trial has a change point or not
        isCP;
        
        % Check for changes in properties that require drawables to be
        %  recomputed
        targetDistance;
    end
    
    methods
        
        %% Constructor
        %  Use topsTreeNodeTask method, which can parse the argument list
        %  that can set properties (even those nested in structs)
        function self = topsTreeNodeTaskSingleCPDotsReversal(varargin)
            
            % ---- Make it from the superclass
            %
            self = self@topsTreeNodeTask(varargin{:});
        end
        
        %% Start task (overloaded)
        %
        % Put stuff here that you want to do before each time you run this
        % task
        function startTask(self)
            
            % ---- Set up independent variables if Quest task
            %
            if strcmp(self.name, 'Quest')
                
                % Initialize and save Quest object
                self.quest = qpInitialize(qpParams( ...
                    'stimParamsDomainList', { ...
                    self.questSettings.stimRange}, ...
                    'psiParamsDomainList',  { ...
                    self.questSettings.thresholdRange, ...
                    self.questSettings.slopeRange, ...
                    self.questSettings.guessRate, ...
                    self.questSettings.lapseRange}));
                
                % Update independent variable struct using initial value
                self.setIndependentVariableByName('coherence', 'values', ...
                    self.getQuestGuess());
                
            elseif ~isempty(self.settings.useQuest)
                
                % Update independent variable struct using Quest threshold
                self.setIndependentVariableByName('coherence', 'values', ...
                    self.settings.useQuest.getQuestThreshold( ...
                    self.settings.coherencesFromQuest));
            end
            
            % ---- Initialize the state machine
            %
            self.initializeStateMachine();
            
            % ---- Show task-specific instructions
            %
            self.helpers.feedback.show('text', self.settings.textStrings, ...
                'showDuration', self.timing.showInstructions);
            pause(self.timing.waitAfterInstructions);
        end
        
        %% Finish task (overloaded)
        %
        % Put stuff here that you want to do after each time you run this
        % task
        function finishTask(self)
        end
        
        %% Start trial
        %
        % Put stuff here that you want to do before each time you run a trial
        function startTrial(self)
            
            % ---- check whether a CP will occur in this trial or not
            %
            
            % Get current task/trial
            trial = self.getTrial();
            ensemble = self.helpers.stimulusEnsemble.theObject;
            trial.initDirection = ensemble.getObjectProperty('direction',4);
            
            % if CP time is longer than viewing duration, no CP
            if trial.timeCP >= trial.viewingDuration
                self.isCP = false;
                trial.presenceCP = 0;
                trial.endDirection = trial.initDirection;
                self.timing.dotsDuration1 = trial.viewingDuration;
                self.timing.dotsDuration2 = 0;
            else
                if rand < trial.probCP
                    self.isCP = true;
                    trial.presenceCP = 1.0; % numeric because of FIRA
                    trial.endDirection = self.flipDirection(trial.initDirection);
                    self.timing.dotsDuration1 = trial.timeCP;
                    self.timing.dotsDuration2 = trial.viewingDuration - trial.timeCP;
                else
                    self.isCP = false;
                    trial.presenceCP = 0;
                    trial.endDirection = trial.initDirection;
                    self.timing.dotsDuration1 = trial.viewingDuration;
                    self.timing.dotsDuration2 = 0;
                end
            end
            
            self.setTrial(trial);
            
            % ---- Prepare components
            %
            self.prepareDrawables();
            self.prepareStateMachine();
            
            % jig sets the timing in the statelist
            self.stateMachine.editStateByName('showDotsEpoch1', 'timeout', self.timing.dotsDuration1);
            self.stateMachine.editStateByName('switchDots', 'timeout', self.timing.dotsDuration2);
            
            % ---- Inactivate all of the readable events
            %
            self.helpers.reader.theObject.deactivateEvents();
            
            % ---- Show information about the task/trial
            %
            % Task information
            taskString = sprintf('%s (task %d/%d): %d correct, %d error, mean RT=%.2f, epoch1=%.2f, epoch2=%.2f', ...
                self.name, self.taskID, length(self.caller.children), ...
                sum([self.trialData.correct]==1), sum([self.trialData.correct]==0), ...
                nanmean([self.trialData.RT]), ...
                self.timing.dotsDuration1, self.timing.dotsDuration2);
            
            % Trial information
            trial = self.getTrial();
            trialString = sprintf('Trial %d/%d, dir=%d, coh=%.0f', self.trialCount, ...
                numel(self.trialData)*self.trialIterations, trial.initDirection, trial.coherence);
            
            % Show the information
            self.statusStrings = {taskString, trialString};
            self.updateStatus(); % just update the second one
        end
        
        %% Flip direction of dots
        %
        % very simple function that
        function direction2 = flipDirection(self, direction1)
            pd = self.settings.possibleDirections;
            direction2 = pd(~(pd == direction1));
        end
        
        %% Finish Trial
        %
        % Could add stuff here
        function finishTrial(self)
            
            % Conditionally update Quest
            if strcmp(self.name, 'Quest')
                
                % ---- Check for bad trial
                %
                trial = self.getTrial();
                if isempty(trial) || ~(trial.correct >= 0)
                    return
                end
                
                % ---- Update Quest
                %
                % (expects 1=error, 2=correct)
                self.quest = qpUpdate(self.quest, self.questSettings.recentGuess, ...
                    trial.correct+1);
                
                % Update next guess, if there is a next trial
                if self.trialCount < length(self.trialIndices)
                    self.trialData(self.trialIndices(self.trialCount+1)).coherence = ...
                        self.getQuestGuess();
                end
                
                % ---- Set reference coherence to current threshold
                %        and set reference RT
                %
                self.settings.coherences  = self.getQuestThreshold( ...
                    self.settings.coherencesFromQuest);
                self.settings.referenceRT = nanmedian([self.trialData.RT]);
            end
        end
        
        %% Check for choice
        %
        % Save choice/RT information and set up feedback for the dots task
        function nextState = checkForChoice(self, events, eventTag)
            
            % ---- Check for event
            %
            eventName = self.helpers.reader.readEvent(events, self, eventTag);
            
            % Nothing... keep checking
            if isempty(eventName)
                nextState = [];
                return
            end
            
            % ---- Good choice!
            %
            % Override completedTrial flag
            self.completedTrial = true;
            
            % Jump to next state when done
            nextState = 'blank';
            
            % Get current task/trial
            trial = self.getTrial();
            
            % Save the choice
            trial.choice = double(strcmp(eventName, 'choseRight'));
            
            % Mark as correct/error
            % jig changed direction to endDirection
            trial.correct = double( ...
                (trial.choice==0 && trial.endDirection==180) || ...
                (trial.choice==1 && trial.endDirection==0));
            
            % Compute/save RT, wrt dotsOff for non-RT
            trial.RT = trial.choiceTime - trial.dotsOff;
            
            
            % ---- Re-save the trial
            %
            self.setTrial(trial);
            
            % ---- Possibly show smiley face
            if trial.correct == 1 && self.timing.showSmileyFace > 0
                self.helpers.stimulusEnsemble.draw({3, [1 2 4]});
                pause(self.timing.showSmileyFace);
            end
        end
        
        %% Switch dots direction at change point
        %
        % this function gets called, via its handle, in an fevalable of the
        % state machine. It is the 'entry' function of a state. It does the
        % following: switch direction of dots
        function switchDots(self)
            trial=self.getTrial();
            self.helpers.stimulusEnsemble.theObject.setObjectProperty(...
                'direction', trial.endDirection, 4)
        end
        
        %% Show feedback
        %
        function showFeedback(self)
            
            % Get current task/trial
            trial = self.getTrial();
            
            % Set up feedback based on outcome
            if trial.correct == 1
                feedbackStr = 'Correct';
                feedbackArgs = { ...
                    'image', self.settings.correctImageIndex, ...
                    'sound', self.settings.correctPlayableIndex};
            elseif trial.correct == 0
                feedbackStr = 'Error';
                feedbackArgs = { ...
                    'image', self.settings.errorImageIndex, ...
                    'sound', self.settings.errorPlayableIndex};
            else
                feedbackArgs = {'text', 'No choice'};
                feedbackStr = 'No choice';
            end
            
            % --- Show trial feedback in GUI/text window
            %
            % jig changed direction to endDirection
            self.statusStrings{2} = ...
                sprintf('Trial %d/%d, dir=%d, coh=%.0f: %s, RT=%.2f', ...
                self.trialCount, numel(self.trialData)*self.trialIterations, ...
                trial.endDirection, trial.coherence, feedbackStr, trial.RT);
            self.updateStatus(2); % just update the second one
            
            % --- Show trial feedback on the screen
            %
            % self.helpers.feedback.show(feedbackArgs{:});
        end
        
        %% Get Quest threshold value(s)
        %
        % pcors is list of proportion correct values
        %  if given, find associated coherences from QUEST Weibull
        %  Parameters are: threshold, slope, guess, lapse
        
        function threshold = getQuestThreshold(self, pcors)
            
            % Find values from PMF
            psiParamsIndex = qpListMaxArg(self.quest.posterior);
            psiParamsQuest = self.quest.psiParamsDomain(psiParamsIndex,:);
            
            if ~isempty(psiParamsQuest)
                
                if nargin < 2 || isempty(pcors)
                    
                    % Just return threshold in units of % coh
                    threshold = psiParamsQuest(1,1);
                else
                    
                    % Compute PMF with fixed guess and no lapse
                    cax = (0:0.1:100);
                    predictedProportions =100*qpPFWeibull(cax', [psiParamsQuest(1,1:3) 0]);
                    threshold = nans(size(pcors));
                    for ii = 1:length(pcors)
                        Lp = predictedProportions(:,2)>=pcors(ii);
                        if any(Lp)
                            threshold(ii) = cax(find(Lp,1));
                        end
                    end
                end
            end
            
            % Convert to % coherence
            threshold = 10^(threshold./20).*100;
        end
        
        %% Get next coherences guess from Quest
        %
        function coh = getQuestGuess(self)
            
            self.questSettings.recentGuess = qpQuery(self.quest);
            coh = min(100, max(0, 10^(self.questSettings.recentGuess/20)*100));
        end
    end
    
    methods (Access = protected)
        
        %% Prepare drawables for this trial
        %
        function prepareDrawables(self)
            
            % ---- Get the current trial and the stimulus ensemble
            %
            trial    = self.getTrial();
            ensemble = self.helpers.stimulusEnsemble.theObject;
            
            % ----- Get target locations
            %
            %  Determined relative to fp location
            fpX = ensemble.getObjectProperty('xCenter', 1);
            fpY = ensemble.getObjectProperty('yCenter', 1);
            td  = self.settings.targetDistance;
            
            % ---- Possibly update all stimulusEnsemble objects if settings
            %        changed
            %
            if isempty(self.targetDistance) || ...
                    self.targetDistance ~= self.settings.targetDistance
                
                % Save current value(s)
                self.targetDistance = self.settings.targetDistance;
                
                %  Now set the target x,y
                ensemble.setObjectProperty('xCenter', [fpX - td, fpX + td], 2);
                ensemble.setObjectProperty('yCenter', [fpY fpY], 2);
            end
            
            % ---- Set a new seed base for the dots random-number process
            %
            trial.randSeedBase = randi(9999);
            self.setTrial(trial);
            
            % ---- Save dots properties
            %
            ensemble.setObjectProperty('randBase',  trial.randSeedBase, 4);
            ensemble.setObjectProperty('coherence', trial.coherence, 4);
            ensemble.setObjectProperty('direction', trial.initDirection, 4);
            
            % ---- Possibly update smiley face to location of correct target
            %
            if self.timing.showSmileyFace > 0
                
                % Set x,y
                ensemble.setObjectProperty('x', fpX + sign(cosd(trial.endDirection))*td, 3);
                ensemble.setObjectProperty('y', fpY, 3);
            end
            
            % ---- Prepare to draw dots stimulus
            %
            ensemble.callObjectMethod(@prepareToDrawInWindow);
        end
        
        
        %% Prepare stateMachine for this trial
        %
        function prepareStateMachine(self)
            % empty function
        end
        
        %% Initialize StateMachine
        %
        function initializeStateMachine(self)
            
            % ---- Fevalables for state list
            %
            dnow    = {@drawnow};
            blanks  = {@dotsTheScreen.blankScreen};
            chkuif  = {@getNextEvent, self.helpers.reader.theObject, false, {'holdFixation'}};
            chkuib  = {}; % {@getNextEvent, self.readables.theObject, false, {}}; % {'brokeFixation'}
            chkuic  = {@checkForChoice, self, {'choseLeft' 'choseRight'}, 'choiceTime'};
            showfx  = {@draw, self.helpers.stimulusEnsemble, {{'colors', ...
                [1 1 1], 1}, {'isVisible', true, 1}, {'isVisible', false, [2 3 4]}},  self, 'fixationOn'};
            showt   = {@draw, self.helpers.stimulusEnsemble, {2, []}, self, 'targetOn'};
            showfb  = {@showFeedback, self};
            showdFX = {@draw, self.helpers.stimulusEnsemble, {4, []}, self, 'dotsOn'};
            % jig added self
            switchd = {@switchDots self};
            hided   = {@draw, self.helpers.stimulusEnsemble, {[], [1 4]}, self, 'dotsOff'};
            
            % recall this function's signature from topsTreeNodeTopNode
            % setNextState(self, condition, thisState, nextStateIfTrue, nextStateIfFalse)
            % thus, the function below sets the 'next' state of the 'showDotsEpoch1'
            % state
            pdbr    = {@setNextState, self, 'isCP', 'showDotsEpoch1', 'switchDots', 'waitForChoiceFX'};
            
            % drift correction
            hfdc  = {@reset, self.helpers.reader.theObject, true};
            
            % Activate/deactivate readable events
            sea   = @setEventsActiveFlag;
            gwfxw = {sea, self.helpers.reader.theObject, 'holdFixation'};
            gwfxh = {};
            gwts  = {sea, self.helpers.reader.theObject, {'choseLeft', 'choseRight'}, 'holdFixation'};
            
            % ---- Timing variables, read directly from the timing property struct
            %
            t = self.timing;
            
            % ---- Make the state machine. These will be added into the
            %        stateMachine (in topsTreeNode)
            %
            % jig:
            %  - changed next state for preDots
            %  - removed showDotsEpoch2 state, which could be consolidated
            %        with switchDots
            states = {...
                'name'              'entry'  'input'  'timeout'                'exit'  'next'            ; ...
                'showFixation'      showfx   {}       0                         pdbr    'waitForFixation' ; ...
                'waitForFixation'   gwfxw    chkuif   t.fixationTimeout         {}      'blankNoFeedback' ; ...
                'holdFixation'      gwfxh    chkuib   t.holdFixation            hfdc    'showTargets'     ; ...
                'showTargets'       showt    chkuib   t.preDots                 gwts    'preDots'         ; ...
                'preDots'           {}       {}       0                         {}      'showDotsEpoch1'  ; ...
                'showDotsEpoch1'    showdFX  {}       t.dotsDuration1           {}      ''                ; ...
                'switchDots'        switchd  {}       t.dotsDuration2           {}      'waitForChoiceFX' ; ...
                'waitForChoiceFX'   hided    chkuic   t.choiceTimeout           {}      'blank'           ; ...
                'blank'             {}       {}       0.1                       blanks  'showFeedback'    ; ...
                'showFeedback'      showfb   {}       t.showFeedback            blanks  'done'            ; ...
                'blankNoFeedback'   {}       {}       0                         blanks  'done'            ; ...
                'done'              dnow     {}       t.interTrialInterval      {}      ''                ; ...
                };
            
            % ---- Set up ensemble activation list. This determines which
            %        states will correspond to automatic, repeated calls to
            %        the given ensemble methods
            %
            % See topsActivateEnsemblesByState for details.
            % jig updated state list to include states that require dots
            % drawing
            activeList = {{ ...
                self.helpers.stimulusEnsemble.theObject, 'draw'; ...
                self.helpers.screenEnsemble.theObject, 'flip'}, ...
                {'preDots' 'showDotsEpoch1' 'switchDots'}};
            
            % --- List of children to add to the stateMachineComposite
            %        (the state list above is added automatically)
            %
            compositeChildren = { ...
                self.helpers.stimulusEnsemble.theObject, ...
                self.helpers.screenEnsemble.theObject};
            
            % Call utility to set up the state machine
            self.addStateMachine(states, activeList, compositeChildren);
        end
    end
    
    methods (Static)
        
        %% ---- Utility for defining standard configurations
        %
        % name is string:
        %  'Quest' for adaptive threshold procedure
        %  or '<SAT><BIAS>' tag, where:
        %     <SAT> is 'N' for neutral, 'S' for speed, 'A' for accuracy
        %     <BIAS> is 'N' for neutral, 'L' for left more likely, 'R' for
        %     right more likely
        function task = getStandardConfiguration(name, varargin)
            
            % ---- Get the task object, with optional property/value pairs
            %
            task = topsTreeNodeTaskSingleCPDotsReversal(name, varargin{:});
             
            % ---- Instruction settings, by column:
            %  1. tag (first character of name)
            %  2. Text string #1
            %  3. RTFeedback flag
            %
            SATsettings = { ...
                'S' 'Be as FAST as possible.'                 task.settings.referenceRT; ...
                'A' 'Be as ACCURATE as possible.'             nan;...
                'N' 'Be as FAST and ACCURATE as possible.'    nan};
            
            dp = task.settings.directionPriors;
            BIASsettings = { ...
                'L' 'Left is more likely.'                    [max(dp) min(dp)]; ...
                'R' 'Right is more likely.'                   [min(dp) max(dp)]; ...
                'N' 'Both directions are equally likely.'     [50 50]};
            
            % For instructions
            %          if strcmp(name, 'Quest')
            %             name = 'NN';
            %          end
            
            % ---- Set strings, priors based on type
            % NOTE: 3 lines below are hard-coded for now, just to get the task
            % to run. Should be improved in the future
            task.settings.textStrings = {SATsettings{2, 2}, BIASsettings{3, 2}};
            task.settings.referenceRT = nan;
            task.setIndependentVariableByName('initDirection', 'priors', []);
        end
    end
end

