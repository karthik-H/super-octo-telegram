# super-octo-telegram

TypeScript e-commerce service. Accounts are created with register and login. Logged-in users add products to the catalog. Anyone can read the catalog.

Users and products are kept in memory and reset when the process stops. Passwords are stored as scrypt hashes. Login returns a bearer token that expires after 7 days.

## Run

```bash
npm install
npm run dev
```

`npm run build` then `npm start` runs the compiled server. The service listens on port `3000`, or `PORT` if set. Set `JWT_SECRET` before using this outside local development.

## Auth

`POST /auth/register`

```json
{ "email": "ada@example.com", "password": "secret123", "name": "Ada" }
```

`201` returns `{ "user": { "id", "email", "name" } }`. Duplicate emails return `409`.

`POST /auth/login`

```json
{ "email": "ada@example.com", "password": "secret123" }
```

`200` returns `{ "token", "user" }`. Wrong credentials return `401`.

## Products

`POST /products` requires `Authorization: Bearer <token>`.

```json
{ "name": "Mug", "description": "Ceramic mug", "priceCents": 1299, "sku": "MUG-1" }
```

`priceCents` is a non-negative integer. `description` and `sku` are optional. `201` returns `{ "product" }`.

`GET /products` returns `{ "products": [...] }`.

`GET /products/:id` returns `{ "product" }`, or `404` when the id is unknown.
