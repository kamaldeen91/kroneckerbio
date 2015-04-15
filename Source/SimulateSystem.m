function sim = SimulateSystem(m, con, obs, opts)
%Simulate Integrate a model under specified experimental conditions and
% according to specified observation schemes
%
%   Mathematically: x = Integral(f, t=0:tF)
%   
%   sim = Simulate(m, con, obs, opts)
%   
%   Inputs
%   m: [ model struct scalar ]
%       The KroneckerBio model that will be simulated
%   con: [ experiment struct vector ]
%       The experimental conditions under which the model will be simulated
%   obs: [ observation struct matrix | nonnegative scalar ]
%       The observation schemes that will be applied to the simulation.
%       Canonically, it is a matrix that has numel(con) rows. If a single
%       number is supplied, a basic simulation until that time will be
%       returned.
%   opts: [ options struct scalar ]
%       Default = []
%       .RelTol [ nonnegative scalar {1e-6} ]
%           Relative tolerance of the integration
%       .AbsTol [ cell vector of nonnegative vectors | nonnegative vector |
%                 nonegative scalar {1e-9} ]
%           Absolute tolerance of the integration. If a cell vector is
%           provided, a different AbsTol will be used for each experiment.
%       .Verbose [ nonnegative integer scalar {1} ]
%           Bigger number displays more progress information
%
%   Outputs
%   sim = Simulate(m, con, obs, opts)
%   	A matrix of simulation structures the same size as obs. The field
%   	names are always the same (otherwise, Matlab won't make a matrix)
%   	but the exact type and meaning is determined by the observation
%   	scheme. The fields below are for when obs is supplied as a number.
%       .t [ sorted nonnegative row vector ]
%           Time points chosen by the ode solver
%       .x [ handle @(t,ind) returns matrix numel(ind) by numel(t) ]
%           This function handle evaluates some states ind of the system at
%           some particular time points t. The user may exclude ind, in
%           which case all states are returned.
%       .u [ handle @(t,ind) returns matrix numel(ind) by numel(t) ]
%           This function handle evaluates some inputs ind of the system at
%           some particular time points t. The user may exclude ind, in
%           which case all inputs are returned.
%       .y [ handle @(t,ind) returns matrix numel(ind) by numel(t) ]
%           This function handle evaluates some outputs ind of the system
%           at some particular time points t. The user may exclude ind, in
%           which case all outputs are returned.
%       .int [ integration struct scalar ]
%           The integrator solution to the system

% (c) 2015 David R Hagen
% This work is released under the MIT license.

%% Work-up
% Clean up inputs
if nargin < 4
    opts = [];
end

assert(nargin >= 2, 'KroneckerBio:Simulate:TooFewInputs', 'Simulate requires at least 2 input arguments')
assert(isscalar(m), 'KroneckerBio:Simulate:MoreThanOneModel', 'The model structure must be scalar')

% Default options
defaultOpts.Verbose = 1;

defaultOpts.RelTol  = [];
defaultOpts.AbsTol  = [];

opts = mergestruct(defaultOpts, opts);

verbose = logical(opts.Verbose);
opts.Verbose = max(opts.Verbose-1,0);

% Constants
nx = m.nx;
n_con = numel(con);
n_obs = size(obs,1);

% Refresh conditions
con = refreshCon(m, con);

% RelTol
opts.RelTol = fixRelTol(opts.RelTol);

% Fix AbsTol to be a cell array of vectors appropriate to the problem
opts.AbsTol = fixAbsTol(opts.AbsTol, 1, false(n_con,1), nx, n_con);

% Fix observations
obs = fixObservation(con, obs);

%% Run integration for the experiment
sim = emptystruct([n_obs,n_obs], 'Type', 'Name', 't', 'x', 'u', 'y', 'ie', 'te', 'xe', 'ue', 'ye', 'int');

for i_con = 1:n_con
    opts_i = opts;
    opts_i.AbsTol = opts.AbsTol{i_con};
    
    if verbose; fprintf(['Integrating system for ' con(i_con).Name '...']); end
    ints = integrateAllSys(m, con(i_con), obs(:,i_con), opts_i);
    if verbose; fprintf('done.\n'); end
    
    for i_obs = 1:n_obs
        sim(i_obs,i_con) = pastestruct(sim(i_obs), obs(i_obs).Simulation(ints(i_obs)));
    end
end
