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
    Controllers=case rpc:multicall(HostNodes, erlang,nodes,[],5*1000) of
		    {ResL,BadNodes}->
			ResL1=[Node||Node<-lists:append(ResL),
				     true/=lists:member(Node,HostNodes)],
			ResL2=rm_duplicates(ResL1),
			case rpc:multicall(ResL2,sd,get,[controller],5*1000) of
			    {ResL3,BadNodes}->
				%rpc:call(node(),io,format,["AllNodes ~p~n",[ResL2]],5*1000),
				rm_duplicates(lists:append(ResL3))
			end
		end,
    Controllers.

%% --------------------------------------------------------------------
%% Function:tes cases
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
rm_duplicates(List)->
   lists:reverse(rm_duplicates(List,[])).
rm_duplicates([],SingleList)->
    SingleList;
rm_duplicates([{_,_}|T],Acc)->
    rm_duplicates(T,Acc);
rm_duplicates([Term|T],Acc)->
    NewAcc=case lists:member(Term,T) of
	       false->
		   [Term|Acc];
	       true->
		   Acc
	   end,
    rm_duplicates(T,NewAcc).
