# PunchIt: Restaurant Order Punching App

MAD (Mobile Application Development) group project.
Server ID + PIN se login, Dine-in / Takeaway, menu se items punch, toppings + comment, Hall / Table / Server select, aur kitchen stations pe dockets.
**Manager / Owner Panel** se restaurant khud apna menu, prices, toppings, tax (Cash / Card alag), stations, tables aur staff set karta hai. Kuch bhi code mein hard-coded nahi.

- **Frontend:** Flutter (Dart), Android Studio
- **Backend:** Node.js + Express (Phase 2)
- **Database:** MySQL (`database/schema.sql`)

---

## Is starter mein kya hai

```
punchit/
├── README.md            <- yeh guide
├── .gitignore
├── app/
│   ├── lib/             <- Flutter code (apne Flutter project mein copy karna hai)
│   ├── test/            <- widget_test.dart (purani wali replace karni hai)
│   └── pubspec_dependencies.txt
├── database/
│   └── schema.sql       <- poora MySQL schema + sample data
└── backend/
    └── README.md        <- Phase 2
```

**Flutter screens jo ready hain (dummy data pe chalti hain):**

| File | Kaam |
|---|---|
| `screens/login_screen.dart` | Server ID + 4-digit PIN pad |
| `screens/order_type_screen.dart` | Dine-in / Takeaway |
| `screens/menu_screen.dart` | Category tabs, search, items grid, cart button |
| `widgets/item_options_sheet.dart` | Crust (required), Extra Toppings (max 5), qty, comment + quick notes |
| `widgets/table_select_sheet.dart` | Hall -> Table (free/occupied/bill colors) -> Server. Takeaway pe customer name/phone |
| `screens/order_summary_screen.dart` | Items edit, qty +/-, swipe to delete, Cash vs Card bill estimate, Send to Kitchen |
| `screens/admin/admin_home_screen.dart` | Manager Panel: Take Order + setup tiles |
| `screens/admin/categories_screen.dart` | Category add/edit/delete, station (printer) link, menu order |
| `screens/admin/products_screen.dart` | Products list, category filter, search, **available ON/OFF switch** (item khatam) |
| `screens/admin/product_form_screen.dart` | Naam, price, category, station override, toppings groups |
| `screens/admin/modifier_groups_screen.dart` | Topping groups (Crust, Extra Toppings), ek/multiple select, required, options + extra price, drag to reorder |
| `screens/admin/tax_settings_screen.dart` | Payment methods ka tax %, service charge, restaurant naam, bill footer, live example |
| `screens/admin/stations_screen.dart` | Kitchen stations, Item vs Cut Table, printer IP/port |
| `screens/admin/floor_screen.dart` | Halls aur tables (number, seats) |
| `screens/admin/staff_screen.dart` | Staff add/edit, role, PIN reset, active/inactive |
| `core/bill_calculator.dart` | Tax / service charge ka formula (ek hi jagah) |
| `widgets/admin_widgets.dart` | Panel ke common dialogs, validators |
| `data/pos_repository.dart` | Interface: screens sirf isse data lete hain |
| `data/mock_pos_repository.dart` | Dummy data (wohi jo `schema.sql` mein hai) |
| `providers/order_provider.dart` | Current order ki state (cart, table, server) |
| `models/models.dart` | Saare models + `fromJson` (backend ke liye ready) |

**Demo login (PIN sab ka `1234`):**

| ID | Kaun | Kahan jata hai |
|---|---|---|
| `S101`, `S102`, `S103` | Servers | Seedha Dine-in / Takeaway |
| `K101` | Kitchen | (Kitchen screen abhi baqi hai) |
| `M201` | Manager (Zain) | Manager Panel |
| `O301` | Owner | Manager Panel |

**Server flow:** Login -> Dine-in -> pehla item (toppings + comment) -> Hall/Table/Server sheet -> aur items add -> View Order (Cash/Card total dikhega) -> Send to Kitchen. Table occupied ho jati hai.

**Owner flow (demo mein yeh zaroor dikhana):**
1. `O301` se login -> **Products** -> "Fries" ka switch OFF -> logout
2. `S101` se login -> Menu mein Fries "Not available" dikhega
3. Owner -> **Tax & Settings** -> Card tax badlo -> Order Summary mein naya total
4. Owner -> **Products** -> naya product + price + toppings group -> server ke menu mein foran aa jata hai

**Rules jo app khud enforce karti hai (viva points):**
- Category mein products hain to delete nahi hogi
- Hall mein tables hain to delete nahi hoga; occupied table delete nahi hogi
- Staff delete nahi hota, sirf **inactive** (purane orders mein naam chahiye). Inactive login nahi kar sakta
- Kam az kam 1 active Manager/Owner aur 1 active payment method hamesha rehna chahiye
- Station delete ho to us ki categories "sirf Cut Table" pe chali jati hain (DB mein `ON DELETE SET NULL`)
- Tax rate bill pe **snapshot** hota hai (`orders.tax_percent`), baad mein rate badle to purane bills same rahein

> Mock data memory mein hai: app restart karne pe changes reset ho jate hain. Backend lagne ke baad MySQL mein save honge.

---

## Step 0: Dono ke laptops pe install (ek baar)

1. **Git:** https://git-scm.com/downloads (install ke baad terminal mein):
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your-github-email@example.com"
   ```
2. **Flutter SDK (3.35 ya naya):** https://docs.flutter.dev/get-started/install (Windows: zip extract karo, e.g. `C:\src\flutter`, aur `C:\src\flutter\bin` ko PATH mein daalo)
3. **Android Studio:** install karo, phir **Settings -> Plugins -> Flutter** install karo (Dart khud aa jata hai)
4. Android Studio mein **SDK Manager -> SDK Tools -> Android SDK Command-line Tools** tick karo
5. Terminal mein:
   ```bash
   flutter doctor
   flutter doctor --android-licenses
   ```
   `flutter doctor` mein Flutter, Android toolchain, Android Studio teeno pe tick aana chahiye.
6. Dono ka **GitHub account** hona chahiye.

---

## Step 1: GitHub repo banao (sirf Person A)

1. github.com -> **New repository**
2. Name: `punchit`, Private ya Public (jo teacher kahe)
3. **"Add a README file" tick karo** (taake repo khali na ho), `.gitignore` aur license **None**
4. Create repository
5. Repo -> **Settings -> Collaborators -> Add people** -> Person B ka GitHub username. Person B email se invite **accept** kare.

---

## Step 2: Repo clone karo (Person A)

Android Studio: **File -> New -> Project from Version Control**
- URL: `https://github.com/<your-username>/punchit.git`
- Directory: e.g. `D:\Projects\punchit`
- Clone (pehli baar GitHub login maangega, browser se allow kar do)

Ya terminal se:
```bash
cd D:\Projects
git clone https://github.com/<your-username>/punchit.git
```

---

## Step 3: Repo ke andar Flutter project banao (Person A)

Android Studio ka **Terminal** tab kholo (neeche), aur `punchit` folder ke andar:

```bash
flutter create --org com.punchit --project-name punchit_app --platforms android app
```

Isse `punchit/app/` mein Flutter project ban jayega.

---

## Step 4: Starter code copy karo (Person A)

1. Is zip ki cheezein repo mein daalo:
   - zip ka `.gitignore`, `database/`, `backend/` -> `punchit/` (root) mein
   - `punchit/app/lib/` folder **poora delete** karo, phir zip ka `app/lib/` wahan paste karo
   - zip ka `app/test/widget_test.dart` -> `punchit/app/test/` mein replace karo (purani test file `MyApp` dhoondti hai jo ab nahi hai, error degi)
   - zip ka `README.md` repo wali README ko replace kar de (optional)
2. Provider package add karo:
   ```bash
   cd app
   flutter pub add provider
   ```
3. Android Studio mein **File -> Open -> `punchit/app`** (Flutter project yahi hai)
4. Emulator start karo (**Device Manager -> Create Device**, e.g. Pixel 7, API 34) ya phone USB se lagao (Developer options -> USB debugging on)
5. Upar green **Run** button, ya:
   ```bash
   flutter run
   ```

---

## Step 5: Pehla commit + push (Person A)

```bash
cd D:\Projects\punchit
git add .
git commit -m "Flutter starter: login, order type, menu, toppings, table select, summary"
git push origin main
```

Android Studio se bhi ho sakta hai: **Ctrl+K** (Commit) -> message -> **Commit and Push**.

GitHub pe refresh karo, `app/`, `database/`, `backend/` dikhne chahiye.

---

## Step 6: Person B setup

```bash
git clone https://github.com/<person-a-username>/punchit.git
cd punchit/app
flutter pub get
flutter run
```
Android Studio mein `punchit/app` open karo.

---

## Roz ka kaam (dono follow karein)

**Rule:** `main` pe seedha kaam nahi. Har feature ki alag branch, phir Pull Request.

```bash
# 1. Kaam shuru karne se pehle latest code lo
git checkout main
git pull

# 2. Apni branch banao
git checkout -b feature/bill-screen

# 3. Kaam karo, beech beech mein commit
git add .
git commit -m "Bill screen UI with tax and discount"

# 4. Push
git push -u origin feature/bill-screen
```

5. GitHub pe **Compare & pull request** -> doosra banda dekh ke **Merge** kare
6. Merge ke baad dono: `git checkout main` aur `git pull`

**Conflict se bachne ke liye:**
- Ek waqt mein dono ek hi file edit na karein. Pehle bata do kaun kis file pe hai.
- Roz kaam shuru karne se pehle `git pull`
- Chhote chhote commits, bade bade nahi

**Branch names:** `feature/...` (naya kaam), `fix/...` (bug), `backend/...`

---

## Frontend phase: 

| Person A | Person B |
|---|---|
Manager Panel (menu, toppings, tax, stations, tables, staff) ready hai. Baqi:

| Person A | Person B |
|---|---|
| Open Orders screen (server ke khule orders) | Station / Kitchen Display screen (station-wise tickets, `K101` login) |
| Add-on items (purane order mein naye items) | Docket preview widget (Pizza / Starter / Cut Table) |
| Bill screen: discount, payment method select, `BillCalculator` se total, Paid -> table free | Manager: Daily sales report (cash vs card, top items) |
| Table floor view (saare halls, status colors) | Manager: Void item (sirf manager) |

---

## Phase 2: Backend 

1. `backend/` mein Node + Express + MySQL APIs banao (`database/schema.sql` run karo)
2. Flutter mein `flutter pub add http`
3. `lib/data/api_pos_repository.dart` banao jo `PosRepository` implement kare (har method `http` se API call aur `Model.fromJson`)
4. `main.dart` mein **sirf ek line** badlo:
   ```dart
   Provider<PosRepository>(create: (_) => ApiPosRepository()),
   ```
5. Android emulator se laptop ka backend: `http://10.0.2.2:3000` (localhost nahi). Real phone se: laptop ka WiFi IP, e.g. `http://192.168.1.5:3000`
6. `http://` (bina https) ke liye `android/app/src/main/AndroidManifest.xml` ke `<application` tag mein `android:usesCleartextTraffic="true"` add karo
