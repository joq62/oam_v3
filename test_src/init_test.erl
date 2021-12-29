%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description :  1
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(init_test).    
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

-include("controller.hrl").
%% --------------------------------------------------------------------

%% External exports
-export([start/0]). 


%% ====================================================================
%% External functions
%% ====================================================================


%% --------------------------------------------------------------------
%% Function:tes cases
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
start()->
  %  io:format("~p~n",[{"Start setup",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=setup(),
  %  io:format("~p~n",[{"Stop setup",?MODULE,?FUNCTION_NAME,?LINE}]),

%    io:format("~p~n",[{"Start first_cluster()",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=first_cluster(),
    io:format("~p~n",[{"Stop initial()()",?MODULE,?FUNCTION_NAME,?LINE}]),

 %   io:format("~p~n",[{"Start add_node()",?MODULE,?FUNCTION_NAME,?LINE}]),
 %   ok=add_node(),
 %   io:format("~p~n",[{"Stop add_node()",?MODULE,?FUNCTION_NAME,?LINE}]),

 %   io:format("~p~n",[{"Start node_status()",?MODULE,?FUNCTION_NAME,?LINE}]),
 %   ok=node_status(),
 %   io:format("~p~n",[{"Stop node_status()",?MODULE,?FUNCTION_NAME,?LINE}]),

%   io:format("~p~n",[{"Start start_args()",?MODULE,?FUNCTION_NAME,?LINE}]),
 %   ok=start_args(),
 %   io:format("~p~n",[{"Stop start_args()",?MODULE,?FUNCTION_NAME,?LINE}]),

%   io:format("~p~n",[{"Start detailed()",?MODULE,?FUNCTION_NAME,?LINE}]),
%    ok=detailed(),
%    io:format("~p~n",[{"Stop detailed()",?MODULE,?FUNCTION_NAME,?LINE}]),

%   io:format("~p~n",[{"Start start_stop()",?MODULE,?FUNCTION_NAME,?LINE}]),
 %   ok=start_stop(),
 %   io:format("~p~n",[{"Stop start_stop()",?MODULE,?FUNCTION_NAME,?LINE}]),



 %   
      %% End application tests
  %  io:format("~p~n",[{"Start cleanup",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=cleanup(),
  %  io:format("~p~n",[{"Stop cleaup",?MODULE,?FUNCTION_NAME,?LINE}]),
   
    io:format("------>"++atom_to_list(?MODULE)++" ENDED SUCCESSFUL ---------"),
    ok.



%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
first_cluster()->
  %  io:format("service_catalog ~p~n",[{db_service_catalog:read_all(),?MODULE,?FUNCTION_NAME,?LINE}]),
    {ok,AppInfo}=oam:new_cluster(), 
    io:format(" AppInfo ~p~n",[{AppInfo,?MODULE,?FUNCTION_NAME,?LINE}]),

    %% 
    [CtrlNode|_]=[N||{{"controller","1.0.0"},N,_Dir,_App,Vsn}<-AppInfo],
    
    io:format("CtrlNode, sd:all() ~p~n",[{rpc:call(CtrlNode,sd,all,[],5*1000),?MODULE,?FUNCTION_NAME,?LINE}]),
    timer:sleep(1000),
   io:format(" who_is_leader ~p~n",[{rpc:call(CtrlNode,bully,who_is_leader,[],5*1000),?MODULE,?FUNCTION_NAME,?LINE}]),

    
    %%
    DbaseNodes=rpc:call(CtrlNode,sd,get,[dbase_infra],5*1000),
    io:format("DbaseNodes ~p~n",[{DbaseNodes,?MODULE,?FUNCTION_NAME,?LINE}]),
    X1=[{N,rpc:call(N,db_service_catalog,read_all,[],5*1000)}||N<-DbaseNodes],
    io:format("db_service_catalog ~p~n",[{X1,?MODULE,?FUNCTION_NAME,?LINE}]),
    X2=[{N,rpc:call(N,mnesia,system_info,[],5*1000)}||N<-DbaseNodes],
    io:format("mnesia:system_info ~p~n",[{X2,?MODULE,?FUNCTION_NAME,?LINE}]),
    
    %%
    io:format("db_deploy_state ~p~n",[{db_deploy_state:read_all(),?MODULE,?FUNCTION_NAME,?LINE}]),
    

    
    
    ok.

  
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% ------------------------------------------------------------------- 
load_deployment(DepId)->
%    gl=db_deployment:read(DepId),
 %   LoadR=[clean_load_controller(Id)||Id<-db_host:ids()],
    %% 
    {ok,DeploymentId}=db_deploy_state:create(DepId,[]),
  %  gl=db_deploy_state:read_all(),
    DeployRes=deploy_pods(DepId,DeploymentId),
    Result=case [{error,Reason}||{error,Reason}<-DeployRes] of
	       []->
		   ok;
	       ErrorList->
	       {error,ErrorList}
    end,
    Result.

   
    

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% ------------------------------------------------------------------- 
deploy_pods(DepId,DeploymentId)->
    AffinityList=db_deployment:affinity(DepId),
    [deploy_pod(PodId,AffinityList,DepId,DeploymentId)||PodId<-db_deployment:pod_specs(DepId)].
    
   



%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% ------------------------------------------------------------------- 
deploy_pod(PodId,AffinityList,DepId,DeploymentId)->
    Result=case db_pods:needs(PodId) of
	       []->
		   case scoring_hosts(AffinityList) of
		       {error,[no_nodes_available]}->
			   {error,[no_nodes_available]};
		       [HostId|_]->
			   case start_pod(PodId,HostId,DepId,DeploymentId) of
			       {error,Reason}->
				   {error,Reason};
			       {ok,PodNode,PodDir} ->
				   Applications=db_pods:application(PodId),
				   load_start_apps(Applications,PodId,PodNode,PodDir)
			   end
		   end;
	       PodNeeds->
		   Candidates=filter_hosts(PodNeeds,AffinityList),
		   case scoring_hosts(Candidates) of
		       {error,[no_nodes_available]}->
			   {error,[no_nodes_available]};
		       [HostId|_]->
			   %% Choosen 
			   case start_pod(PodId,HostId,DepId,DeploymentId) of
			       {error,Reason}->
				   {error,Reason};
			       {ok,PodNode,PodDir} ->
				   AppIds=db_pods:application(PodId),
				   load_start_apps(AppIds,PodId,PodNode,PodDir)
			   end
		   end
	   end,
    Result.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% ------------------------------------------------------------------- 
load_start_apps(AppIds,PodId,PodNode,PodDir)->
    io:format("AppIds,PodId,PodNode,PodDir ~p~n",[{AppIds,PodId,PodNode,PodDir,?MODULE,?FUNCTION_NAME,?LINE}]),
    load_start_app(AppIds,PodId,PodNode,PodDir,[]).
    
load_start_app([],_PodId,_PodNode,_PodDir,StartRes)->
    StartRes;
load_start_app([AppId|T],PodId,PodNode,PodDir,Acc)->
    App=db_service_catalog:app(AppId),
    Vsn=db_service_catalog:vsn(AppId),
    GitPath=db_service_catalog:git_path(AppId),
    NewAcc=case pod:load_app(PodNode,PodDir,{App,Vsn,GitPath}) of
	       {error,Reason}->
		   [{error,Reason}|Acc];
	       ok->
		   Env=[],
		   case pod:start_app(PodNode,App,Env) of
		       {error,Reason}->
			   [{error,Reason}|Acc];
		       ok->
			   [{ok,PodId,PodNode,PodDir,App,Vsn}|Acc]
		   end
	   end,
    load_start_app(T,PodId,PodNode,PodDir,NewAcc).


    
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% ------------------------------------------------------------------- 
start_pod(PodId,HostId,DepId,DeploymentId)->
     UniquePod=integer_to_list(erlang:system_time(millisecond)),
    {PodName,_Vsn}=PodId,
    NodeName=PodName++"_"++UniquePod,
    PodDir=NodeName++".pod",
    HostNode=db_host:node(HostId),
    HostName=db_host:hostname(HostId),
    rpc:call(HostNode,os,cmd,["rm -rf "++PodDir],5*1000),
    timer:sleep(1000),
    ok=rpc:call(HostNode,file,make_dir,[PodDir],5*1000),
    Cookie=atom_to_list(erlang:get_cookie()),
    Args="-setcookie "++Cookie,
    Result=case pod:start_slave(HostNode,HostName,NodeName,Args,PodDir) of
	       {error,Reason}->
		   rpc:call(HostNode,os,cmd,["rm -rf "++PodDir],5*1000),
		   {error,Reason};
	       {ok,PodNode,PodDir} ->
		   {atomic,ok}=db_deploy_state:add_pod_status(DeploymentId,{PodNode,PodDir,PodId}),
		   {ok,PodNode,PodDir} 
	   end,
    Result.
    

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% ------------------------------------------------------------------- 

filter_hosts([],AffinityList)->
    AffinityList;
filter_hosts({hosts,HostList},AffinityList)->
    Candidates=[Id||Id<-AffinityList,
		    lists:member(Id,HostList),
	            pong=:=net_adm:ping(list_to_atom(db_host:node(Id)))],
    Candidates.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
scoring_hosts([])->
    {error,[no_nodes_available]};
scoring_hosts(Candidates)->
    NodeAdded=[{Id,db_host:node(Id)}||Id<-Candidates],
     Z=[{lists:flatlength(L),Node}||{Node,L}<-sd:all()],
 %   io:format("Z ~p~n",[Z]),
    S1=lists:keysort(1,Z),
 %   io:format("S1 ~p~n",[S1]),
    SortedList=lists:reverse([Id||{Id,Node}<-NodeAdded,
		 lists:keymember(Node,2,S1)]),
    SortedList.
    

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% ------------------------------------------------------------------- 
pods_needs(PodIds)->
    pods_needs(PodIds,[]).

pods_needs([],Needs)->
    Needs;
pods_needs([PodId|T],Acc)->
    NewAcc=case db_pods:needs(PodId) of
	       []->
		   Acc;
	       Need->
		   [{PodId,Need}|Acc]
	   end,
    
    pods_needs(T,NewAcc).


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% ------------------------------------------------------------------- 
start_loader()->
%   ok=lib_controller:load_configs(),
    ok=application:start(dbase_infra),
    ok=dbase_infra:init_dynamic(),
    ok.


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% ------------------------------------------------------------------- 
restart_hosts_nodes()->
    Nodes=[db_host:node(Id)||Id<-db_host:ids()],
    [rpc:call(Node,init,stop,[],5*1000)||Node<-Nodes],
    timer:sleep(1000),
    %% start all hosts
    Ids=db_host:ids(),
    Result=case map_ssh_start(Ids) of
	       {ok,StartRes}->
		   [rpc:call(N,os,cmd,["rm -rf *.pod"],5*1000)||{ok,[_Id,N]}<-StartRes],
		   {ok,StartRes};
	       {error,StartRes}->
		   {error,StartRes}  
	   end,
    Result.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% ------------------------------------------------------------------- 


load_infra_pod([],_NodeName,_PodDir,LoadRes)->
    LoadRes;
load_infra_pod([[{ok,HostId,HostNode}]|T],NodeName,PodDir,Acc)->
    {ok,Pod,PodDir}=pod:start_slave(HostId,NodeName,PodDir),
    SdAppInfo=db_service_catalog:read({sd,"1.0.0"}),
    BullyAppInfo=db_service_catalog:read({bully,"0.1.0"}),
    DbaseInfraAppInfo=db_service_catalog:read({dbase_infra,"0.1.0"}),
    LoadRes=[load(Pod,PodDir,AppInfo)||AppInfo<-[SdAppInfo,
						 BullyAppInfo,
						 DbaseInfraAppInfo]],
    NewAcc=[LoadRes|Acc],
    load_infra_pod(T,NodeName,PodDir,NewAcc).
 

load(Pod,PodDir,AppInfo)->
    pod:load_app(Pod,PodDir,AppInfo).
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------  
stop_hosts()->
   
    ok.

map_ssh_start(Ids)->
    F1=fun ssh_start/2,
    F2 = fun check_start/3,
    StartRes=mapreduce:start(F1,F2,[],Ids),
    Result=case [{error,Reason}||{error,Reason}<-StartRes] of
	       []->
		   {ok,StartRes};
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

 
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
add_node()->
   
   
    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------

    

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------



%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------

get_nodes()->
    [host1@c100,host2@c100,host3@c100,host4@c100].
    
start_slave(NodeName)->
    HostId=net_adm:localhost(),
    Node=list_to_atom(NodeName++"@"++HostId),
    rpc:call(Node,init,stop,[]),
    
    Cookie=atom_to_list(erlang:get_cookie()),
   % gl=Cookie,
    Args="-pa ebin -setcookie "++Cookie,
    io:format("Node Args ~p~n",[{Node,Args}]),
    {ok,Node}=slave:start(HostId,NodeName,Args).

setup()->
 
    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------    

cleanup()->
  
    ok.
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------

access_info_all()->
    
    A=[{{"c100","host0"},
	[{hostname,"c100"},
	 {ip,"192.168.0.100"},
	 {ssh_port,22},
	 {uid,"joq62"},
	 {pwd,"festum01"},
	 {node,host0@c100}],
	auto_erl_controller,
	[{erl_cmd,"/lib/erlang/bin/erl -detached"},
	 {cookie,"cookie"},
	 {env_vars,
	  [{kublet,[{mode,controller}]},
	   {dbase_infra,[{nodes,[host1@c100,host2@c100]}]},
	   {bully,[{nodes,[host1@c100,host2@c100]}]}]},
	 {nodename,"host0"}],
	["logs"],
	"applications",stopped},
       {{"c100","host1"},
	[{hostname,"c100"},
	 {ip,"192.168.0.100"},
	 {ssh_port,22},
	 {uid,"joq62"},
	 {pwd,"festum01"},
	 {node,host1@c100}],
	auto_erl_controller,
	[{erl_cmd,"/lib/erlang/bin/erl -detached"},
	 {cookie,"cookie"},
	 {env_vars,
	  [{kublet,[{mode,controller}]},
	   {dbase_infra,[{nodes,[host0@c100,host2@c100]}]},
	   {bully,[{nodes,[host0@c100,host2@c100]}]}]},
	 {nodename,"host1"}],
	["logs"],
	"applications",stopped},
       {{"c100","host2"},
	[{hostname,"c100"},
	 {ip,"192.168.0.100"},
	 {ssh_port,22},
	 {uid,"joq62"},
	 {pwd,"festum01"},
	 {node,host2@c100}],
	auto_erl_controller,
	[{erl_cmd,"/lib/erlang/bin/erl -detached"},
	 {cookie,"cookie"},
	 {env_vars,
	  [{kublet,[{mode,controller}]},
	   {dbase_infra,[{nodes,[host0@c100,host1@c100]}]},
	   {bully,[{nodes,[host0@c100,host1@c100]}]}]},
	 {nodename,"host2"}],
	["logs"],
	"applications",stopped}],
    lists:keysort(1,A).
