%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(node_lib).  
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%%---------------------------------------------------------------------
%% Records for test
%%

%% --------------------------------------------------------------------
%-compile(export_all).
-export([
	 create/6,
	 create/5,
	 delete/1,
	 ssh_create/2,
	 ssh_create/5,
	 load_start_appl/6,
	 stop_unload_appl/3
	]).
	 

%% ====================================================================
%% External functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
create(HostName,NodeName,Cookie,PaArgs,EnvArgs)->
    Args=PaArgs++" "++"-setcookie "++Cookie++" "++EnvArgs,
    Result=case slave:start(HostName,NodeName,Args) of
	       {error,Reason}->
		   {error,[Reason]};
	       {ok,SlaveNode}->
		   case net_kernel:connect_node(SlaveNode) of
		       false->
			   {error,[failed_connect,SlaveNode]};
		       ignored->
			   {error,[ignored,SlaveNode]};
		       true->
			   {ok,SlaveNode}
			   
		   end
	   end,
    Result.
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
create(HostName,NodeDir,NodeName,Cookie,PaArgs,EnvArgs)->
  %  io:format("HostName ~p~n",[HostName]),
  %  io:format("NodeDir ~p~n",[NodeDir]),
  %  io:format("NodeName ~p~n",[NodeName]),
  %  io:format("PaArgs ~p~n",[{PaArgs,?MODULE,?LINE}]),
  %  io:format("Cookie ~p~n",[Cookie]),
  %  io:format("EnvArgs ~p~n",[EnvArgs]),

    Args=PaArgs++" "++"-setcookie "++Cookie++" "++EnvArgs,
    Result=case slave:start(HostName,NodeName,Args) of
	       {error,Reason}->
		   {error,[Reason]};
	       {ok,SlaveNode}->
		   case net_kernel:connect_node(SlaveNode) of
		       false->
			   {error,[failed_connect,SlaveNode]};
		       ignored->
			   {error,[ignored,SlaveNode]};
		       true->
			   case rpc:call(SlaveNode,code,add_patha,[NodeDir],1000) of
			       {badrpc,Error}->
				   {error,[badrpc,Error,SlaveNode]};
			       {error,bad_directory}->
				   {error,[bad_directory,NodeDir]};
			       true-> {ok,SlaveNode}
			   end
		   end
	   end,
    Result.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------	       
delete(Node)->
    slave:stop(Node).


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
ssh_create(HostName,NodeName,Cookie,PaArgs,EnvArgs)->
    {ok,Ip}=db_host_spec:read(local_ip,HostName),
    {ok,SshPort}=db_host_spec:read(ssh_port,HostName),
    {ok,Uid}=db_host_spec:read(uid,HostName),
    {ok,Pwd}=db_host_spec:read(passwd,HostName),
    ssh_create({HostName,NodeName,Cookie,PaArgs,EnvArgs},
	       {Ip,SshPort,Uid,Pwd}).
    
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
ssh_create({HostName,NodeName,Cookie,PaArgs,EnvArgs},
	   {Ip,SshPort,Uid,Pwd})->

    Node=list_to_atom(NodeName++"@"++HostName),
    rpc:call(Node,init,stop,[],5000),
    true=check_stopped_node(100,Node,false),
    Args=PaArgs++" "++"-setcookie "++Cookie++" "++EnvArgs,

    Msg="erl -sname "++NodeName++" "++Args++" "++"-detached", 
    Timeout=10000,
    Result=case rpc:call(node(),my_ssh,ssh_send,[Ip,SshPort,Uid,Pwd,Msg,Timeout],Timeout-1000) of
	       % {badrpc,timeout}-> retry X times       
	       {badrpc,Reason}->
		   {error,[{?MODULE,?LINE," ",badrpc,Reason}]};
	       ok->
		   case check_started_node(100,Node,false) of
		       false->
			   rpc:call(Node,init,stop,[],5000),
			   {error,[{?MODULE,?LINE," ",couldnt_connect,Node}]};
		       true->
			   {ok,Node}
		   end
	   end,
    Result.

check_stopped_node(_N,_Node,true)->
    true;
check_stopped_node(0,_Node,Boolean) ->
    Boolean;
check_stopped_node(N,Node,_) ->
    Boolean=case net_adm:ping(Node) of
		pong->
		    timer:sleep(100),
		    false;
		pang->
		    true
	    end,
    check_stopped_node(N-1,Node,Boolean).

check_started_node(_N,_Node,true)->
    true;
check_started_node(0,_Node,Boolean) ->
    Boolean;
check_started_node(N,Node,_) ->

    Boolean=case net_adm:ping(Node) of
		  pang->
		    timer:sleep(100),
		      false;
		pong->
		    true
	    end,
    check_started_node(N-1,Node,Boolean).
    

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
load_start_appl(Node,NodeDir,ApplId,ApplVsn,GitPath,{StartModule,StartFunction,StartArgs})->
   % {ok,Root}=rpc:call(Node,file,get_cwd,[],5000),
  %  ApplDir=filename:join([Root,NodeDir,ApplId++"_"++ApplVsn]),
    ApplDir=filename:join([NodeDir,ApplId++"_"++ApplVsn]),
  %  os:cmd("rm -rf "++ApplDir),
 %   ok=file:make_dir(ApplDir),
    rpc:call(Node,os,cmd,["rm -rf "++ApplDir],5000),
    ok=rpc:call(Node,file,make_dir,[ApplDir],5000),
    Result=case rpc:call(node(),git_lib,create,[Node,ApplDir,GitPath],20*5000) of
	       {error,Reason}->
		   {error,Reason};
	       {ok,ApplDir}->
		   ApplEbin=filename:join(ApplDir,"ebin"),
			   case rpc:call(Node,code,add_patha,[ApplEbin],5000) of
			       {error,Reason}->
				   {error,[?MODULE,?LINE," ",Reason]};
			       true->
				   case rpc:call(Node,StartModule,StartFunction,StartArgs,20*5000) of
				       ok->
					   {ok,ApplId,ApplVsn,ApplDir};
				       Error ->
					    {error,[?MODULE,?LINE," ",Error]}
				   end
			   end
	   end,
    Result.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
stop_unload_appl(Node,ApplDir,ApplId)->
    Appl=list_to_atom(ApplId),
    ok=rpc:call(Node,application,stop,[Appl],5000),
    ok=rpc:call(Node,application,unload,[Appl],5000),    
    true=filelib:is_dir(ApplDir),
    os:cmd("rm -rf "++ApplDir),
    ok.


