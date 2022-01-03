%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description :  1
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(loader).    
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

-include("controller.hrl").
-include("logger_infra.hrl").
%% --------------------------------------------------------------------

%% External exports
-export([
	 first/0,
	 first/2
	]). 


%% ====================================================================
%% External functions
%% ====================================================================
first()->
    
   
 %   Result=case pod:restart_hosts_nodes() of
    Result=case restart_hosts_nodes() of
	       {error,StartRes}->
		   {error,StartRes};
	       {ok,HostIdNodesList}-> %[{HostId,HostNode}]
		   AvailableControllerHostIdDepIds=[{HostId,DepId}||{DepId,_Name,_Vsn,PodSpecs,[HostId|_],_Status}<-db_deployment:read_all(),
								    [{"controller","1.0.0"}]=:=PodSpecs,
								    lists:keymember(HostId,1,HostIdNodesList)],
		   [{FirstHostId,DepId}|_]=AvailableControllerHostIdDepIds,
		   {ok,FirstHostId,{PodNode,PodDir,PodId}}=first(FirstHostId,DepId),
		    %% {PodNode,_PodDir,_PodId}=PodInfo,	
		   case rpc:call(PodNode,db_deploy_state,create,[DepId,[]],5*1000) of
		       {badrpc,Reason}->
			   {error,[badrpc,Reason]};
		       {ok,DepInstanceId}->
			   case rpc:call(PodNode,db_deploy_state,add_pod_status,[DepInstanceId,{PodNode,PodDir,PodId}],5*1000) of
			       {badrpc,Reason}->
				   {error,[badrpc,Reason]};
			       {atomic,ok}->
				   {ok,PodNode};
			       ErrorReason->
				   {error,ErrorReason}
			   end;
		       ErrorReason->
			   {error,ErrorReason}
		   end;
	       ErrorReason->
		   {error,ErrorReason}
	   end,
		    
    Result.
    
restart_hosts_nodes()->
    [rpc:call(db_host:node(HostId),init,stop,[],5*1000)||HostId<-db_host:ids()],
    start_hosts(db_host:ids(),[]).
    
start_hosts([],StartRes)->
    case [{HostId,HostNode}||{ok,[HostId,HostNode]}<-StartRes] of
	[]->
	    {error,StartRes};
	HostIdNodesList->
	    {ok,HostIdNodesList}
    end;   
start_hosts([HostId|T],Acc)->
    start_hosts(T,[pod:ssh_start(HostId)|Acc]).
    

%% --------------------------------------------------------------------
%% Function:tes cases
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------


first(FirstHostId,DepId)->
    %FirstHostNode=db_host:node(FirstHostId),
    [PodId]=db_deployment:pod_specs(DepId),
    io:format("PodId ~p~n",[{PodId,?MODULE,?FUNCTION_NAME,?LINE}]),
    		   %% 
    {ok,PodNode,PodDir}=pod:start_pod(PodId,FirstHostId),
    io:format("{ok,PodNode,PodDir} ~p~n",[{PodNode,PodDir,?MODULE,?FUNCTION_NAME,?LINE}]),
    AppIds=db_pods:application(PodId),
    io:format("AppIds ~p~n",[{AppIds,?MODULE,?FUNCTION_NAME,?LINE}]),
   
    {ok,AppInfo}=pod:load_start_apps(AppIds,PodId,PodNode,PodDir), 
    io:format("AppInfo ~p~n",[{AppInfo,?MODULE,?FUNCTION_NAME,?LINE}]),

    {ok,FirstHostId,{PodNode,PodDir,PodId}}.
		    

% io:format("AppIds ~p~n",[{AppIds,?MODULE,?FUNCTION_NAME,?LINE}]),


%% --------------------------------------------------------------------
%% Function:tes cases
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
