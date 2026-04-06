// agent-browser-core-unofficial
// Unofficial Rust library crate exposing the core of agent-browser.
// Original work Copyright 2025 Vercel Inc., licensed under Apache-2.0.
// See NOTICE for full attribution.

pub mod color;
pub mod commands;
pub mod connection;
pub mod flags;
pub mod native;
pub mod output;
pub mod validation;

#[cfg(test)]
pub mod test_utils;

// Convenience re-exports for library consumers
pub use commands::{gen_id, parse_command};
pub use connection::{ensure_daemon, send_command, DaemonOptions, DaemonResult, Response};
pub use flags::{parse_flags, Flags};
pub use validation::{is_valid_session_name, session_name_error};
