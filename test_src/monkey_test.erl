%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description :  1
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(monkey_test).   
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

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

 %   io:format("~p~n",[{"Start pass1()",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=pass1(),
    io:format("~p~n",[{"Stop pass1()",?MODULE,?FUNCTION_NAME,?LINE}]),

 %   io:format("~p~n",[{"Start desired_state()",?MODULE,?FUNCTION_NAME,?LINE}]),
   % ok=desired_state(),
  %  io:format("~p~n",[{"Stop desired_state()",?MODULE,?FUNCTION_NAME,?LINE}]),

 %   io:format("~p~n",[{"Start os_stop()",?MODULE,?FUNCTION_NAME,?LINE}]),
  %  ok=os_stop(),
 %   io:format("~p~n",[{"Stop os_stop()",?MODULE,?FUNCTION_NAME,?LINE}]),

 
% 


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
%% --------------------------------------------------------------------

setup()->
%
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

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
%
% {mymath,"1.0.0","https://github.com/joq62/mymath.git"}.
% {mydivi,"1.0.0","https://github.com/joq62/mydivi.git"}.
% {myadd,"1.0.0","https://github.com/joq62/myadd.git"}.

pass1()->
    ControllerNodes=cluster:get_controllers(),
    [ControllerNode|_]=ControllerNodes,
    
    io:format("******** = ~p~n",[{date(),time()}]),
    io:format("ControllerNode ~p~n",[{ControllerNode,misc_node:vmid_hostid(ControllerNode),?MODULE,?FUNCTION_NAME,?LINE}]),
    io:format("leader ~p~n",[{rpc:call(ControllerNode,bully,who_is_leader,[],1000),?MODULE,?FUNCTION_NAME,?LINE}]),
    check(ControllerNode,controller),
    check(ControllerNode,mymath),
    check(ControllerNode,mydivi),
    check(ControllerNode,myadd),
    
    timer:sleep(10*1000),
    
    pass1().    

check(ControllerNode,App)->
    case rpc:call(ControllerNode,sd,get,[App],5*1000) of
	{badrpc,Reason}->
	    io:format("badrpc,Reason ~p~n",[{badrpc,Reason,?MODULE,?FUNCTION_NAME,?LINE}]),
	    ok;
	AppNodes->
	  %  I=[misc_node:vmid_hostid(Node)||Node<-AppNodes],
	    io:format("Len,Nodes = ~p~n",[{App,length_list(AppNodes),AppNodes}]),
	    ok
    end.



%    N1=length_list(StartedNodes),
    
%    N2=rand:uniform(N1),
 %   io:format("N1,N2,Started = ~p~n",[{N1,N2,StartedNodes}]),
 %   HostToStop=lists:nth(N2,StartedNodes),
 %   lib_os:restart(HostToStop),
    


length_list(L)->
    length_list(L,0).
length_list([],L)->
    L;
length_list([_|T],L)->
    length_list(T,L+1).

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------

    
