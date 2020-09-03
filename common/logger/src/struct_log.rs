// Copyright (c) The Libra Core Contributors
// SPDX-License-Identifier: Apache-2.0
use crate::{
    counters::{STRUCT_LOG_CONNECT_ERROR_COUNT, STRUCT_LOG_TCP_CONNECT_COUNT},
    Level,
};
use chrono::{SecondsFormat, Utc};
use serde::Serialize;
use serde_json::Value;
use std::{
    collections::HashMap,
    fmt::Display,
    io,
    io::Write,
    marker::PhantomData,
    net::{TcpStream, ToSocketAddrs},
    time::Duration,
};

#[cfg(test)]
mod tests;

const WRITE_TIMEOUT_MS: u64 = 2000;
const CONNECTION_TIMEOUT_MS: u64 = 5000;

#[derive(Debug, Serialize)]
pub struct StructuredLogEntry {
    /// log message set by macros like info!
    #[serde(skip_serializing_if = "Option::is_none")]
    message: Option<String>,
    /// description of the log
    #[serde(skip_serializing_if = "Option::is_none")]
    pattern: Option<&'static str>,
    /// category of the event
    #[serde(skip_serializing_if = "Option::is_none")]
    category: Option<&'static str>,
    /// name of the event
    #[serde(skip_serializing_if = "Option::is_none")]
    name: Option<&'static str>,
    /// rust module (e.g. consensus::round_manager)
    #[serde(skip_serializing_if = "Option::is_none")]
    module: Option<&'static str>,
    /// filename + line (e.g. consensus/src/round_manager.rs:678)
    #[serde(skip_serializing_if = "Option::is_none")]
    location: Option<&'static str>,
    /// time of the log
    timestamp: String,
    /// Log level
    #[serde(skip_serializing_if = "Option::is_none")]
    level: Option<Level>,
    /// arbitrary data that can be logged
    #[serde(skip_serializing_if = "HashMap::is_empty")]
    data: HashMap<&'static str, Value>,
}

impl Default for StructuredLogEntry {
    fn default() -> Self {
        Self {
            message: None,
            pattern: None,
            category: None,
            name: None,
            module: None,
            location: None,
            timestamp: Utc::now().to_rfc3339_opts(SecondsFormat::Micros, true),
            level: None,
            data: Default::default(),
        }
    }
}

impl crate::Schema for StructuredLogEntry {
    fn visit(&self, visitor: &mut dyn crate::Visitor) {
        use crate::{Key, Value};

        for (key, val) in &self.data {
            visitor.visit_pair(Key::new(key), Value::from_serde(val));
        }
    }
}

impl StructuredLogEntry {
    /// Specifically for text based conversion logs
    pub fn new_text() -> Self {
        let mut ret = Self::default();
        ret.category = Some("text");
        ret
    }

    /// Creates a log with a category and a name.  This should be preferred
    pub fn new_named(category: &'static str, name: &'static str) -> Self {
        let mut ret = Self::default();
        ret.category = Some(category);
        ret.name = Some(name);
        ret
    }

    /// Sets the log level of the log
    pub fn level(mut self, level: Level) -> Self {
        self.level = Some(level);
        self
    }

    pub(crate) fn json_data(mut self, key: &'static str, value: Value) -> Self {
        self.data.insert(key, value);
        self
    }

    pub fn schema<S: crate::Schema>(mut self, schema: S) -> Self {
        struct JsonVisitor<'a>(&'a mut HashMap<&'static str, serde_json::Value>);

        impl<'a> crate::Visitor for JsonVisitor<'a> {
            fn visit_pair(&mut self, key: crate::Key, value: crate::Value<'_>) {
                use crate::Value;

                let v = match value {
                    Value::Debug(d) => serde_json::Value::String(format!("{:?}", d)),
                    Value::Display(d) => serde_json::Value::String(d.to_string()),
                    Value::Serde(s) => serde_json::to_value(s).unwrap(),
                };

                self.0.insert(key.as_str(), v);
            }
        }

        schema.visit(&mut JsonVisitor(&mut self.data));

        self
    }

    pub fn schemas(mut self, schemas: &[&dyn crate::Schema]) -> Self {
        struct JsonVisitor<'a>(&'a mut HashMap<&'static str, serde_json::Value>);

        impl<'a> crate::Visitor for JsonVisitor<'a> {
            fn visit_pair(&mut self, key: crate::Key, value: crate::Value<'_>) {
                use crate::Value;

                let v = match value {
                    Value::Debug(d) => serde_json::Value::String(format!("{:?}", d)),
                    Value::Display(d) => serde_json::Value::String(d.to_string()),
                    Value::Serde(s) => serde_json::to_value(s).unwrap(),
                };

                self.0.insert(key.as_str(), v);
            }
        }

        for schema in schemas {
            schema.visit(&mut JsonVisitor(&mut self.data));
        }

        self
    }

    /// Add a data field, with a given value, will serialize into JSON and be indexed accordingly
    pub fn data<D: Serialize>(self, key: &'static str, value: D) -> Self {
        self.json_data(
            key,
            serde_json::to_value(value).expect("Failed to serialize StructuredLogEntry key"),
        )
    }

    /// Used for errors and other types that don't serialize well
    pub fn data_display<D: Display>(self, key: &'static str, value: D) -> Self {
        self.data(key, value.to_string())
    }

    /// Add a typed data field to serialize, to ensure type and name consistency
    pub fn field<D: Serialize>(self, field: &LoggingField<D>, value: D) -> Self {
        self.data(field.0, value)
    }

    /// Sets the context log line used for text logs.  This is useful for migration of text logs
    pub fn message(mut self, message: String) -> Self {
        self.message = Some(message);
        self
    }

    #[doc(hidden)] // set from macro
    pub fn add_message(&mut self, message: String) -> &mut Self {
        self.message = Some(message);
        self
    }

    #[doc(hidden)] // set from macro
    pub fn add_category(&mut self, target: &'static str) -> &mut Self {
        if self.category.is_none() {
            self.category = Some(target);
        }
        self
    }

    #[doc(hidden)] // set from macro
    pub fn add_pattern(&mut self, pattern: &'static str) -> &mut Self {
        self.pattern = Some(pattern);
        self
    }

    #[doc(hidden)] // set from macro
    pub fn add_module(&mut self, module: &'static str) -> &mut Self {
        self.module = Some(module);
        self
    }

    #[doc(hidden)] // set from macro
    pub fn add_location(&mut self, location: &'static str) -> &mut Self {
        self.location = Some(location);
        self
    }

    #[doc(hidden)] // set from macro
    pub fn add_data<D: Serialize>(&mut self, key: &'static str, value: D) -> &mut Self {
        self.data.insert(
            key,
            serde_json::to_value(value).expect("Failed to serialize StructuredLogEntry key"),
        );
        self
    }
}

/// Field is similar to .data but restricts type of the value to a specific type.
///
/// Example:
///
/// mod logging {
///    pub const MY_FIELD:LoggingField<u64> = LoggingField::new("my_field");
/// }
///
/// mod my_code {
///    fn my_fn() {
///        info!(StructuredLogEntry::new(...).field(&logging::MY_FIELD, 0))
///    }
/// }
pub struct LoggingField<D>(&'static str, PhantomData<D>);

impl<D> LoggingField<D> {
    pub const fn new(name: &'static str) -> Self {
        Self(name, PhantomData)
    }
}

/// A wrapper for `TcpStream` that handles reconnecting to the endpoint automatically
///
/// `TcpWriter::write()` will block on the message until it is connected.
pub(crate) struct TcpWriter {
    /// The DNS name or IP address logs are being sent to
    endpoint: String,
    /// The `TCPStream` to write to, which will be `None` when disconnected
    stream: Option<TcpStream>,
}

impl TcpWriter {
    pub fn new(endpoint: String) -> Self {
        Self {
            endpoint,
            stream: None,
        }
    }

    pub fn endpoint(&self) -> &str {
        &self.endpoint
    }

    /// Ensure that we get a connection, no matter how long it takes
    /// This will block until there is a connection
    fn refresh_connection(&mut self) {
        loop {
            match self.connect() {
                Ok(stream) => {
                    self.stream = Some(stream);
                    return;
                }
                Err(e) => {
                    log::error!("[Logging] Failed to connect: {}", e);
                    STRUCT_LOG_CONNECT_ERROR_COUNT.inc();
                }
            }

            // Sleep a second so this doesn't just spin as fast as possible
            std::thread::sleep(Duration::from_millis(1000));
        }
    }

    /// Connect and ensure the write timeout is set
    fn connect(&mut self) -> io::Result<TcpStream> {
        STRUCT_LOG_TCP_CONNECT_COUNT.inc();

        let mut last_error = io::Error::new(
            io::ErrorKind::Other,
            format!("Unable to resolve and connect to {}", self.endpoint),
        );

        // resolve addresses to handle DNS names
        for addr in self.endpoint.to_socket_addrs()? {
            match TcpStream::connect_timeout(&addr, Duration::from_millis(CONNECTION_TIMEOUT_MS)) {
                Ok(stream) => {
                    // Set the write timeout
                    if let Err(err) =
                        stream.set_write_timeout(Some(Duration::from_millis(WRITE_TIMEOUT_MS)))
                    {
                        STRUCT_LOG_CONNECT_ERROR_COUNT.inc();
                        log::error!("[Logging] Failed to set write timeout: {}", err);
                        continue;
                    }
                    return Ok(stream);
                }
                Err(err) => last_error = err,
            }
        }

        Err(last_error)
    }
}

impl Write for TcpWriter {
    fn write(&mut self, buf: &[u8]) -> io::Result<usize> {
        // Refresh the connection if it's missing
        if self.stream.is_none() {
            self.refresh_connection();
        }

        // Attempt to write, and if it fails clear underlying stream
        // This doesn't guarantee a message cut off mid send will work, but it does guarantee that
        // we will connect first
        let mut stream = self.stream.as_ref().unwrap();
        let result = stream.write(buf);
        if result.is_err() {
            self.stream = None;
        }

        result
    }

    fn flush(&mut self) -> io::Result<()> {
        if let Some(mut stream) = self.stream.as_ref() {
            stream.flush()
        } else {
            Err(io::Error::new(
                io::ErrorKind::NotConnected,
                "Can't flush, not connected",
            ))
        }
    }
}
