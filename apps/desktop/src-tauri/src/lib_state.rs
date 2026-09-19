use std::path::PathBuf;
use std::sync::{Arc, Mutex};
use tokio::sync::Mutex as TokioMutex;
use crate::indexer::Indexer;
use crate::mdns::MdnsHandle;
use crate::server::ServerHandle;

pub struct AppState {
    pub indexer: Arc<TokioMutex<Indexer>>,
    pub server_handle: Mutex<Option<ServerHandle>>,
    pub mdns_handle: Mutex<Option<MdnsHandle>>,
    /// Directory for persisting generated thumbnail JPEG files.
    pub thumb_cache_dir: PathBuf,
}
