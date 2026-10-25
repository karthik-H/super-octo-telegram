import { createApp } from "./app";

const port = Number(process.env.PORT ?? 3000);
if (!Number.isInteger(port) || port <= 0) {
  throw new Error("PORT must be a positive integer");
}

createApp().listen(port, () => {
  console.log(`e-commerce service listening on ${port}`);
});
