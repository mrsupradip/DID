# DevZone Fix Plan (BlackboxAI)

## Step 0 — Repo audit / confirm issues

- [ ] Search and locate exact friend-request + “App isn’t responding” code path.
- [ ] Locate root cause of the red error screen (`_dependencies.isEmpty`) and navigation lifecycle misuse.
- [ ] Identify current Firestore schema fields for teams/memberships/chat/notifications/friend requests/posts/comments/stories/quiz posts.
- [ ] Identify why OAuth buttons on signup page do nothing.

## Step 1 — Google + GitHub signup/auth

- [ ] Implement Google OAuth sign-in using FirebaseAuth.
- [ ] Implement GitHub OAuth sign-in using FirebaseAuth OAuth provider.
- [ ] After OAuth: ensure profile document exists (no duplicates).
- [ ] Add loading indicators and robust error handling.

## Step 2 — Account deletion cascading cleanup

- [ ] Replace `_deleteAccount()` with a complete cascade delete:
  - [ ] Delete user profile doc.
  - [ ] Delete user-owned posts, comments, stories, quiz posts.
  - [ ] Delete owned teams + team rooms/messages.
  - [ ] Remove user from memberIds/members in teams; avoid orphan teams.
  - [ ] Delete saved posts.
  - [ ] Delete chat messages / conversations tied to user.
  - [ ] Delete notifications.
  - [ ] Delete friend requests.
  - [ ] Delete any additional user-related Firestore documents discovered in audit.
- [ ] Delete Firebase Auth user after Firestore cleanup.

## Step 3 — Add Friend freeze fix

- [ ] Remove infinite loading.
- [ ] Add mounted checks before setState/dialog mutations.
- [ ] Ensure Firestore queries/writes use correct fields and timeouts.
- [ ] Close dialogs properly.

## Step 4 — Remove red error screen

- [ ] Remove Navigator calls from build methods.
- [ ] Prevent navigation triggered inside FutureBuilder/StreamBuilder builders.
- [ ] Prevent duplicate navigations (guard flags, post-frame callbacks).
- [ ] Add mounted checks and correct pushReplacement usage.

## Step 5 — Home feed + Find Team layout gaps

- [ ] Fix bottom spacing in Home feed.
- [ ] Fix bottom empty space in Find Team page.
- [ ] Ensure SafeArea/MediaQuery padding correct and no scroll padding.

## Step 6 — My Room logic + UI improvements

- [ ] Ensure Joined Teams query uses `memberIds arrayContains currentUserId`.
- [ ] Confirm joining writes update memberIds so joined team appears immediately.
- [ ] Improve UI: spacing, loading/empty states, modern cards, member count, team code, last activity.

## Step 7 — Firestore data consistency

- [ ] Audit all team writes (join/create/update/delete) for schema consistency.

## Step 8 — Final stability pass

- [ ] Global scan for setState after dispose, navigation loops, stream issues, dialog leaks.
- [ ] Run `flutter analyze` and tests.
