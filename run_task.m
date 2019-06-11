function topNode = run_task(location)
%% function [mainTreeNode, datatub] = run_task(location)
%
% run_task = Single Change Point Dots
%
% This function configures, initializes, runs, and cleans up a SingleCP_DotsReversal
%  experiment 
%
% 11/28/18   aer wrote it

%% ---- Clear globals
%
% umm, duh
clear globals

%% ---- Configure experiment based on location
%
%   locations are 'pilot', 'office', 'tutorial'
%
% UIs:
%  'dotsReadableEyeEyelink'
%  'dotsReadableEyePupilLabs'
%  'dotsReadableEyeEOG'
%  'dotsReadableHIDKeyboard'
%  'dotsReadableEyeMouseSimulator'
%  'dotsReadableHIDButtons'
%  'dotsReadableHIDGamepad'

switch location
    case {'office'}
        arglist = { ...
            'taskSpecs',            {'Block3' 3 'Block4' 5}, ...%{'Quest' 50 'SN' 50 'AN' 50}, ...
            'trialFolder',          'Blocks002/', ...  % folder where trial generation data resides
            'readables',            {'dotsReadableHIDKeyboard'}, ...
            'recordDotsPositions',  false, ...
            'displayIndex',         0, ... % 0=small, 1=main, 2=other screen
            'remoteDrawing',        false, ...
            'sendTTLs',             false, ...
            'showFeedback',         0, ... % timeout for feedback
            'showSmileyFace',       0, ... % timeout for smiley face on correct target
            };
        
    case {'pilot'}
        arglist = { ...
            'taskSpecs',            {'Quest' 3 'Block2' 3 ...
                                    'Block3' 3 'Block4' 3}, ...%{'Quest' 50 'SN' 50 'AN' 50}, ...
            'trialFolder',          'Blocks003/', ...  % folder where trial generation data resides
            'readables',            {'dotsReadableHIDGamepad'}, ...
            'recordDotsPositions',  false, ...
            'displayIndex',         2, ... % 0=small, 1=main, 2=other screen
            'remoteDrawing',        false, ...
            'sendTTLs',             false, ...
            'showFeedback',         0, ... % timeout for feedback
            'showSmileyFace',       0, ... % timeout for smiley face on correct target
            };
        
    case {'tutorial'}
        arglist = { ...
            'taskSpecs',            {'CP' 10}, ...%{'Quest' 50 'SN' 50 'AN' 50}, ...
            'probCPs',              .5, ... %this vector should be as long as there are task nodes.
            'readables',            {'dotsReadableHIDKeyboard'}, ...
            'displayIndex',         2, ... % 0=small, 1=main, 2=other screen
            'remoteDrawing',        false, ...
            'sendTTLs',             false, ...
            'showFeedback',         0.5, ... % timeout for feedback
            'showSmileyFace',       0.5, ... % timeout for smiley face on correct target
            };
end

%% ---- Call the configuration routine
%
topNode = configure_task(arglist{:});

%% ---- Run it!
%
topNode.run();
