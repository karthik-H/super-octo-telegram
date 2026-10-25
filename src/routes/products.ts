import { Router } from "express";
import { requireAuth } from "../auth";
import { createProduct, findProductById, listProducts } from "../store";

export const productsRouter = Router();

productsRouter.get("/", (_req, res) => {
  res.json({ products: listProducts() });
});

productsRouter.get("/:id", (req, res) => {
  const product = findProductById(req.params.id);
  if (!product) {
    res.status(404).json({ error: "product not found" });
    return;
  }
  res.json({ product });
});

productsRouter.post("/", requireAuth, (req, res) => {
  const body = req.body as {
    name?: unknown;
    description?: unknown;
    priceCents?: unknown;
    sku?: unknown;
  };

  if (typeof body?.name !== "string" || body.name.trim().length === 0) {
    res.status(400).json({ error: "name is required" });
    return;
  }
  if (body.name.trim().length > 200) {
    res.status(400).json({ error: "name must be 200 characters or fewer" });
    return;
  }

  const description = body.description === undefined ? "" : body.description;
  if (typeof description !== "string" || description.length > 2000) {
    res.status(400).json({ error: "description must be a string of at most 2000 characters" });
    return;
  }

  if (typeof body.priceCents !== "number" || !Number.isInteger(body.priceCents) || body.priceCents < 0) {
    res.status(400).json({ error: "priceCents must be a non-negative integer" });
    return;
  }

  let sku: string | null = null;
  if (body.sku !== undefined && body.sku !== null) {
    if (typeof body.sku !== "string" || body.sku.trim().length === 0 || body.sku.trim().length > 64) {
      res.status(400).json({ error: "sku must be a non-empty string of at most 64 characters" });
      return;
    }
    sku = body.sku.trim();
  }

  const product = createProduct({
    name: body.name.trim(),
    description: description.trim(),
    priceCents: body.priceCents,
    sku,
  });
  res.status(201).json({ product });
});
