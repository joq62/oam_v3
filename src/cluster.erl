%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description :  1
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(cluster).    
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

-include("controller.hrl").
-include("logger_infra.hrl").
%% --------------------------------------------------------------------

%% External exports
-export([
	 get_controllers/0,
	 get_controllers/1
	]). 


%% ====================================================================
%% External functions
%% ====================================================================


%% --------------------------------------------------------------------
%% Function:tes cases
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
get_controllers()->
    HostNodes=[db_host:node(Id)||Id<-db_host:ids(),
				pong=:=net_adm:ping(db_host:node(Id))],
    get_controllers(HostNodes).

get_controllers(HostNodes)->
   % io:format("HostNodes ~p~n",[{HostNodes,?MODULE,?FUNCTION_NAME,?LINE}]),
    {ResL,BadNodes}=rpc:multicall(HostNodes, erlang,nodes,[],5*1000),
    AllNodes=[Node||Node<-lists:append(ResL),
		 true/=lists:member(Node,HostNodes)],
   % io:format("AllNodes ~p~n",[{AllNodes,?MODULE,?FUNCTION_NAME,?LINE}]),
    NoDuplicatesAllNodes=misc:rm_duplicates(AllNodes),
   % io:format("NoDuplicatesAllNodes ~p~n",[{NoDuplicatesAllNodes,?MODULE,?FUNCTION_NAME,?LINE}]),
    {SdResL,BadNodes}=rpc:multicall(NoDuplicatesAllNodes,sd,get,[controller],5*1000),
  %  io:format("SdResL ~p~n",[{SdResL,?MODULE,?FUNCTION_NAME,?LINE}]),
    ErrorList=[{Error,Reason}||{Error,Reason}<-lists:append(SdResL)],
    Controllers=[Controller||Controller<-lists:append(SdResL),
			     false=:=lists:member(Controller,ErrorList)],
    Result=case Controllers of
	       []->
		   case ErrorList of
		       []->
			   {error,[no_controller_nodes,?MODULE,?FUNCTION_NAME,?LINE]}; 
		       ErrorList->
			   {error,[ErrorList,BadNodes,?MODULE,?FUNCTION_NAME,?LINE]}
		   end;
	       Controllers->
		   misc:rm_duplicates(Controllers)
	   end,
    Result.

