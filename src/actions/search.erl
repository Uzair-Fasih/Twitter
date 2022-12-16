-module(search).
-define(IF(Cond,E1,E2), (case (Cond) of true -> (E1); false -> (E2) end)).
-export([query/3]).

match_tweets(_Tweets, 0, MatchedTweets, _WhatToSearch) ->
    MatchedTweets;
match_tweets(TweetsList, LengthTweetsList, MatchedTweets, SearchItem) ->
    {ProxyUser, Author, Tweet} = lists:nth(LengthTweetsList, TweetsList),
    
    IsMatch = string:find(Tweet, SearchItem),
    
    if
      (IsMatch == nomatch) -> 
        match_tweets(TweetsList, LengthTweetsList - 1, MatchedTweets, SearchItem); 
      true -> 
        ModifiedMatchedTweets = MatchedTweets ++ [#{
          success => erlang:list_to_binary("true"),
          proxy => erlang:list_to_binary(ProxyUser),
          kind => erlang:list_to_binary([?IF(ProxyUser == Author, "tweet", "retweet")]),
          author => erlang:list_to_binary(Author), 
          tweet => erlang:list_to_binary(Tweet)
        }],
        match_tweets(TweetsList, LengthTweetsList - 1, ModifiedMatchedTweets, SearchItem)
    end.


query_each(_Keys, 0, _TweetDB, MatchedTweets, _SearchItem) ->
    MatchedTweets;
query_each(Keys, KeyLen, TweetDB, MatchedTweets, SearchItem) ->
    Key = lists:nth(KeyLen, Keys),
    UserRecord = maps:get(Key, TweetDB),
    Tweets = maps:get(feed, UserRecord),
    TwtLen = length(Tweets),
    MatchedTweets1 = match_tweets(Tweets, TwtLen, MatchedTweets, SearchItem),
    query_each(Keys, KeyLen - 1, TweetDB, MatchedTweets1, SearchItem).

query(State, Query, Websocket) ->
    {_ConnectionMapping, Datastore} = State,
    Keys = maps:keys(Datastore),
    MatchedTweets = query_each(Keys, length(Keys), Datastore, [], Query),
    TweetSet = sets:from_list(MatchedTweets), % Remove duplicates from the mathching logic
    erlang:start_timer(0, Websocket, jsone:encode(#{
      results => sets:to_list(TweetSet),
      success => erlang:list_to_binary("true"),
      kind => erlang:list_to_binary("search")
    })).
