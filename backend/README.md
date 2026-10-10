# Backend (Phase 2)

Node.js + Express + MySQL yahan banega, frontend complete hone ke baad.

```bash
npm init -y
npm i express mysql2 bcryptjs jsonwebtoken cors dotenv node-thermal-printer
```

- `.env` GitHub pe push **nahi** hoti (`.gitignore` mein hai), `.env.example` push hoti hai
- Har route `lib/data/pos_repository.dart` ke ek method se match karta hai

## Endpoints

| Method | Endpoint | Repository method | Role |
|---|---|---|---|
| POST | `/api/auth/login` | `login` | Public |
| GET | `/api/categories` | `getCategories` | All |
| GET | `/api/menu` (items + modifier_groups + options) | `getMenuItems` | All |
| GET | `/api/halls`, `/api/halls/:id/tables` | `getHalls`, `getTables` | All |
| GET | `/api/staff/servers` | `getServers` | All |
| POST | `/api/orders` | `placeOrder` | Server, Admin |
| GET | `/api/settings`, `/api/payment-methods` | `getSettings`, `getPaymentMethods` | All |
| POST / PUT / DELETE | `/api/categories[/:id]` | `saveCategory`, `deleteCategory` | Admin |
| POST / PUT / DELETE | `/api/menu[/:id]` | `saveMenuItem`, `deleteMenuItem` | Admin |
| GET / POST / PUT / DELETE | `/api/modifier-groups[/:id]` | `...ModifierGroup` | Admin |
| GET / POST / PUT / DELETE | `/api/stations[/:id]` | `...Station` | Admin |
| POST / PUT / DELETE | `/api/halls[/:id]`, `/api/tables[/:id]` | `saveHall`, `saveTable` ... | Admin |
| GET / POST / PUT | `/api/staff[/:id]` (body mein `pin` optional) | `getAllStaff`, `saveStaff` | Admin |
| POST / PUT / DELETE | `/api/payment-methods[/:id]` | `...PaymentMethod` | Admin |
| PUT | `/api/settings` | `saveSettings` | Admin |

Admin = `role IN ('manager','owner')` (JWT middleware se check).
`id == 0` wala record Flutter se aaye to `POST` (naya), warna `PUT`.

## Rules (mock repository mein bhi yahi hain, wahan dekh lo)

- Category delete: products hon to `400` "Is category mein N products hain"
- Menu item delete: agar `order_items` mein use ho chuka hai to delete ki jagah `is_available = 0`
- Modifier group save: purane options `UPDATE`, naye (`id = 0`) `INSERT`, hataye gaye options agar orders mein use hue to `is_available = 0`, warna `DELETE`
- Staff: delete nahi, `is_active = 0`. PIN hamesha `bcrypt` hash. Aakhri active manager/owner inactive nahi ho sakta
- Payment method: kam az kam 1 active
- Bill: `lib/core/bill_calculator.dart` wala formula hi use karo, aur `tax_percent` order mein snapshot karo
- Saare errors: `res.status(400).json({ error: 'Roman Urdu message' })`, app wohi message dikhati hai
