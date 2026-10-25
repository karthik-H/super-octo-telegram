import express, { type NextFunction, type Request, type Response } from "express";
import { authRouter } from "./routes/auth";
import { productsRouter } from "./routes/products";

export function createApp(): express.Express {
  const app = express();
  app.use(express.json());

  app.use("/auth", authRouter);
  app.use("/products", productsRouter);

  app.use((req, res) => {
    res.status(404).json({ error: `no route for ${req.method} ${req.path}` });
  });

  app.use((err: unknown, _req: Request, res: Response, next: NextFunction) => {
    if (err instanceof SyntaxError) {
      res.status(400).json({ error: "invalid JSON" });
      return;
    }
    next(err);
  });

  return app;
}
