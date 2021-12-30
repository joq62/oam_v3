%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description :  1
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(terminal).    
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

-include("controller.hrl").
-include("logger_infra.hrl").
%% --------------------------------------------------------------------

%% External exports
-export([
	 start/1
	]). 


%% ====================================================================
%% External functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Function:tes cases
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
start(ControllerNode)->
    case rpc:call(ControllerNode,sd,get,[dbase_infra],5*1000) of
	{badrpc,Reason}->
	    io:format("{error = ~p~n",[{badrpc,Reason,?MODULE,?FUNCTION_NAME,?LINE}]),
	    timer:sleep(3000),
	    start(ControllerNode);
	[]->
	    io:format("{error = ~p~n",[{error,[],?MODULE,?FUNCTION_NAME,?LINE}]),
	    timer:sleep(3000),
	    start(ControllerNode);
	[DbaseNode|_]->
	    case rpc:call(DbaseNode,db_logger,ids,[],3000) of
		{badrpc,Reason}->
		    io:format("{error = ~p~n",[{badrpc,Reason,?MODULE,?FUNCTION_NAME,?LINE}]),
		    timer:sleep(3000),
		    start(ControllerNode);
		[]->
		    io:format("{No Ids = ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE}]),
		    timer:sleep(3000),
		    start(ControllerNode);
		Ids->
		    OldNew=q_sort:sort(Ids),
		    Latest=lists:last(OldNew),
		    X=[{Id,rpc:cast(DbaseNode,db_logger,nice_print,[Id])}||Id<-OldNew],
		    spawn(fun()->print_log(ControllerNode,Latest) end)
	    end
    end,   
    ok.

print_log(ControllerNode,Latest)->
    NewLatest=case rpc:call(ControllerNode,sd,get,[dbase_infra],5*1000) of
		  {badrpc,Reason}->
		      io:format("{error = ~p~n",[{badrpc,Reason,?MODULE,?FUNCTION_NAME,?LINE}]),
		      Latest;
		  []->
		      io:format("{error, = ~p~n",[{error,[],?MODULE,?FUNCTION_NAME,?LINE}]),
		      Latest;
		  [DbaseNode|_]->
		      case rpc:call(DbaseNode,db_logger,ids,[],3000) of
			  {badrpc,Reason}->
			      io:format("{error = ~p~n",[{badrpc,Reason,?MODULE,?FUNCTION_NAME,?LINE}]),
			      Latest;
			  []->
			      io:format("{No Ids = ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE}]),
			      Latest;
			  Ids->
			      OldNew=q_sort:sort(Ids),
			      XLatest=lists:last(OldNew),
			      [rpc:cast(DbaseNode,db_logger,nice_print,[Id])||Id<-OldNew,
									   Id>Latest],
			      XLatest
		      end
	      end,   
    timer:sleep(2000),
    print_log(ControllerNode,NewLatest).
		     
%% --------------------------------------------------------------------
%% Function:tes cases
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
