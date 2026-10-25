import { randomUUID } from "crypto";
import type { Product, PublicUser, User } from "./types";

const usersById = new Map<string, User>();
const usersByEmail = new Map<string, User>();
const productsById = new Map<string, Product>();

export function toPublicUser(user: User): PublicUser {
  return { id: user.id, email: user.email, name: user.name };
}

export function findUserByEmail(email: string): User | undefined {
  return usersByEmail.get(email);
}

export function findUserById(id: string): User | undefined {
  return usersById.get(id);
}

export function createUser(input: {
  email: string;
  name: string;
  passwordHash: string;
}): User {
  const user: User = {
    id: randomUUID(),
    email: input.email,
    name: input.name,
    passwordHash: input.passwordHash,
  };
  usersById.set(user.id, user);
  usersByEmail.set(user.email, user);
  return user;
}

export function listProducts(): Product[] {
  return [...productsById.values()];
}

export function findProductById(id: string): Product | undefined {
  return productsById.get(id);
}

export function createProduct(input: {
  name: string;
  description: string;
  priceCents: number;
  sku: string | null;
}): Product {
  const product: Product = {
    id: randomUUID(),
    name: input.name,
    description: input.description,
    priceCents: input.priceCents,
    sku: input.sku,
    createdAt: new Date().toISOString(),
  };
  productsById.set(product.id, product);
  return product;
}
