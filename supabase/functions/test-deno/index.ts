import { serve } from "https://deno.land/std@0.208.0/http/server.ts";

const handler = (req: Request): Response => {
  return new Response("Hello, Deno!");
};

console.log("Server running on http://localhost:8000");
await serve(handler, { port: 8000 });
