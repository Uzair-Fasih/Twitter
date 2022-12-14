let websocket;
let username;
let homefeed = "";

const avatars = {
  Gojo: "1",
  Nino: "2",
  Obama: "3",
};

function onLoad() {
  username = prompt("username");
  const avatarEl = document.querySelector(".center > .user-input >.avatar");
  avatarEl.setAttribute("src", `./static/avatar${avatars[username]}.jpg`);
  avatarEl.setAttribute("style", null);
  connect(username);
}

function follow(follow) {
  websocket.send(JSON.stringify({ action: "follow", follow }));
}

function retweet(tweetAuthor, tweet) {
  websocket.send(JSON.stringify({ action: "retweet", tweetAuthor, tweet }));
}

function tweet() {
  const tweetMsg = document.getElementById("tweetData");
  websocket.send(JSON.stringify({ action: "tweet", tweet: tweetMsg.value }));
  tweetMsg.value = "";
}

function tweet_key(event) {
  event = event || window.event;
  if (event.keyCode == 13) {
    tweet();
  }
}

function connect(username) {
  wsHost = "ws://" + window.location.host + "/websocket";
  websocket = new WebSocket(wsHost);
  websocket.onopen = function (evt) {
    websocket.send(JSON.stringify({ action: "login", username }));
  };
  websocket.onclose = function (evt) {
    // onClose(evt);
  };
  websocket.onmessage = function (evt) {
    const decoded = JSON.parse(evt.data);
    if ("results" in decoded) {
      const feed = document.getElementById("feed");
      console.log(decoded);
      homefeed = feed.innerHTML;
      feed.innerHTML = "";
      decoded.results.forEach(({ author, tweet }) => {
        addTweetToFeed(author, author, tweet);
      });
    }

    if ("author" in decoded) {
      const feed = document.getElementById("feed");
      feed.innerHTML = homefeed;
      addTweetToFeed(decoded.author, decoded.author, decoded.tweet);
      homefeed = feed.innerHTML;
    }
  };
  websocket.onerror = function (evt) {
    // onError(evt);
  };
}

function goToHome() {
  const feed = document.getElementById("feed");
  feed.innerHTML = homefeed;
}

function search(event) {
  event = event || window.event;
  if (event.keyCode == 13) {
    websocket.send(
      JSON.stringify({ action: "search", query: event.target.value })
    );
    event.target.value = "";
  }
}

function addTweetToFeed(author, username, tweet) {
  const feed = document.getElementById("feed");
  feed.innerHTML =
    `
  <div class="user-card">
      <img class="avatar" src="./static/avatar${avatars[username]}.jpg" />
      <div class="content">
        <div class="user-info">
          <span>${author}</span> <span>@${username}</span>
        </div>
        <div class="tweet">
          ${tweet}
        </div>
        <div class="actions">
          <div class="action" onclick="retweet('${author}', '${tweet}')">
            <img src="./static/retweet.svg" />
            <span>Retweet</span>
          </div>
          <div class="action" onclick="follow('${author}')">
            <img src="./static/follow.svg" /><span>Follow</span>
          </div>
        </div>
      </div>
    </div>
  ` + feed.innerHTML;
}
