export type User = {
  id: string;
  email: string;
  name: string;
  passwordHash: string;
};

export type PublicUser = {
  id: string;
  email: string;
  name: string;
};

export type Product = {
  id: string;
  name: string;
  description: string;
  priceCents: number;
  sku: string | null;
  createdAt: string;
};

declare global {
  namespace Express {
    interface Request {
      userId?: string;
    }
  }
}
