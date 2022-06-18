%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(git_lib).  
    
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
%-include("log.hrl").
%%---------------------------------------------------------------------
%% Records for test
%%

%% --------------------------------------------------------------------
%-compile(export_all).
-export([
	 create/2,
	 create/3
	]).
	 

%% ====================================================================
%% External functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
create(Node,BaseApplDir,GitPath)->
    {ok,Root}=rpc:call(Node,file,get_cwd,[],1000),  
    ApplDir=filename:join(Root,BaseApplDir),
    TempDir=filename:join(Root,"temp.dir"),
    rpc:call(Node,os,cmd,["rm -rf "++TempDir],1000),
    timer:sleep(1000),
    ok=rpc:call(Node,file,make_dir,[TempDir],1000),
    _Clonres=rpc:call(Node,os,cmd,["git clone "++GitPath++" "++TempDir],5000),
    timer:sleep(1000),
 %   io:format("Clonres ~p~n",[Clonres]),

 %   rpc:cast(node(),nodelog_server,log,[info,?MODULE_STRING,?LINE,
%					{clone_result,Clonres}]),
    %MvRes=rpc:call(Node,os,cmd,["mv  "++TempDir++"/*"++" "++ApplDir],5000),
  %  io:format("MvRes ~p~n",[MvRes]),
 %   rpc:cast(node(),nodelog_server,log,[info,?MODULE_STRING,?LINE,
%				     {mv_result,MvRes}]),
    _RmRes=rpc:call(Node,os,cmd,["rm -r  "++TempDir],5000),
    timer:sleep(1000),
   % io:format("RmRes ~p~n",[RmRes]),
    %rpc:cast(node(),nodelog_server,log,[info,?MODULE_STRING,?LINE,
%				     {rm_result,RmRes}]),
    Ebin=filename:join(ApplDir,"ebin"),
    Reply=case rpc:call(Node,filelib,is_dir,[Ebin],5000) of
	      true->
		  case rpc:call(Node,code,add_patha,[Ebin],5000) of
		      true->
			  
			  {ok,ApplDir};
		      {badrpc,Reason} ->
			  
			  {error,[badrpc,Reason]};
		      Err ->
			
			  {error,[Err]}
		  end;
	      false ->
		  {error,[no_dir_created,?MODULE,?LINE]};
	      {badrpc,Reason} ->

		  {error,[badrpc,Reason]}
	  end,
    io:format("Reply ~p~n",[Reply]),
    Reply.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
create(ApplDir,GitPath)->
    TempDir="temp.dir",
    os:cmd("rm -rf "++TempDir),
    ok=file:make_dir(TempDir),
    os:cmd("git clone "++GitPath++" "++TempDir),
    os:cmd("mv  "++TempDir++"/*"++" "++ApplDir),
    os:cmd("rm -rf "++TempDir),
    Ebin=filename:join(ApplDir,"ebin"),
    Reply=case filelib:is_dir(Ebin) of
	      true->
		  case code:add_patha(Ebin) of
		      true->
			  {ok,ApplDir};
		      Err ->
			  {error,[Err]}
		  end;
	      false ->
		  {error,[no_dir_created,?MODULE,?LINE]}
	  end,
    Reply.


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
