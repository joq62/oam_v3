%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(lib_oam).  
    
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
-define(ClusterNodes,['compute@c200','compute@c201','compute@c202','compute@c203']).

%% External exports
-export([
	 leader/0,
	 reset_log/0,
	 reset_log/1,
	 start/0,
	 sd_all/0,
	 read_log/0,
	 read_log/1,
	 restart/1,
	 restart/0
	]).


%% ====================================================================
%% External functions
%% ====================================================================
start()->
    Ping=[{Node,net_adm:ping(Node)}||Node<-?ClusterNodes],
    io:format("Ping ~p~n",[{Ping,?MODULE,?FUNCTION_NAME,?LINE}]),
    [read_log(Node)||Node<-?ClusterNodes],
    
    ok.

%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
leader()->
    [rpc:call(Node,bully_server,who_is_leader,[],1000)||Node<-?ClusterNodes].

%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
reset_log()->
    [reset_log(Node)||Node<-?ClusterNodes].
reset_log(WNode)->
    rpc:call(WNode,os,cmd,["rm -f log/sys.log"]),
    rpc:call(WNode,file,write_file,["log/sys.log",list_to_binary("Init new sys log file\n")]),
    read_log(WNode).
%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
read_log()->
    [read_log(Node)||Node<-?ClusterNodes].

read_log(WNode)->
    Info=case rpc:call(WNode,os,cmd,["cat log/sys.log"]) of
	     {badrpc,Reason}->
		 {error,[badrpc,Reason,WNode]};
	     X->
		 string:tokens(X,"\n")
	 end,
    io:format("--------------------- ~p -------------------------~n~n",[WNode]),
    io:format(" log info ~p~n~n",[Info]).
%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------

sd_all()->
       [{Node,rpc:call(Node,application,which_applications,[],1000)}||Node<-?ClusterNodes].


%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
restart(Host)->
    
    I=[{Node,misc_node:vmid_hostid(Node)}||Node<-?ClusterNodes],
    case I of
	[]->
	    {error,[not_not_running,Host]};
	_->
	    case [Node||{Node,{_,HostId}}<-I,HostId=:=Host] of
		[]->
		    {error,[not_not_running,Host]};
		[NodeToRestart]->
		    ShutdownMsg=rpc:call(NodeToRestart,os,cmd,["reboot"],2000),
		    io:format("ShutdownMsg ~p~n",[{ShutdownMsg,?MODULE,?FUNCTION_NAME,?LINE}]),
		    ShutdownMsg
	    end
    end.
%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
restart()->    
    [{Node,rpc:call(Node,os,cmd,["reboot"],2000)}||Node<-?ClusterNodes].
