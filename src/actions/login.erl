-module(login).
-export([upsert_user/4]).

% Create and register new user or if user already exists, authenticate user
upsert_user(State, Username, Password, Websocket) ->
  {ConnectionMapping, Datastore} = State,
  Found = erlang:is_map_key(Username, Datastore),
  case Found of
    true ->
      % If user is found, then checked against the stored password 
      UserRecord = maps:get(Username, Datastore),
      SavedPassword = maps:get(password, UserRecord),

      IsValid = SavedPassword =:= Password,
      case IsValid of
        true -> 
          erlang:start_timer(0, Websocket, jsone:encode(#{success => erlang:list_to_binary("true"), kind => erlang:list_to_binary("login")})),
          { maps:put(Username, Websocket, ConnectionMapping), Datastore };
        false ->
          lager:info("User '~s' is not authenticated: Password not valid", [Username]),
          Websocket ! {terminate,  "Bad Password"},
          State
      end;

    false -> 
      erlang:start_timer(0, Websocket, jsone:encode(#{success => erlang:list_to_binary("true"), kind => erlang:list_to_binary("login")})),
      {
        maps:put(Username, Websocket, ConnectionMapping), 
        maps:put(Username, #{password => Password, followers => [], feed => []}, Datastore)
      }
  end.