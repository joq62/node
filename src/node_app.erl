%%%-------------------------------------------------------------------
%% @doc node public API
%% @end
%%%-------------------------------------------------------------------

-module(node_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    node_sup:start_link().

stop(_State) ->
    ok.

%% internal functions
