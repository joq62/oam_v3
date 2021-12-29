%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(cluster).  
    
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------

%% External exports
-export([
	 new/0
	]).


%% ====================================================================
%% External functions
%% ====================================================================
new()->
    Result=case pod:restart_hosts_nodes() of
	       {error,StartRes}->
		   {error,StartRes};
	       {ok,HostIdNodesList}-> %[{HostId,HostNode}]
		   %% load infra in Host
		   case start_infra(HostIdNodesList) of
		       {error,Reason}->
			   
			   {error,Reason};
		       {ok,StartList}->
			   {ok,lists:append([AppInfo||{ok,AppInfo}<-StartList])}
		   end
	   end,
    Result.

start_infra(HostIdNodesList)->
    start_infra(HostIdNodesList,[]).
start_infra([],StartRes)->
    {ok,StartRes};
start_infra([{HostId,HostNode}|T],Acc)->
    ControllerDepIdList=[Id||{Id,_Name,_Vsn,PodSpecs,Affinity,_Status}<-db_deployment:read_all(),
	       [{"controller","1.0.0"}]=:=PodSpecs,
	       [HostId]=:=Affinity],
    LoadStartRes=case ControllerDepIdList of
		     []->
			 WorkerDepIdList=[Id||{Id,_Name,_Vsn,PodSpecs,Affinity,_Status}<-db_deployment:read_all(),
					      [{"worker","1.0.0"}]=:=PodSpecs,
					      [HostId]=:=Affinity],
			 case WorkerDepIdList of
			     []->
				 {error,[no_deployment,HostId,HostNode]};
			     [DepId|_]->
				 pod:start_deployment(DepId,HostId)
			 end;
		     [DepId|_]->
			 pod:start_deployment(DepId,HostId)
		 end,
    NewAcc=[LoadStartRes|Acc],
    start_infra(T,NewAcc).	



