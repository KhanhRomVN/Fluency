import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import App from "./App";
import "@/styles/index.css";

// Suppress harmless Monaco Editor errors
window.addEventListener("unhandledrejection", (event) => {
  // Check for "operation is manually canceled" error from Monaco
  if (
    event.reason &&
    event.reason.type === "cancelation" &&
    event.reason.msg === "operation is manually canceled"
  ) {
    event.preventDefault(); // Prevent logging as an error
    return;
  }

  // Check for "message channel closed" error
  if (
    event.reason instanceof Error &&
    event.reason.message.includes(
      "A listener indicated an asynchronous response by returning true, but the message channel closed before a response was received"
    )
  ) {
    event.preventDefault(); // Prevent logging as an error
    return;
  }
});

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <App />
  </StrictMode>
);
