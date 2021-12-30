%% Author: uabjle
%% Created: 10 dec 2012
%% Description: TODO: Add description to application_org
-module(oam). 

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Key Data structures
%% 
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Definitions 
%% --------------------------------------------------------------------
-define(SERVER,oam_server).
%% --------------------------------------------------------------------
-export([
	 first/0,
	 first/2,
	 restart_hosts/0,
	
	 new_cluster/0,
	 call/4,
	 ping/0
	 
        ]).

-export([
	 start/0,
	 stop/0
	]).



%% ====================================================================
%% External functions
%% ====================================================================

%% Asynchrounus Signals

%% Gen server functions

start()-> gen_server:start_link({local, ?SERVER}, ?SERVER, [], []).
stop()-> gen_server:call(?SERVER, {stop},infinity).




%%---------------------------------------------------------------
-spec ping()-> {atom(),node(),module()}|{atom(),term()}.
%% 
%% @doc:check if service is running
%% @param: non
%% @returns:{pong,node,module}|{badrpc,Reason}
%%
ping()-> 
    gen_server:call(?SERVER, {ping},infinity).
restart_hosts()-> 
    gen_server:call(?SERVER, {restart_hosts},infinity).

call(Host,M,F,A)-> 
    gen_server:call(?SERVER, {call,Host,M,F,A},infinity).
first()-> 
    gen_server:call(?SERVER, {first},infinity).
first(FirstHostId,DepId)-> 
    gen_server:call(?SERVER, {first,FirstHostId,DepId},infinity).

new_cluster()-> 
    gen_server:call(?SERVER, {new_cluster},infinity).

%%----------------------------------------------------------------------
