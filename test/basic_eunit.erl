%%% -------------------------------------------------------------------
%%% @author  : Joq Erlang
%%% @doc: : 
%%% Created :
%%% Node end point  
%%% Creates and deletes Pods
%%% 
%%% API-kube: Interface 
%%% Pod consits beams from all services, app and app and sup erl.
%%% The setup of envs is§
%%% -------------------------------------------------------------------
-module(basic_eunit).   
 
-export([start/0]).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").
-include_lib("kernel/include/logger.hrl").
%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
start()->
    
    ok=start_nodelog(),
    ok=start_appl(),
 %   ok=local_test(),
    ok=remote_test(),
  
    init:stop(),
    ok.




%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
start_nodelog()->
    ok=application:start(nodelog),
    nodelog_server:create(filename:join("test_ebin","logfile")).
    
    

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
local_test()->

    {ok,HostName}=net:gethostname(),
    NodeDir1="test_dir_1",
    NodeName1="slave1",
    Node1=list_to_atom(NodeName1++"@"++HostName),
    

    {ok,Node1}=create(NodeName1,NodeDir1),
    ok=delete(Node1,NodeDir1),
    timer:sleep(2000),
    {ok,Node1}=create(NodeName1,NodeDir1),

    {ok,Node1,ApplId,ApplDir}=load_start_sd(Node1,NodeDir1),

    ok=stop_unload_sd(Node1,ApplId,ApplDir),
    {badrpc,{'EXIT',{noproc,{gen_server,call,[sd_server,{ping},infinity]}}}}=rpc:call(Node1,sd_server,ping,[],1000),
    ok.    
  

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
remote_test()->

    {ok,HostName}=net:gethostname(),
    NodeDir1="/home/joq62/test_dir_2",
    NodeName1="slave2",
    Node1=list_to_atom(NodeName1++"@"++HostName),

    rpc:call(Node1,init,stop,[],1000),
    timer:sleep(500),
    {ok,Node1}=ssh_create(NodeName1,NodeDir1),

    {ok,Node1,ApplId,ApplDir}=load_start_sd(Node1,NodeDir1),

    ok=stop_unload_sd(Node1,ApplId,ApplDir),
    {badrpc,{'EXIT',{noproc,{gen_server,call,[sd_server,{ping},infinity]}}}}=rpc:call(Node1,sd_server,ping,[],1000),
    ok.    



%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
stop_unload_sd(Node,ApplId,ApplDir)->
    node_server:stop_unload_appl(Node,ApplDir,ApplId).

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
load_start_sd(Node,NodeDir)->
    ApplId="sd",
    ApplVsn="0.1.0",
    GitPath="https://github.com/joq62/sd.git",
    StartCmd={sd_server,appl_start,[[]]},
    {ok,ApplId,ApplVsn,ApplDir}=node_server:load_start_appl(Node,NodeDir,ApplId,ApplVsn,GitPath,StartCmd),
    
    {ok,"sd","0.1.0",_}= {ok,ApplId,ApplVsn,ApplDir},
    pong=rpc:call(Node,sd_server,ping,[],5000),

    io:format("sd:all ~p~n",[rpc:call(Node,sd_server,all,[],1000)]),
    {ok,Node,ApplId,ApplDir}.



%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
ssh_create(NodeName,NodeDir)->
    {ok,HostName}=net:gethostname(),

    os:cmd("rm -rf "++NodeDir),
    ok=file:make_dir(NodeDir),
    Cookie=atom_to_list(erlang:get_cookie()),
    PaArgs=" ",
    EnvArgs=" ",
    Ip="192.168.1.100",
    SshPort=22,
    Uid="joq62",
    Passwd="festum01",
    {ok,Node}=node_server:ssh_create({HostName,NodeName,Cookie,PaArgs,EnvArgs},
				     {Ip,SshPort,Uid,Passwd}),
    {ok,Node}.
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
create(NodeName,NodeDir)->
    {ok,HostName}=net:gethostname(),

    os:cmd("rm -rf "++NodeDir),
    ok=file:make_dir(NodeDir),
    Cookie=atom_to_list(erlang:get_cookie()),
    PaArgs=" ",
    EnvArgs=" ",
    {ok,Node}=node_server:create(HostName,NodeDir,NodeName,Cookie,PaArgs,EnvArgs),
    {ok,Node}.


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
delete(Node,NodeDir)->
    ok=node_server:delete(Node),
    os:cmd("rm -rf "++NodeDir),
    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
start_appl()->
    ok=node_server:appl_start([]),
    pong=node_server:ping(),
    ok.
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------

setup()->
  
    % Simulate host
    R=rpc:call(node(),test_nodes,start_nodes,[],2000),
%    [Vm1|_]=test_nodes:get_nodes(),

%    Ebin="ebin",
 %   true=rpc:call(Vm1,code,add_path,[Ebin],5000),
 
    R.
