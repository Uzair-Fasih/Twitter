-module(twitter_engine).

-export([start/1]).

ltb(In) ->
  erlang:list_to_binary(In).

start(State) ->
  {MappingBitch, DBBitch} = State,
  lager:info("Here's the map: ~p | ~p", [MappingBitch, DBBitch]),
  receive
    {login, User, CID} ->
      lager:info("A User has logged in"),
      MutatedState = twitter_core:upsert_user(State, User, CID),
      start(MutatedState);

    {tweet, User, Tweet} ->
      lager:info("A tweet has been made by ~s and its: ~s", [User, Tweet]),
      MutatedState = twitter_core:tweet(State, User, User, Tweet),
      start(MutatedState);

    {follow, User, FollowUser} ->
      lager:info("~s has decided to follow ~s", [User, FollowUser]),
      MutatedState = twitter_core:follow(State, User, FollowUser),
      start(MutatedState);
    
    {retweet, User, TweetAuthor, Tweet} ->
      lager:info("~s has decided to retweet tweet by author: ~s, which is: ~p", [User, TweetAuthor, Tweet]),
      MutatedState = twitter_core:tweet(State, User, TweetAuthor, Tweet),
      start(MutatedState)

  end.
