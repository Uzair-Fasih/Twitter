-module(follow).
-export([subscribe/4]).

subscribe(State, Follower, Username, Websocket) ->
  {ConnectionMapping, Datastore} = State,

  if Follower =:= Username ->
    erlang:start_timer(0, Websocket, jsone:encode(#{
      success => erlang:list_to_binary("false"),
      message => erlang:list_to_binary("Cannot follow self.")
    })),
    State;

  true ->
    Found = erlang:is_map_key(Username, Datastore),

    case Found of
      false ->
        erlang:start_timer(0, Websocket, jsone:encode(#{
        success => erlang:list_to_binary("false"),
        message => erlang:list_to_binary("User not found.")
      })),
      State;

      true ->
        UserRecord = maps:get(Username, Datastore),
        Followers = maps:get(followers, UserRecord) ++ [Follower],
        
        UpdatedRecord = maps:put(followers, Followers, UserRecord),
        MutatedDatastore = maps:put(Username, UpdatedRecord, Datastore),
        {ConnectionMapping, MutatedDatastore}
    end
  end.
    

  


  