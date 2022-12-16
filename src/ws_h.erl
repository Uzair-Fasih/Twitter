-module(ws_h).

-export([init/2]).
-export([websocket_init/1]).
-export([websocket_handle/2]).
-export([websocket_info/2]).
-export([terminate/3]).

init(Req, Opts) ->
	{cowboy_websocket, Req, Opts, #{idle_timeout => infinity}}. % Set the idle_timeout to infinity so the server doesn't one-sidedly disconnect

websocket_init(State) ->
	{[], State}.

websocket_handle({text, Msg}, State) ->
	[TwitterEngine | _] = State,
	Request = jsone:decode(Msg),
	Action = maps:get(<<"action">>, Request),
	
	case Action of
		<<"login">> -> 
			Username = binary_to_list(maps:get(<<"username">>, Request)),
			Password = binary_to_list(maps:get(<<"password">>, Request)),
			TwitterEngine ! {login, Username, Password, self()},
			{[], State ++ [Username]};

		<<"tweet">> ->
			[_, Username] = State,
			TwitterEngine ! {tweet, Username, binary_to_list(maps:get(<<"tweet">>, Request))},
			{[], State};

		<<"follow">> ->
			[_, Username] = State,
			TwitterEngine ! {follow, Username, binary_to_list(maps:get(<<"follow">>, Request)), self()},
			{[], State};

		<<"retweet">> ->
			[_, Username] = State,
			TwitterEngine ! {
				retweet, 
				Username, 
				binary_to_list(maps:get(<<"author">>, Request)), 
				binary_to_list(maps:get(<<"tweet">>, Request))
			},
			{[], State};

		<<"search">> ->
			TwitterEngine ! { search, binary_to_list(maps:get(<<"query">>, Request)), self() },
			{[], State}
	end;
websocket_handle(_Data, State) ->
	{[], State}.

% Handle client side error states 
websocket_info({timeout, _Ref, Msg}, State) ->
	{[{text, Msg}], State};
websocket_info(Info, State) ->
	case Info of
		{terminate, Err} ->
			lager:info("Terminating Websocket on Process: ~p, Reason: ~s", [self(), Err]),
			{stop, State};
		_ ->
			{[], State}
	end.

% Keep track of users logging out
terminate(_Reason, _PartialReq, State) -> 
	[_, Username] = State,
	lager:info("User '~s' has logged out.", [Username]),
	ok.