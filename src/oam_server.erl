%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : resource discovery accroding to OPT in Action 
%%% This service discovery is adapted to 
%%% Type = application 
%%% Instance ={ip_addr,{IP_addr,Port}}|{erlang_node,{ErlNode}}
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(oam_server). 

-behaviour(gen_server).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
% -include("").
%% --------------------------------------------------------------------
-define(HostConfigDir,"configurations/host_configuration").
-define(ScheduleInterval,1*30*1000).

%% External exports
-export([
	 desired_state/0
	]).


-export([init/1, handle_call/3,handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {
	       }).

%% ====================================================================
%% External functions
%% ====================================================================


desired_state()->
    gen_server:cast(?MODULE, {desired_state}).

%% ====================================================================
%% Server functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([]) ->
    ok=application:start(sd),
    ok=application:start(dbase_infra),
  
 %   io:format("mnesia:system_info ~p~n",[{rpc:call(node(),mnesia,system_info,[],5*1000),?MODULE,?FUNCTION_NAME,?LINE}]),
  %  io:format("db_service_catalog:read_all() ~p~n",[{node(),db_service_catalog:read_all(),?MODULE,?FUNCTION_NAME,?LINE}]),
    
    {ok, #state{}
    }.

%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_call({new_cluster},_From,State) ->
    Reply=rpc:call(node(),cluster,new,[],5*10*1000),
    {reply, Reply, State};


handle_call({init_dbase},_From, State) ->
    Reply=init_dbase,
    {reply, Reply, State};

handle_call({ping},_From,State) ->
    Reply={pong,node(),?MODULE},
    {reply, Reply, State};

handle_call({stop}, _From, State) ->
    {stop, normal, shutdown_ok, State};

handle_call(Request, From, State) ->
    Reply = {unmatched_signal,?MODULE,Request,From},
    {reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------

handle_cast({desired_state}, State) ->
     spawn(fun()->do_desired_state() end),
    {noreply, State};

handle_cast(Msg, State) ->
    io:format("unmatched match cast ~p~n",[{Msg,?MODULE,?LINE,time()}]),
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info(_Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
do_desired_state()->
    io:format("~p~n",[{?MODULE,?FUNCTION_NAME,?LINE,time()}]),
    timer:sleep(?ScheduleInterval),
    Result=rpc:call(node(),host_desired_state,start,[],25*1000),
    io:format("~p~n",[{Result,?MODULE,?FUNCTION_NAME,?LINE,time()}]),
    rpc:cast(node(),?MODULE,desired_state,[]).
		  
