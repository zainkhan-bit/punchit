# PunchIt: Restaurant Order Punching App

MAD (Mobile Application Development) group project.
Employee ID + PIN se login, Dine-in / Takeaway, table select, menu se items punch, toppings + comment, kitchen queue, payment (Cash / Card) aur receipt.
**Manager / Owner Panel** se restaurant khud apna menu, prices, toppings, tax (Cash / Card alag), stations, tables aur staff set karta hai, aur daily report dekhta hai. Kuch bhi code mein hard-coded nahi.

- **🎨 Figma Prototype:** [PunchIt — Restaurant POS Prototype](https://www.figma.com/design/9FR4QHRafelroeX5xowQky/PunchIt-%E2%80%94-Restaurant-POS-Prototype?node-id=4-9&t=f21O1SKP7F0Lviyu-1)
- **Frontend:** Flutter (Dart), Android Studio
- **Backend:** Node.js + Express (Phase 2)
- **Database:** MySQL (`database/schema.sql`)

---

## Project structure

```
punchit/
├── README.md               <- yeh guide
├── app/                    <- Flutter project (Android Studio mein yahi folder kholna hai)
│   ├── lib/
│   │   ├── main.dart       <- Providers + theme
│   │   ├── core/           <- theme (Figma colors), bill calculator
│   │   ├── models/         <- saare models
│   │   ├── data/           <- repository interface + mock data
│   │   ├── providers/      <- current order ki state
│   │   ├── widgets/        <- Figma ke common widgets (ui_kit), order card
│   │   └── screens/        <- server, kitchen/ aur admin/ screens
│   └── test/               <- widget tests
├── database/
│   └── schema.sql          <- poora MySQL schema + sample data
└── backend/
    └── README.md           <- Phase 2 (API endpoints)
```

## App chalana

```bash
cd app
flutter pub get
flutter analyze
flutter test
flutter run
```

Abhi data **mock** hai (memory mein). App band karne pe naye orders aur changes reset ho jate hain. Backend banne ke baad `main.dart` mein sirf repository wali ek line badalni hai.

---

## Screens (Figma ke mutabiq)

**Server**

| File | Kaam |
|---|---|
| `screens/login_screen.dart` | Employee ID + 4-digit PIN. Role ke hisaab se Server / Kitchen / Manager screen |
| `screens/order_type_screen.dart` | Server Home: active orders, free tables, Dine-in / Takeaway, "On your floor" |
| `screens/choose_table_screen.dart` | Hall -> Table (free / occupied / bill) -> Server |
| `screens/menu_screen.dart` | Take an order: category pills, search, items, quick add (+) |
| `screens/item_options_screen.dart` | Make it their way: Crust (required), Extra Toppings (max 5), quick notes, comment, qty |
| `screens/order_summary_screen.dart` | Review order: edit, qty +/-, swipe to delete, Cash vs Card estimate, takeaway customer, Send to kitchen |
| `screens/order_sent_screen.dart` | "The kitchen has it." + what happens next |
| `screens/your_orders_screen.dart` | Active (payment baqi) aur History (paid) orders |
| `screens/collect_payment_screen.dart` | Payment method, cash received + change, ya card reference |
| `screens/payment_complete_screen.dart` | Receipt (restaurant naam, tax, footer). Table free ho jati hai |
| `screens/server_nav.dart` | Server bottom bar: Home, Orders, Tables, Sign out |

**Kitchen**

| File | Kaam |
|---|---|
| `screens/kitchen/kitchen_queue_screen.dart` | Kitchen queue aur Ready for pickup: Start preparing -> Mark ready -> Served |

**Manager / Owner**

| File | Kaam |
|---|---|
| `screens/admin/admin_home_screen.dart` | Restaurant overview: aaj ki sales, orders in progress, staff on shift, Take order |
| `screens/admin/products_screen.dart` | Manage menu: All / Unavailable, search, category filter, **available ON/OFF switch** |
| `screens/admin/product_form_screen.dart` | Naam, price, category, station override, toppings groups |
| `screens/admin/staff_screen.dart` | Staff & access: team members, role permissions, add / edit, PIN reset, active / inactive |
| `screens/admin/daily_report_screen.dart` | Total sales, sales through the day (chart), payment breakdown, tables occupied |
| `screens/admin/order_history_screen.dart` | Completed (paid) orders |
| `screens/admin/restaurant_settings_screen.dart` | Settings hub: halls & tables, stations, tax, categories, toppings |
| `screens/admin/categories_screen.dart` | Category add/edit/delete, station (printer) link, menu order |
| `screens/admin/modifier_groups_screen.dart` | Topping groups, ek/multiple select, required, options + extra price, drag to reorder |
| `screens/admin/tax_settings_screen.dart` | Payment methods ka tax %, service charge, restaurant naam, bill footer |
| `screens/admin/stations_screen.dart` | Kitchen stations, Item vs Cut Table, printer IP/port |
| `screens/admin/floor_screen.dart` | Halls aur tables (number, seats) |
| `screens/admin/manager_nav.dart` | Manager bottom bar: Home, Menu, Reports, Settings |

**Baqi files**

| File | Kaam |
|---|---|
| `core/app_theme.dart` | Figma colors, theme, `rs()` aur date/time format |
| `core/bill_calculator.dart` | Tax / service charge ka formula (ek hi jagah) |
| `widgets/ui_kit.dart` | Figma widgets: header, buttons, cards, pills, banners, bottom nav |
| `widgets/order_card.dart` | Order card (server, kitchen, history) |
| `widgets/admin_widgets.dart` | Panel ke common dialogs, validators |
| `data/pos_repository.dart` | Interface: screens sirf isse data lete hain |
| `data/mock_pos_repository.dart` | Dummy data (wohi jo `schema.sql` mein hai) + demo orders |
| `providers/order_provider.dart` | Current order ki state (cart, table, server) |
| `models/models.dart` | Saare models (`PlacedOrder` bhi) + `fromJson` |

---

## Demo login (PIN sab ka `1234`)

| ID | Kaun | Kahan jata hai |
|---|---|---|
| `S101`, `S102`, `S103` | Servers | Server Home |
| `K101` | Kitchen | Kitchen queue |
| `M201` | Manager (Zain) | Restaurant overview |
| `O301` | Owner | Restaurant overview |

## Demo flows

**Server:** Login -> Dine-in -> table + server -> items (toppings + comment) -> Review order (Cash / Card total) -> Send to kitchen -> Your orders -> Collect payment -> receipt. Table occupied ho kar payment ke baad free ho jati hai.

**Kitchen:** `K101` -> order pe "Mark ready" -> Ready tab -> "Mark served". Server ki orders list mein status update ho jata hai.

**Owner (demo mein yeh zaroor dikhana):**
1. `O301` se login -> **Menu** -> "Fries" ka switch OFF -> logout
2. `S101` se login -> menu mein Fries "Not available" dikhega
3. Owner -> **Settings** -> Tax & payments -> Card tax badlo -> Review order aur Collect payment mein naya total
4. Owner -> **Menu** -> Add a product (price + toppings group) -> server ke menu mein foran aa jata hai
5. Payment ke baad Owner -> **Reports** mein sales aur payment breakdown

## Rules jo app khud enforce karti hai (viva points)

- Category mein products hain to delete nahi hogi
- Hall mein tables hain to delete nahi hoga; occupied table delete nahi hogi
- Occupied table pe naya order nahi lagta
- Staff delete nahi hota, sirf **inactive** (purane orders mein naam chahiye). Inactive login nahi kar sakta
- Kam az kam 1 active Manager/Owner aur 1 active payment method hamesha rehna chahiye
- Station delete ho to us ki categories "sirf Cut Table" pe chali jati hain (DB mein `ON DELETE SET NULL`)
- Cash payment total se kam ho to record nahi hoti; ek order ki payment do baar nahi hoti
- Tax rate bill pe **snapshot** hota hai (`orders.tax_percent`), baad mein rate badle to purane bills same rahein
