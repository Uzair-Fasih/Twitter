# Twitter Clone with Webocket Interface

## Authors
| Name | UFID |
| ----------- | ----------- |
| Mohammed Uzair Fasih | 6286 1020 |
| Sohaib Uddin Syed | 5740 5488 |

## Overview
The goal of the project is to implement a WebSocket interface for the simulation of the Twitter engine.

## What is Working?

The simulation correctly sets up the required number of nodes and calcualates the average time for various operations.

## Running the application
1) Install erlang from https://www.erlang.org/ and clone this repository.

2) Install erlang tools.

3) Run the project.

Run the project
```bash
> erl -make
```

4) To start the twitter engine, run the following:

```bash
> erl -sname server -pa ebin
> twitterEngine:startEngine().
```

5) To start the simulator, run the following in a different terminal:

```bash
> erl -sname simulator -pa ebin
> users:startUsers('server@USERNAME', [no_of_actors], [no_of_requests]).
```
- ```[no_of_actors]``` is number of actors/users to be simulated on the server.
- ```[no_of_requests]``` is number of requests to be made by each actor.


    $ rebar3 compile
