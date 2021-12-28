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
-define(ClusterNodes,['compute@c200','compute@c201','compute@c202','compute@c203']).

%% External exports
-export([
	 new/0
	]).


%% ====================================================================
%% External functions
%% ====================================================================
new()->
    Result=case restart_hosts_nodes() of
	       {error,StartRes}->
		   {error,StartRes};
	       {ok,HostIdNodesList}-> %[{HostId,HostNode}]
		   %% load infra in Host
		   case start_infra(HostIdNodesList) of
		       {error,Reason}->
			   {error,Reason};
		       {ok,StartList}->
			   {ok,StartList}
		   end
	   end,
    Result.

start_infra(HostIdNodesList)->
    start_infra(HostIdNodesList,[]).
start_infra([],StartRes)->
    {ok,StartRes};
start_infra([{HostId,HostNode}|T],Acc)->
    PodDir=db_host:application_dir(HostId),
    Pod=HostNode,
    Env=[],
    {SdApp,SdVsn,SdGitPath}=db_service_catalog:read({sd,"1.0.0"}),
    ok=pod:load_app(Pod,PodDir, {SdApp,SdVsn,SdGitPath}),
    ok=pod:start_app(Pod,SdApp,Env),
    LoadStartRes=case db_host:type(HostId) of
		     no_auto_erl_worker->
			 [{SdApp,SdVsn,PodDir,Pod}];
		     auto_erl_controller->
			 {BullyApp,BullyVsn,BullyGitPath}=db_service_catalog:read({bully,"0.1.0"}),
			 ok=pod:load_app(Pod,PodDir, {BullyApp,BullyVsn,BullyGitPath}),
			 ok=pod:start_app(Pod,BullyApp,Env),
			 [{SdApp,SdVsn,PodDir,Pod},{BullyApp,BullyVsn,PodDir,Pod}]
		 end,
    NewAcc=lists:append([LoadStartRes,Acc]),
    start_infra(T,NewAcc).				      
	
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% ------------------------------------------------------------------- 
deploy_infra()->
    DepIds=[{"infra_1","1.0.0"},{"infra_2","1.0.0"},{"infra_3","1.0.0"}],
    deploy_infra(DepIds,[]).

deploy_infra([],StartRes)->
    Z1=lists:append(StartRes),
    Z2=[{error,Reason}||{error,Reason}<-Z1],
    Result=case Z2 of
	       []->
		   {ok,[X||{ok,X}<-Z1]};
	       ErrorList->
		   {error,ErrorList}
	   end,
    Result;
   % StartRes;

deploy_infra([DepId|T],Acc) ->
    {ok,DeploymentId}=db_deploy_state:create(DepId,[]),
    AffinityList=db_deployment:affinity(DepId),
    DeployRes=lists:append([deploy_pod(PodId,AffinityList,DepId,DeploymentId)||PodId<-db_deployment:pod_specs(DepId)]),
    deploy_infra(T,[DeployRes|Acc]).

    

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% ------------------------------------------------------------------- 
deploy_pod(PodId,AffinityList,DepId,DeploymentId)->
    Result=case db_pods:needs(PodId) of
	       []->
		   case pod:scoring_hosts(AffinityList) of
		       {error,[no_nodes_available]}->
			   {error,[no_nodes_available]};
		       [HostId|_]->
			   case pod:start_pod(PodId,HostId,DepId,DeploymentId) of
			       {error,Reason}->
				   {error,Reason};
			       {ok,PodNode,PodDir} ->
				   Applications=db_pods:application(PodId),
				   pod:load_start_apps(Applications,PodId,PodNode,PodDir)
			   end
		   end;
	       PodNeeds->
		   Candidates=pod:filter_hosts(PodNeeds,AffinityList),
		   case pod:scoring_hosts(Candidates) of
		       {error,[no_nodes_available]}->
			   {error,[no_nodes_available]};
		       [HostId|_]->
			   %% Choosen 
			   case pod:start_pod(PodId,HostId,DepId,DeploymentId) of
			       {error,Reason}->
				   {error,Reason};
			       {ok,PodNode,PodDir} ->
				   AppIds=db_pods:application(PodId),
				   pod:load_start_apps(AppIds,PodId,PodNode,PodDir)
			   end
		   end
	   end,
    Result.

%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
restart_hosts_nodes()->
    Nodes=[db_host:node(Id)||Id<-db_host:ids()],
    [rpc:call(Node,init,stop,[],5*1000)||Node<-Nodes],
    timer:sleep(1000),
    %% start all hosts
    Ids=db_host:ids(),
    Result=case map_ssh_start(Ids) of
	       {ok,StartRes}->
		%   io:format("StartRes ~p~n",[{StartRes,?MODULE,?FUNCTION_NAME,?LINE}]),
		   %[rpc:call(N,os,cmd,["rm -rf *.pod"],5*1000)||{_Id,N}<-StartRes],
		   [{_Id,Node1}|_]=StartRes,
		   [rpc:call(Node1,net_adm,ping,[N],5*1000)||{_Id,N}<-StartRes],
		   
		   {ok,StartRes};
	       {error,StartRes}->
		   {error,StartRes}  
	   end,
    Result.

map_ssh_start(Ids)->
    F1=fun ssh_start/2,
    F2 = fun check_start/3,
    StartRes=mapreduce:start(F1,F2,[],Ids),
    Result=case [{error,Reason}||{error,Reason}<-StartRes] of
	       []->
		   Filtered=[{HostId,HostNode}||{ok,[HostId,HostNode]}<-StartRes],
		   {ok,Filtered};
	       _->
		   {error,StartRes}
	   end,
%   io:format("~p~n",[Result]),
    Result.

ssh_start(Pid,Id)->
    Pid!{ssh_start,pod:ssh_start(Id)}.

check_start(Key,Vals,[])->
  %  io:format("~p~n",[{?MODULE,?LINE,Key,Vals}]),
    check_start(Vals,[]).

check_start([],StartResult)->
    StartResult;
check_start([{error,Reason}|T],Acc) ->
    io:format("~p~n",[{error,Reason,?MODULE,?FUNCTION_NAME,?LINE}]),
    NewAcc=[{error,Reason}|Acc],
    check_start(T,NewAcc);
check_start([{ok,Reason}|T],Acc) ->
 %  io:format("~p~n",[{ok,Reason,?MODULE,?FUNCTION_NAME,?LINE}]),
    
    NewAcc=[{ok,Reason}|Acc],
    check_start(T,NewAcc).

 
