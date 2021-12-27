%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description :  1
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(install_test).   
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
%-include_lib("eunit/include/eunit.hrl").
%% --------------------------------------------------------------------

%% External exports
-export([start/0,
	 dbase_infra/0]). 


%% ====================================================================
%% External functions
%% ====================================================================


%% --------------------------------------------------------------------
%% Function:tes cases
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
start()->
    io:format("~p~n",[{"Start setup",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=setup(),
    io:format("~p~n",[{"Stop setup",?MODULE,?FUNCTION_NAME,?LINE}]),

 

    io:format("~p~n",[{"Start host()",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=host(),
    io:format("~p~n",[{"Stop host()",?MODULE,?FUNCTION_NAME,?LINE}]),

%   io:format("~p~n",[{"Start sd_bully()",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=sd_bully(),
    io:format("~p~n",[{"Stop sd_bully()",?MODULE,?FUNCTION_NAME,?LINE}]),

%   io:format("~p~n",[{"Start dbase_infra()",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=dbase_infra(),
    io:format("~p~n",[{"Stop dbase_infra()",?MODULE,?FUNCTION_NAME,?LINE}]),
 
%   io:format("~p~n",[{"Start single()",?MODULE,?FUNCTION_NAME,?LINE}]),
 %   ok=single(),
 %   io:format("~p~n",[{"Stop single()",?MODULE,?FUNCTION_NAME,?LINE}]),

   % io:format("~p~n",[{"Start cluster()",?MODULE,?FUNCTION_NAME,?LINE}]),
   % ok=cluster(),
   % io:format("~p~n",[{"Stop cluster()",?MODULE,?FUNCTION_NAME,?LINE}]),

 
      %% End application tests
    io:format("~p~n",[{"Start cleanup",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=cleanup(),
    io:format("~p~n",[{"Stop cleaup",?MODULE,?FUNCTION_NAME,?LINE}]),
   
    io:format("------>"++atom_to_list(?MODULE)++" ENDED SUCCESSFUL ---------"),
    ok.

-define(ServiceCatalog,"service.catalog").
-define(ApplicationDir,"applications").

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
dbase_infra()->
    io:format("Start  ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE}]),
    {ok,I}=file:consult(?ServiceCatalog),
    [{_Host,OneNode}|_]=[{Host,host_config:node(Host)}||Host<-lib_status:node_started()],
    Running=rpc:call(OneNode,application,which_applications,[],1000),
  %  io:format(" Running ~p~n",[{Running,?MODULE,?FUNCTION_NAME,?LINE}]),
    case lists:keymember(dbase_infra,1,Running) of
	false->
	    io:format(" start dbase_infra  ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE}]),
	    ok=start_app(lists:keyfind(dbase_infra,1,I));
	true->
%	    io:format("dbase no action ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE}]),
	    ok
    end,
    
 %   io:format("who_is_leader() ~p~n",[{rpc:call(OneNode,bully,who_is_leader,[],1000),?MODULE,?FUNCTION_NAME,?LINE}]),
    timer:sleep(20000),
  %  io:format("  ~p~n",[{rpc:call(OneNode,db_deployment,read_all,[],1000),?MODULE,?FUNCTION_NAME,?LINE}]),
    io:format("End  ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE}]),
    dbase_infra().
    %ok.
    
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------

sd_bully()->
 %   {ok,Bin}=file:read_file(?ServiceCatalog),
 %   HostNode200=host_config:node("c200"),
 %   R_delete=rpc:call(HostNode200,file,delete,["service.catalog"],1000),
 %   io:format("R_delete  ~p~n",[{R_delete,?MODULE,?FUNCTION_NAME,?LINE}]),
  %  R_delete=rpc:call(HostNode200,file,delete,["service.catalog"],1000),
    
    {ok,I}=file:consult(?ServiceCatalog),
    [{_Host,OneNode}|_]=[{Host,host_config:node(Host)}||Host<-lib_status:node_started()],
    Running=rpc:call(OneNode,application,which_applications,[],1000),
 %   io:format(" Running ~p~n",[{Running,?MODULE,?FUNCTION_NAME,?LINE}]),
    case lists:keymember(sd,1,Running) of
	false->
	    io:format(" start sd  ~p~n",[{sd,?MODULE,?FUNCTION_NAME,?LINE}]),
	    ok=start_app(lists:keyfind(sd,1,I));
	true->
	 %   io:format("sd no action ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE}]),
	    ok
    end,
    case lists:keymember(bully,1,Running) of
	false->
	  %  io:format(" start bully  ~p~n",[{bully,?MODULE,?FUNCTION_NAME,?LINE}]),
	    NodeStarted=[host_config:node(Host)||Host<-lib_status:node_started()],
	 %   [rpc:call(Node,application,set_env,[[{bully,[{nodes,Nodes}]}]])||Node<-NodeStarted],
	    ok=start_app(lists:keyfind(bully,1,I));
	true->
	  %  io:format("bully no action ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE}]),
	    ok
    end,
 %   io:format("who_is_leader() ~p~n",[{rpc:call(OneNode,bully,who_is_leader,[],1000),?MODULE,?FUNCTION_NAME,?LINE}]),
    timer:sleep(20000),
 %   io:format("bully  ~p~n",[{rpc:call(OneNode,application,get_env,[bully,nodes],1000),?MODULE,?FUNCTION_NAME,?LINE}]),
 %   io:format("dbase_infra  ~p~n",[{rpc:call(OneNode,application,get_env,[dbase_infra,nodes],1000),?MODULE,?FUNCTION_NAME,?LINE}]),
    
   % spawn(fun()->sd_bully() end).
    ok.
start_app({App,Vsn,GitPath})->
   
    NodeStarted=[{Host,host_config:node(Host)}||Host<-lib_status:node_started()],

  %  io:format(" NodeStarted ~p~n",[{NodeStarted,?MODULE,?FUNCTION_NAME,?LINE}]),
     R_Stop=[{Host,stop_app(Node,App)}||{Host,Node}<-NodeStarted],
  %  io:format("R_Stop  ~p~n",[{R_Stop,?MODULE,?FUNCTION_NAME,?LINE}]),
    R_load=[{Host,load_service(Node,?ApplicationDir,{App,Vsn,GitPath})}||{Host,Node}<-NodeStarted],
  %  io:format("R_load  ~p~n",[{R_load,?MODULE,?FUNCTION_NAME,?LINE}]),
    R_start=[{Host,rpc:call(Node,application,start,[App],5000)}||{Host,Node}<-NodeStarted],
  %  io:format("R_start  ~p~n",[{R_start,?MODULE,?FUNCTION_NAME,?LINE}]),
    ok.

load_service(Node,RootDir,{App,Vsn,GitPath})->
    AppId=atom_to_list(App),
    SourceDir=AppId,
    DestDir=filename:join(RootDir,AppId++"-"++Vsn),
    rpc:call(Node,os,cmd,["rm -rf "++DestDir],2000),
    timer:sleep(1000),
    rpc:call(Node,os,cmd,["git clone "++GitPath],2000),
    timer:sleep(1000),
    rpc:call(Node,os,cmd,["mv "++SourceDir++" "++DestDir],2000),
    timer:sleep(1000),
    Result=case rpc:call(Node,code,add_patha,[filename:join(DestDir,"ebin")],2000) of
	       true->
		   rpc:call(Node,application,load,[App],2000),
		   {ok,App};
	       Reason->
		   {error,[Reason,App,DestDir]}
	   end,
    io:format(" ~p~n",[Result]),
    Result.

stop_app(Node,App)->
    rpc:call(Node,application,stop,[App],1000),
    ok.

    

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
host()->
    spawn(fun()->print_status(2*60*1000) end),
    ok=application:start(sd),
    ok=application:start(host),
  %  io:format("sd:all() ~p~n",[{sd:all(),?MODULE,?FUNCTION_NAME,?LINE}]),
    X=[{Host,lib_os:restart(Host)}||Host<-lib_status:node_started()],
    io:format("X ~p~n",[{X,?MODULE,?FUNCTION_NAME,?LINE}]),
    timer:sleep(60*1000),
    
    
    ok.


print_status(Sleep)->
  %  io:format("os_started ~p~n",[{time(),lib_status:os_started()}]),
  %  io:format("os_stopped ~p~n",[{time(),lib_status:os_stopped()}]),
  %  io:format("node_started ~p~n",[{time(),lib_status:node_started()}]),
  %  io:format("node_stopped ~p~n",[{time(),lib_status:node_stopped()}]),
    NodeStarted=[{Host,host_config:node(Host)}||Host<-lib_status:node_started()],
    [io:format("~p~n",[{Host,rpc:call(Node,application,which_applications,[],1000)}])||{Host,Node}<-NodeStarted],
    timer:sleep(Sleep),
    print_status(Sleep).
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
dist_nodes(Nodes)->
    
    [Node||Node<-[glurk|Nodes],rpc:call(Node,db_lock,check_init,[],2000)=:=ok].


single()->
  %  cSlaves=create_nodes(),
  
    Nodes=[node()|nodes()],
    
    []=dist_nodes(Nodes),
    
    

     [{'test@joq62-X550CA',{error,[mnesia_not_started]}},
      {'a@joq62-X550CA',{error,[mnesia_not_started]}},
      {'b@joq62-X550CA',{error,[mnesia_not_started]}},
      {'c@joq62-X550CA',{error,[mnesia_not_started]}}]=[{Node,rpc:call(Node,db_lock,check_init,[],2000)}||Node<-Nodes],
    
    ok=init_distributed_mnesia(Nodes),

    []=dist_nodes(Nodes),
    
    [{'test@joq62-X550CA',{error,[not_initiated,db_lock]}},
     {'a@joq62-X550CA',{error,[not_initiated,db_lock]}},
     {'b@joq62-X550CA',{error,[not_initiated,db_lock]}},
     {'c@joq62-X550CA',{error,[not_initiated,db_lock]}}
    ]=[{Node,rpc:call(Node,db_lock,check_init,[],2000)}||Node<-Nodes],
    
    ok=lock(),
    [{'test@joq62-X550CA',ok},
     {'a@joq62-X550CA',ok},
     {'b@joq62-X550CA',ok},
     {'c@joq62-X550CA',ok}
    ]=[{Node,rpc:call(Node,db_lock,check_init,[],2000)}||Node<-Nodes],

    ['test@joq62-X550CA','a@joq62-X550CA',
     'b@joq62-X550CA','c@joq62-X550CA']=dist_nodes(Nodes),
    ok=loose_restart_node(),    
  %  ok=db_lock:create_table(),
  %  {atomic,ok}=db_lock:create(leader,0),
  %  [{leader,0,'test@joq62-X550CA'}]=db_lock:read_all_info(),
  %  true=db_lock:is_open(leader,node()),
  %  ['test@joq62-X550CA']=db_lock:leader(leader),
    
  %  true=db_lock:is_leader(leader,node()),
	     
  %  ['test@joq62-X550CA']=db_lock:leader(leader),
  %  timer:sleep(2500),
    
   % true=db_lock:is_open(leader,node1,2),
   % false=db_lock:is_leader(leader,node()),
   % true=db_lock:is_leader(leader,node1),
   % true=rpc:call(Node1,db_lock,is_open,[leader,Node1,1],2000),
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
-define(NodeNames,["a","b","c"]).
create_nodes()->
    Cookie=atom_to_list(erlang:get_cookie()),
    NodeInfo=[{NodeName,"-pa ebin -setcookie "++Cookie}||NodeName<-?NodeNames],
    SlaveStart=[slave:start(net_adm:localhost(),NodeName,Arg)||{NodeName,Arg}<-NodeInfo],
    [{ok,'a@joq62-X550CA'},
     {ok,'b@joq62-X550CA'},
     {ok,'c@joq62-X550CA'}]=SlaveStart,
    Slaves=[Slave||{ok,Slave}<-SlaveStart],
   
    [pong,pong,pong]=[net_adm:ping(Slave)||Slave<-Slaves],
    
    Slaves.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
init_dist_mnesia()->
    AllNodes=[node()|nodes()],
    ok=init_distributed_mnesia(AllNodes),
    ok.

init_distributed_mnesia(Nodes)->
    StopResult=[rpc:call(Node,mnesia,stop,[],5*1000)||Node<-Nodes],
    Result=case [Error||Error<-StopResult,Error/=stopped] of
	       []->
		   case mnesia:delete_schema(Nodes) of
		       ok->
			   StartResult=[rpc:call(Node,mnesia,start,[],5*1000)||Node<-Nodes],
			   case [Error||Error<-StartResult,Error/=ok] of
			       []->
				   ok;
			       Reason->
				   {error,[Reason,?FUNCTION_NAME,?MODULE,?LINE]}
			   end;
		       Reason->
			   {error,[Reason,?FUNCTION_NAME,?MODULE,?LINE]}
		   end;
	       Reason->
		   {error,[Reason,?FUNCTION_NAME,?MODULE,?LINE]}
	   end,
    Result.
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non

create_tables()->
    ok=db_lock:create_table(),
    [db_lock:add_node(Node,ram_copies)||Node<-nodes()],
    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
loose_restart_node()->
    HostId=net_adm:localhost(),    
    KilledNode='a@joq62-X550CA',
    DistR1 =[{Node,rpc:call(Node,db_lock,read_all_info,[],5*1000)}||Node<-nodes()],
    [{'a@joq62-X550CA',[{host_lock,_,'a@joq62-X550CA'}]},
     {'b@joq62-X550CA',[{host_lock,_,'a@joq62-X550CA'}]},
     {'c@joq62-X550CA',[{host_lock,_,'a@joq62-X550CA'}]}]=DistR1,

 %   {atomic,glok}=rpc:call(KilledNode,db_lock,create,[leader,0,KilledNode],5*1000),
	
    slave:stop(KilledNode),
   % timer:sleep(100),
    pang=net_adm:ping(KilledNode),
    DistR2 =[{Node,rpc:call(Node,db_lock,read_all_info,[],5*1000)}||Node<-nodes()],
    [{'b@joq62-X550CA',[{host_lock,_,'a@joq62-X550CA'}]},
     {'c@joq62-X550CA',[{host_lock,_,'a@joq62-X550CA'}]}]=DistR2, 

    timer:sleep(1200),
    true=rpc:call('b@joq62-X550CA',db_lock,is_open,[host_lock,'b@joq62-X550CA',1],5*1000),    
    %Leader checks if a node is absent
  
    MissingNodes=check_missing_nodes(),
    [KilledNode]=MissingNodes,
    
    % Restart node
    [NodeName,HostId]=string:tokens(atom_to_list(KilledNode),"@"),
    Cookie=atom_to_list(erlang:get_cookie()),
    Arg="-pa ebin -setcookie "++Cookie,
    {ok,KilledNode}=slave:start(HostId,NodeName,Arg),    
    
    %% 

    % Add to cluster
    stopped=rpc:call(KilledNode,mnesia,stop,[],5*1000),
    ok=rpc:call(KilledNode,mnesia,start,[],5*1000),
    [Node1|_]=rpc:call(KilledNode,erlang,nodes,[],2000),
    
    ok=rpc:call(Node1,db_lock,add_node,[KilledNode,ram_copies],2000),

    DistR3 =[{Node,rpc:call(Node,db_lock,read_all_info,[],5*1000)}||Node<-nodes()],
    [{'b@joq62-X550CA',[{host_lock,_,'b@joq62-X550CA'}]},
     {'c@joq62-X550CA',[{host_lock,_,'b@joq62-X550CA'}]},
     {'a@joq62-X550CA',[{host_lock,_,'b@joq62-X550CA'}]}]=DistR3, 
    
    false=rpc:call('c@joq62-X550CA',db_lock,is_leader,[host_lock,'a@joq62-X550CA'],2000),
    ok. 

check_missing_nodes()->
    DBNodes=mnesia:system_info(db_nodes),
    RunningDBNodes=mnesia:system_info(running_db_nodes),
    MissingNodes=[Node||Node<-DBNodes,
		       false==lists:member(Node,RunningDBNodes)],
    MissingNodes.
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
lock()->
    ok=db_lock:create_table(),
    [db_lock:add_node(Node,ram_copies)||Node<-nodes()],
    {atomic,ok}=db_lock:create(host_lock,1,node()),
  
    DistR1 =[{Node,rpc:call(Node,db_lock,read_all_info,[],5*1000)}||Node<-nodes()],
     [{'a@joq62-X550CA',[{host_lock,1,'test@joq62-X550CA'}]},
      {'b@joq62-X550CA',[{host_lock,1,'test@joq62-X550CA'}]},
      {'c@joq62-X550CA',[{host_lock,1,'test@joq62-X550CA'}]}
     ]=DistR1,


    ['test@joq62-X550CA']=db_lock:leader(host_lock),
    timer:sleep(1200),
    true=rpc:call('a@joq62-X550CA',db_lock,is_open,[host_lock,'a@joq62-X550CA'],5*1000),
    false=db_lock:is_open(host_lock,node()),
    Lock1 =[{Node,rpc:call(Node,db_lock,leader,[host_lock],5*1000)}||Node<-nodes()],
    [{'a@joq62-X550CA',['a@joq62-X550CA']},
     {'b@joq62-X550CA',['a@joq62-X550CA']},
     {'c@joq62-X550CA',['a@joq62-X550CA']}]=Lock1,
    

    

    ok.



%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
pass_2()->
    
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

setup()->
   
   ok.


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------    

cleanup()->
  
  %  application:stop(etcd),
  %  init:stop(),
    ok.
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
