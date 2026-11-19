You are a senior Flutter developer and UI/UX designer.

Build a complete, production-ready Flutter UI for a badminton scoring and tournament app named **"Shuttle Smashers"**.

⚠️ Requirements:

* Use Flutter (latest stable version)
* Use clean architecture and modular structure
* Use Material 3 design
* Use responsive layouts (mobile-first)
* Use reusable widgets
* No backend integration needed (UI only with dummy data)

---

🎨 THEME:

* Primary color: Deep Blue (#1E3A8A)
* Accent color: Neon Green (#22C55E)
* Background: Dark gradient (sports style)
* UI style: Modern, sporty, premium (like CricHeroes + Dream11 style)

---

📱 SCREENS TO BUILD:

1️⃣ Splash Screen

* App logo (Shuttle Smashers)
* Animated loading indicator

---

2️⃣ Login Screen

* Mobile number input
* OTP input UI
* Google login button
* Clean modern UI

---

3️⃣ Home Screen

* Top greeting (Hello Player 👋)
* Live Matches section (horizontal cards)
* Upcoming Matches section
* Floating button: "Create Match"
* Bottom navigation bar:

    * Home
    * Tournaments
    * Leaderboard
    * Profile

---

4️⃣ Create Match Screen

* Select match type:

    * Singles
    * Doubles
    * Mixed Doubles
* Player selection UI (cards with avatars)
* Start Match button

---

5️⃣ Live Score Screen (MOST IMPORTANT)

* Scoreboard UI:
  Team A vs Team B
* Big score display:
  18 - 17
* Buttons:
  +1 Team A
  +1 Team B
  Undo
  End Match
* Show set history
* Highlight current server
* Smooth animations

---

6️⃣ Tournament Screen

* List of tournaments
* Create tournament button
* Tournament card:
  name, type, players count

---

7️⃣ Tournament Details Screen

* Bracket view (simple UI)
* Match list
* Winner highlight

---

8️⃣ Leaderboard Screen

* Player ranking list
* Stats:
  matches, wins, points

---

9️⃣ Player Profile Screen

* Profile avatar
* Name
* Stats (wins, matches)
* Match history list

---

🔧 COMPONENTS TO CREATE:

* Custom AppBar
* Match Card widget
* Player Card widget
* Score Button widget
* Leaderboard Tile
* Tournament Card

---

✨ UI DETAILS:

* Use rounded corners (16-20 radius)
* Use subtle shadows
* Use gradients for premium look
* Smooth transitions & animations
* Use icons (Material Icons)

---

📂 PROJECT STRUCTURE:

lib/
├── main.dart
├── core/
│    ├── theme/
│    ├── constants/
├── features/
│    ├── auth/
│    ├── home/
│    ├── match/
│    ├── tournament/
│    ├── leaderboard/
│    ├── profile/
├── widgets/

---

🧠 IMPORTANT:

* Use dummy JSON data for UI
* No backend code
* Code must be clean and readable
* Add comments for each screen

---

🎯 OUTPUT:

* Full Flutter code for all screens
* Proper navigation between screens
* Reusable widgets
* Ready to run project

---

Make the UI look like a modern sports app used by real players.
