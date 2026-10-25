import { randomBytes, scryptSync, timingSafeEqual } from "crypto";
import type { NextFunction, Request, Response } from "express";
import jwt from "jsonwebtoken";
import { findUserById } from "./store";

const KEY_LENGTH = 64;

function tokenSecret(): string {
  return process.env.JWT_SECRET ?? "dev-only-change-me";
}

export function hashPassword(password: string): string {
  const salt = randomBytes(16).toString("hex");
  const hash = scryptSync(password, salt, KEY_LENGTH).toString("hex");
  return `${salt}:${hash}`;
}

export function verifyPassword(password: string, stored: string): boolean {
  const [salt, hash] = stored.split(":");
  if (!salt || !hash) return false;
  const actual = Buffer.from(hash, "hex");
  const expected = scryptSync(password, salt, KEY_LENGTH);
  if (actual.length !== expected.length) return false;
  return timingSafeEqual(actual, expected);
}

export function signToken(userId: string): string {
  return jwt.sign({ sub: userId }, tokenSecret(), { expiresIn: 60 * 60 * 24 * 7 });
}

export function readUserId(token: string): string | null {
  try {
    const payload = jwt.verify(token, tokenSecret());
    if (typeof payload === "string" || typeof payload.sub !== "string") return null;
    return payload.sub;
  } catch {
    return null;
  }
}

export function requireAuth(req: Request, res: Response, next: NextFunction): void {
  const header = req.header("authorization");
  if (!header?.startsWith("Bearer ")) {
    res.status(401).json({ error: "missing bearer token" });
    return;
  }

  const userId = readUserId(header.slice("Bearer ".length).trim());
  if (!userId || !findUserById(userId)) {
    res.status(401).json({ error: "invalid token" });
    return;
  }

  req.userId = userId;
  next();
}
