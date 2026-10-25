import { Router } from "express";
import { hashPassword, signToken, verifyPassword } from "../auth";
import { createUser, findUserByEmail, toPublicUser } from "../store";

export const authRouter = Router();

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

authRouter.post("/register", (req, res) => {
  const body = req.body as { email?: unknown; password?: unknown; name?: unknown };
  if (
    typeof body?.email !== "string" ||
    typeof body.password !== "string" ||
    typeof body.name !== "string"
  ) {
    res.status(400).json({ error: "email, password, and name are required" });
    return;
  }

  const email = body.email.trim().toLowerCase();
  const name = body.name.trim();
  if (!EMAIL_PATTERN.test(email)) {
    res.status(400).json({ error: "email is invalid" });
    return;
  }
  if (name.length === 0) {
    res.status(400).json({ error: "name is required" });
    return;
  }
  if (body.password.length < 8) {
    res.status(400).json({ error: "password must be at least 8 characters" });
    return;
  }
  if (findUserByEmail(email)) {
    res.status(409).json({ error: "email is already registered" });
    return;
  }

  const user = createUser({
    email,
    name,
    passwordHash: hashPassword(body.password),
  });
  res.status(201).json({ user: toPublicUser(user) });
});

authRouter.post("/login", (req, res) => {
  const body = req.body as { email?: unknown; password?: unknown };
  if (typeof body?.email !== "string" || typeof body.password !== "string") {
    res.status(400).json({ error: "email and password are required" });
    return;
  }

  const email = body.email.trim().toLowerCase();
  const user = findUserByEmail(email);
  if (!user || !verifyPassword(body.password, user.passwordHash)) {
    res.status(401).json({ error: "invalid email or password" });
    return;
  }

  res.json({
    token: signToken(user.id),
    user: toPublicUser(user),
  });
});
