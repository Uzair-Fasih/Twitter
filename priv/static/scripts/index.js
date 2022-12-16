// Websockets
let websocket;
let globalUsername;
const avatarMap = {
  percival: "1",
  raiden: "2",
};

const loginAction = (username, password, setState) => {
  const wsHost = `ws://${window.location.host}/websocket`;
  websocket = new WebSocket(wsHost);

  globalUsername = username;

  websocket.onopen = function (evt) {
    websocket.send(JSON.stringify({ action: "login", username, password }));
  };

  websocket.onmessage = function (evt) {
    const response = JSON.parse(evt.data);

    if (response.success == "true" && response.kind == "login") {
      setState((state) => ({ ...state, isAuthenticated: true }));
    }

    if (
      response.success == "true" &&
      (response.kind == "tweet" || response.kind == "retweet")
    ) {
      setState((state) => ({
        ...state,
        homefeed: [response, ...state.homefeed],
      }));
    }

    if (response.success == "true" && response.kind == "search") {
      setState((state) => ({
        ...state,
        search: response.results,
      }));
    }
  };

  websocket.onerror = function (evt) {
    // onError(evt);
  };

  websocket.onclose = function (evt) {
    setState((state) => ({ homefeed: [], search: [], isAuthenticated: false }));
  };
};

// Components
const Button = ({ label, onClick = () => {}, style = {} }) => {
  return (
    <button style={style} className="twitter-button" onClick={onClick}>
      {label}
    </button>
  );
};

const Panel = ({ children }) => {
  return <div className="panel">{children}</div>;
};

const Header = ({ setScreenIdx }) => {
  const [tweetData, setTweetData] = React.useState("");
  const [searchData, setSearch] = React.useState("");

  function sendTweet() {
    websocket.send(JSON.stringify({ action: "tweet", tweet: tweetData }));
    setTweetData("");
  }
  function sendSearch() {
    websocket.send(JSON.stringify({ action: "search", query: searchData }));
    setSearch("");
    setScreenIdx(1);
  }

  function onKeyDown(event) {
    if (event.keyCode == 13) {
      tweet();
    }
  }

  function onKeyDownSearch(event) {
    if (event.keyCode == 13) {
      sendSearch();
    }
  }

  function onChange(event) {
    setTweetData(event.target.value);
  }
  function onChangeSearch(event) {
    setSearch(event.target.value);
  }

  return (
    <div className="header">
      <input
        value={searchData}
        onKeyDown={onKeyDownSearch}
        onChange={onChangeSearch}
        placeholder="Search Twitter"
      />
      <div className="tweeter">
        <img
          src={`/static/media/avatar${avatarMap[globalUsername]}.jpg`}
          alt="avatar"
        />
        <div className="tweeter-action">
          <textarea
            value={tweetData}
            onKeyDown={onKeyDown}
            onChange={onChange}
            placeholder="Tweet Something"
          />
          <Button
            onClick={sendTweet}
            label="Tweet"
            style={{ width: "max-content", marginTop: ".5rem" }}
          />
        </div>
      </div>
    </div>
  );
};

const Tweet = ({ author, tweet, proxy = "mom", kind = "tweet" }) => {
  function follow() {
    websocket.send(JSON.stringify({ action: "follow", follow: author }));
  }

  function retweet() {
    websocket.send(JSON.stringify({ action: "retweet", author, tweet }));
  }

  return (
    <div class="tweet-container">
      {kind == "retweet" && <p className="retweet"> {proxy} retweeted </p>}
      <div class="tweet">
        <img src={`/static/media/avatar${avatarMap[author]}.jpg`} />
        <div class="content">
          <div class="user-info">
            <span>{author}</span>
            <span>@{author}</span>
          </div>
          <div class="tweet-message">{tweet}</div>
          <div class="actions">
            <div class="action" onClick={retweet}>
              <img src="./static/assets/retweet.svg" />
              <p>Retweet</p>
            </div>
            <div class="action" onClick={follow}>
              <img src="./static/assets/follow.svg" />
              <p>Follow</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

// Pages
const LoginPage = ({ setState }) => {
  const [username, setUsername] = React.useState("");
  const [password, setPassword] = React.useState("");

  const updateUsername = (event) => setUsername(event.target.value);
  const updatePassword = (event) => setPassword(event.target.value);

  return (
    <div className="login-page-container">
      <div className="login-page-content">
        <img src="./static/assets/twitter.svg" alt="twitter logo" />
        <h1>Sign in to Twitter</h1>
        <input
          value={username}
          onChange={updateUsername}
          placeholder="Enter your username"
        />
        <input
          placeholder="Enter your password"
          value={password}
          onChange={updatePassword}
          type="password"
        />
        <Button
          style={{ marginTop: "1rem", width: "60%" }}
          label="login"
          onClick={() => loginAction(username, password, setState)}
        />
      </div>
    </div>
  );
};

const FeedPage = ({ state }) => {
  const tweets = state.homefeed || [];
  return (
    <div className="home-feed">
      <h2># Home</h2>
      <div>
        {tweets.map((tweet, idx) => (
          <Tweet key={`${tweet.author}-${idx}-${tweet.proxy}`} {...tweet} />
        ))}
      </div>
    </div>
  );
};

const SearchPage = ({ state }) => {
  const tweets = state.search || [];
  return (
    <div className="search-feed">
      <h2># Search</h2>
      <div>
        {tweets.map((tweet, idx) => (
          <Tweet key={`${tweet.author}-${idx}-${tweet.proxy}`} {...tweet} />
        ))}
      </div>
    </div>
  );
};

const ProtectedPage = ({ state }) => {
  const screens = [FeedPage, SearchPage];
  const [screenIdx, setScreenIdx] = React.useState(0);

  const Page = screens[screenIdx];
  return (
    <div className="protected-page">
      <Panel>
        <div className="mini-header">
          <img
            onClick={() => setScreenIdx(0)}
            src="./static/assets/twitter.svg"
            alt="twitter logo"
          />
        </div>
      </Panel>
      <div className="protected-page-content">
        <Header setScreenIdx={setScreenIdx} />
        <Page state={state} />
      </div>
      <Panel />
    </div>
  );
};

const ReactAppFromCDN = () => {
  const [state, setState] = React.useState({
    isAuthenticated: false,
    homefeed: [],
    search: [],
  });
  if (!state.isAuthenticated) return <LoginPage setState={setState} />;
  return <ProtectedPage state={state} />;
};

ReactDOM.render(<ReactAppFromCDN />, document.querySelector("#root"));
