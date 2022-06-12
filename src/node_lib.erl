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
	 delete/1,
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

    Node=list_to_atom(NodeName++"@"++HostName),
    Kill=rpc:call(Node,init,stop,[],5000),
    Ip=config_server:host_local_ip(HostName),
    SshPort=config_server:host_ssh_port(HostName),
    Uid=config_server:host_uid(HostName),
    Pwd=config_server:host_passwd(HostName),
    Args=PaArgs++" "++"-setcookie "++Cookie++" "++EnvArgs,

    Msg="erl -sname "++NodeName++" "++Args++" "++"-detached", 
    Timeout=5000,
    Result=case rpc:call(node(),my_ssh,ssh_send,[Ip,SshPort,Uid,Pwd,Msg,Timeout],Timeout-1000) of
	       {badrpc,Reason}->
		   {error,[{badrpc,Reason}]};
	       ok->
		   case net_adm:ping(Node) of
		       pang->
			   Kill=rpc:call(Node,init,stop,[],5000),
			   {error,[{couldnt_connect,Node}]};
		       pong->
			   {ok,Node}
		   end
	   end,
    Result.



%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
load_start_appl(Node,NodeDir,ApplId,ApplVsn,GitPath,{StartModule,StartFunction,StartArgs})->
    ApplDir=filename:join(NodeDir,ApplId++"_"++ApplVsn),
    os:cmd("rm -rf "++ApplDir),
    ok=file:make_dir(ApplDir),
    Result=case rpc:call(node(),git_lib,create,[ApplDir,GitPath],20*5000) of
		       {error,Reason}->
			   rpc:cast(node(),nodelog_server,log,[warning,?MODULE_STRING,?LINE,
					      {"Error when loading service ",ApplId,' ', {error,Reason}}],5000),
			   {error,Reason};
		       {ok,ApplDir}->
			   ApplEbin=filename:join(ApplDir,"ebin"),
			   case rpc:call(Node,code,add_patha,[ApplEbin],5000) of
			       {error,Reason}->
				   {error,Reason};
			       true->
				   rpc:cast(node(),nodelog_server,log,[notice,?MODULE_STRING,?LINE,
						      {"Application  succesfully loaded ",ApplId,' ',ApplVsn,' ',Node}]),
				   case rpc:call(Node,StartModule,StartFunction,StartArgs,20*5000) of
				       ok->
					   rpc:cast(node(),nodelog_server,log,[notice,?MODULE_STRING,?LINE,
							      {"Application  succesfully started ",ApplId,' ',ApplVsn,' ',Node}]),
					   {ok,ApplId,ApplVsn,ApplDir};
				       Error ->
					   rpc:cast(node(),nodelog_server,log,[notice,?MODULE_STRING,?LINE,
							      {"Error whenstarting application ",ApplId,' ',Error}]),
					   Error
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


