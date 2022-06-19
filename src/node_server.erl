%%% -------------------------------------------------------------------
%%% Author  : joqerlang
%%% Description :
%%% load,start,stop unload applications in the pods vm
%%% supports with services
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(node_server).   

-behaviour(gen_server).  

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
-define(SERVER,?MODULE).

%% External exports
-export([
	
	 create/6,
	 create/5,
	 ssh_create/2,
	 ssh_create/5,
	 delete/1,
	 load_start_appl/6,
	 stop_unload_appl/3,

	 appl_start/1,
	 read_state/0,
	 ping/0
	]).


-export([
	 start/0,
	 stop/0
	]).


-export([init/1, handle_call/3,handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {
		nodes
	       
	       }).

%% ====================================================================
%% External functions
%% ====================================================================
appl_start([])->
    application:start(node).

%% ====================================================================
%% Server functions
%% ====================================================================
%% Gen server functions

start()-> gen_server:start_link({local, ?SERVER}, ?SERVER, [], []).
stop()-> gen_server:call(?SERVER, {stop},infinity).

%% ====================================================================
%% Application handling
%% ====================================================================


create(HostName,NodeName,Cookie,PaArgs,EnvArgs)->
    gen_server:call(?SERVER, {create,HostName,NodeName,Cookie,PaArgs,EnvArgs},infinity).

create(HostName,NodeDir,NodeName,Cookie,PaArgs,EnvArgs)->
    gen_server:call(?SERVER, {create,HostName,NodeDir,NodeName,Cookie,PaArgs,EnvArgs},infinity).



ssh_create(NodeArgs,SshArgs)->
    gen_server:call(?SERVER, {ssh_create,NodeArgs,SshArgs},infinity).
ssh_create(HostName,NodeName,Cookie,PaArgs,EnvArgs)->
    gen_server:call(?SERVER, {ssh_create,HostName,NodeName,Cookie,PaArgs,EnvArgs},infinity).

delete(Node)->
    gen_server:call(?SERVER, {delete,Node},infinity).
    
load_start_appl(Node,NodeDir,ApplId,ApplVsn,GitPath,StartCmd)->
    gen_server:call(?SERVER, {load_start_appl,Node,NodeDir,ApplId,ApplVsn,GitPath,StartCmd},infinity).
    
stop_unload_appl(Node,ApplDir,ApplId)->
    gen_server:call(?SERVER, {stop_unload_appl,Node,ApplDir,ApplId},infinity).


%%---------------------------------------------------------------
%% Function:template()
%% @doc: service spec template  list of {app,vsn} to run      
%% @param: 
%% @returns:[{app,vsn}]
%%
%%---------------------------------------------------------------
%-spec template()-> [{atom(),string()}].
%template()->
 %   gen_server:call(?SERVER, {template},infinity).


%% ====================================================================
%% Support functions
%
%%---------------------------------------------------------------
%% Function:read_state()
%% @doc: read theServer State variable      
%% @param: non 
%% @returns:State
%%
%%---------------------------------------------------------------
-spec read_state()-> term().
read_state()->
    gen_server:call(?SERVER, {read_state},infinity).
%% 
%% @doc:check if service is running
%% @param: non
%% @returns:{pong,node,module}|{badrpc,Reason}
%%
-spec ping()-> {atom(),node(),module()}|{atom(),term()}.
ping()-> 
    gen_server:call(?SERVER, {ping},infinity).

%% ====================================================================
%% Gen Server functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([]) ->
    rpc:cast(node(),nodelog_server,log,[notice,?MODULE_STRING,?LINE,
					{"OK, started server at node  ",?MODULE," ",node()}]),
    {ok, #state{
	   }
    }.

%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_call({create,HostName,NodeName,Cookie,PaArgs,EnvArgs},_From, State) ->
    Reply=case rpc:call(node(),node_lib,create,[HostName,NodeName,Cookie,PaArgs,EnvArgs],2*5000) of
	      {ok,Node}->
		  rpc:cast(node(),nodelog_server,log,[notice,?MODULE_STRING,?LINE,
						      {"OK, start Node at host  ",Node,HostName}]),
		  {ok,Node};
	      {error,Reason}->
		  rpc:cast(node(),nodelog_server,log,[warning,?MODULE_STRING,?LINE,
						      {"Error when creating Node with name  at host  ",NodeName,HostName, Reason}]),
		  {error,Reason}
	  end,
    {reply, Reply, State};


handle_call({ssh_create,NodeArgs,SshArgs},_From, State) ->
    Reply=case rpc:call(node(),node_lib,ssh_create,[NodeArgs,SshArgs],5*5000) of
	      {ok,Node}->
		  rpc:cast(node(),nodelog_server,log,[notice,?MODULE_STRING,?LINE,
						      {"OK, start Node at host  ",Node,NodeArgs}]),
		  {ok,Node};
	      {error,Reason}->
		  rpc:cast(node(),nodelog_server,log,[warning,?MODULE_STRING,?LINE,
						      {"Error when creating Node with name  at host  ",NodeArgs, Reason}]),
		  {error,Reason}
	  end,
    {reply, Reply, State};

handle_call({ssh_create,HostName,NodeName,Cookie,PaArgs,EnvArgs},_From, State) ->
    Reply=case rpc:call(node(),node_lib,ssh_create,[HostName,NodeName,Cookie,PaArgs,EnvArgs],5*5000) of
	      {ok,Node}->
		  rpc:cast(node(),nodelog_server,log,[notice,?MODULE_STRING,?LINE,
						      {"OK, start Node at host  ",Node,HostName}]),
		  {ok,Node};
	      {error,Reason}->
		  rpc:cast(node(),nodelog_server,log,[warning,?MODULE_STRING,?LINE,
						      {"Error when creating NodeName at host  ",NodeName,HostName, Reason}]),
		  {error,Reason}
	  end,
    {reply, Reply, State};




handle_call({delete,Node},_From, State) ->
    Reply=rpc:call(node(),node_lib,delete,[Node],2*5000),
    {reply, Reply, State};


handle_call({load_start_appl,Node,NodeDir,ApplId,ApplVsn,GitPath,{StartModule,StartFunction,StartArgs}},_From, State) ->
     Reply=rpc:call(node(),node_lib,load_start_appl,[Node,NodeDir,ApplId,ApplVsn,GitPath,{StartModule,StartFunction,StartArgs}],5*5000),
    {reply, Reply, State};

handle_call({stop_unload_appl,Node,ApplDir,ApplId},_From, State) ->
     Reply=rpc:call(node(),node_lib,stop_unload_appl,[Node,ApplDir,ApplId],5*5000),
    {reply, Reply, State};

handle_call({read_state},_From, State) ->
    Reply=State,
    {reply, Reply, State};

handle_call({ping},_From, State) ->
    Reply=pong,
    {reply, Reply, State};

handle_call({stopped},_From, State) ->
    Reply=ok,
    {reply, Reply, State};


handle_call({not_implemented},_From, State) ->
    Reply=not_implemented,
    {reply, Reply, State};

handle_call({stop}, _From, State) ->
    {stop, normal, shutdown_ok, State};

handle_call(Request, From, State) ->
    %rpc:cast(node(),log,log,[?Log_ticket("unmatched call",[Request, From])]),
    Reply = {ticket,"unmatched call",Request, From},
    {reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------


handle_cast(_Msg, State) ->
  %  rpc:cast(node(),log,log,[?Log_ticket("unmatched cast",[Msg])]),
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info({nodedown,Node}, State) ->
    io:format(" ~p~n",[{?MODULE,?LINE,nodedown,Node}]),
    {noreply, State};

handle_info(Info, State) ->
    io:format("Info ~p~n",[{?MODULE,?LINE,Info}]),
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

		  
