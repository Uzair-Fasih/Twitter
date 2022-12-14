-module(twitter_core).
-compile(export_all).

upsert_user(State, User, CID) ->
  {Mapping, DB} = State,
  Find = erlang:is_map_key(User, DB),
  case Find of
    true -> {maps:put(User, CID, Mapping), DB};
    false ->
      {maps:put(User, CID, Mapping), maps:put(User, #{followers => [], feed => []}, DB)}
  end.


tweet_each([], _Author, _Tweet, _Mapping, DB) -> DB;
tweet_each(Followers, Author, Tweet, Mapping, DB) ->
  [Username | Remaining] = Followers,
  UsernameRecord = maps:get(Username, DB),
  UsernameFeed = maps:get(feed, UsernameRecord),
  
  MutatedUsernameRecord = maps:put(feed, UsernameFeed ++ [{Author, Tweet}], UsernameRecord),
  MutatedDB = maps:put(Username, MutatedUsernameRecord, DB),

  UserPID = maps:get(Username, Mapping),
  erlang:start_timer(0, UserPID, jsone:encode(#{author => erlang:list_to_binary(Author), tweet => erlang:list_to_binary(Tweet)})),
  tweet_each(Remaining, Author, Tweet, Mapping, MutatedDB).


tweet(State, User, Author, Tweet) ->
  {Mapping, DB} = State,
  UserRecord = maps:get(User, DB),
  Followers = maps:get(followers, UserRecord) ++ [User],
  {Mapping, tweet_each(Followers, Author, Tweet, Mapping, DB)}.


follow(State, User, FollowUser) ->
  {Mapping, DB} = State,
  
  FollowUserRecord = maps:get(FollowUser, DB),
  Followers = maps:get(followers, FollowUserRecord) ++ [User],
  
  UpdatedFollowUserRecord = maps:put(followers, Followers, FollowUserRecord),
  MutatedDB = maps:put(FollowUser, UpdatedFollowUserRecord, DB),

  {Mapping, MutatedDB}.
