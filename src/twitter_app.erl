%%%-------------------------------------------------------------------
%% @doc twitter public API
%% @end
%%%-------------------------------------------------------------------

-module(twitter_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    lager:info("~w~n", [jsone:decode(<<"[1,2,3]">>)]),
    TwitterEnginePID = spawn_link(twitter_engine, start, [{#{}, #{}}]),
    Dispatch = cowboy_router:compile([
		{'_', [
			{"/", cowboy_static, {priv_file, twitter, "index.html"}},
			{"/style.css", cowboy_static, {priv_file, twitter, "style.css"}},
			{"/websocket", ws_h, [TwitterEnginePID]},
			{"/static/[...]", cowboy_static, {priv_dir, twitter, "static"}}
		]}
	]),
	{ok, _} = cowboy:start_clear(http, [{port, 8080}], #{
		env => #{dispatch => Dispatch}
	}),
	twitter_sup:start_link().

stop(_State) ->
    ok.

%% internal functions
