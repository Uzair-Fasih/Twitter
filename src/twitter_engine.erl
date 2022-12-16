-module(twitter_engine).

-export([start/1]).

start(State) ->
  receive
    {login, Username, Password, Websocket} ->
      lager:info("User '~s' has logged in.", [Username]),
      MutatedState = login:upsert_user(State, Username, Password, Websocket),
      start(MutatedState);

    {tweet, User, Tweet} ->
      lager:info("A tweet has been made by user '~s' and it is as follows: '~s'", [User, Tweet]),
      MutatedState = tweet:message(State, User, {User, Tweet}),
      start(MutatedState);

    {follow, User, FollowUser, Websocket} ->
      lager:info("User '~s' has decided to follow user '~s'", [User, FollowUser]),
      MutatedState = follow:subscribe(State, User, FollowUser, Websocket),
      start(MutatedState);
    
    {retweet, User, TweetAuthor, Tweet} ->
      lager:info("~s has decided to retweet tweet by author: ~s, which is: ~p", [User, TweetAuthor, Tweet]),
      MutatedState = tweet:message(State, User, {TweetAuthor, Tweet}),
      start(MutatedState);

    {search, Query, Websocket} ->
      search:query(State, Query, Websocket),
      start(State)

  end.
