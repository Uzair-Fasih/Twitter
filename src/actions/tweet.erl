-module(tweet).
-define(IF(Cond,E1,E2), (case (Cond) of true -> (E1); false -> (E2) end)).
-export([message/3]).

message_each(State, [], _Rest) -> State;
message_each(State, Followers, {ProxyUser, Author, Tweet}) ->
  {ConnectionMapping, Datastore} = State,

  [Username | Remaining] = Followers,
  UserRecord = maps:get(Username, Datastore),
  UsernameFeed = maps:get(feed, UserRecord),
  
  MutatedUserRecord = maps:put(feed, UsernameFeed ++ [{ProxyUser, Author, Tweet}], UserRecord),
  MutatedDatastore = maps:put(Username, MutatedUserRecord, Datastore),

  Websocket = maps:get(Username, ConnectionMapping),
  erlang:start_timer(0, Websocket, jsone:encode(#{
    success => erlang:list_to_binary("true"),
    proxy => erlang:list_to_binary(ProxyUser),
    kind => erlang:list_to_binary([?IF(ProxyUser == Author, "tweet", "retweet")]),
    author => erlang:list_to_binary(Author), 
    tweet => erlang:list_to_binary(Tweet)})
  ),

  message_each({ConnectionMapping, MutatedDatastore}, Remaining, {ProxyUser, Author, Tweet}).


message(State, Username, {Author, Tweet}) ->
  {_ConnectionMapping, Datastore} = State,

  % Get all followers of the user
  UserRecord = maps:get(Username, Datastore),
  Followers = maps:get(followers, UserRecord) ++ [Username], % Also add current user so they their own tweet in feed as well
  
  message_each(State, Followers, {Username, Author, Tweet}).


