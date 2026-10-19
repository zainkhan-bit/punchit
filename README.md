# PunchIt: Restaurant Order Punching App

MAD (Mobile Application Development) group project.
Server ID + PIN se login, Dine-in / Takeaway, menu se items punch, toppings + comment, Hall / Table / Server select, aur kitchen stations pe dockets.
**Manager / Owner Panel** se restaurant khud apna menu, prices, toppings, tax (Cash / Card alag), stations, tables aur staff set karta hai. Kuch bhi code mein hard-coded nahi.

- **🎨 Figma Prototype:** [PunchIt — Restaurant POS Prototype](https://www.figma.com/design/9FR4QHRafelroeX5xowQky/PunchIt-%E2%80%94-Restaurant-POS-Prototype?node-id=4-9&t=f21O1SKP7F0Lviyu-1)
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

---
