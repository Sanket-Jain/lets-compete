<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>${pageTitle} — Carrom Manager</title>
  <link rel="preconnect" href="https://fonts.googleapis.com"/>
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/>
  <link rel="stylesheet" href="/static/css/app.css"/>
</head>
<body>

<nav>
  <a class="nav-brand" href="/"><span>CARROM</span> MGR</a>
  <a class="nav-link" href="/">Home</a>
  <a class="nav-link" href="/players">Players</a>
  <a class="nav-link" href="/teams">Teams</a>
  <a class="nav-link" href="/tournaments">Tournaments</a>
  <a class="nav-link" href="/fixtures">Fixtures</a>
  <div class="nav-spacer"></div>
</nav>

<!-- Global toast -->
<div id="toast"></div>

<!-- Global confirm dialog -->
<div class="confirm-overlay" id="confirmOverlay">
  <div class="confirm-box">
    <h3 id="confirmTitle">Confirm</h3>
    <p id="confirmMsg"></p>
    <div class="confirm-actions">
      <button class="btn btn-outline" id="confirmCancel">Cancel</button>
      <button class="btn btn-danger" id="confirmOk">Confirm</button>
    </div>
  </div>
</div>
