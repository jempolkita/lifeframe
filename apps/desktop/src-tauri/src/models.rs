use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BoundingBox {
    pub x: f32,
    pub y: f32,
    pub width: f32,
    pub height: f32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FaceTag {
    pub id: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub person_id: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub person_name: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub confidence: Option<f32>,
    pub is_confirmed: bool,
    pub box_area: BoundingBox,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Person {
    pub id: String,
    pub name: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub thumbnail_face_id: Option<String>,
    pub photo_count: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GeoLocation {
    pub latitude: f64,
    pub longitude: f64,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub altitude: Option<f64>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct ExifData {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub make: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub model: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub lens: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub focal_length: Option<f32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub f_number: Option<f32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub iso: Option<u32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub exposure_time: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Photo {
    pub id: String,
    pub filename: String,
    pub relative_path: String,
    pub size_bytes: i64,
    pub hash_sha256: String,
    pub mime_type: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub width: Option<u32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub height: Option<u32>,
    pub rating: i32,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub date_taken: Option<String>,
    pub date_modified: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub album_id: Option<String>,
    pub tags: Vec<String>,
    pub faces: Vec<FaceTag>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub gps: Option<GeoLocation>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub exif: Option<ExifData>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub library_path: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Album {
    pub id: String,
    pub name: String,
    pub relative_path: String,
    pub photo_count: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncManifest {
    pub server_id: String,
    pub server_name: String,
    pub generated_at: String,
    pub total_photos: i64,
    pub total_size_bytes: i64,
    pub photos: Vec<Photo>,
    pub albums: Vec<Album>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub people: Vec<Person>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DeviceStatus {
    pub device_id: String,
    pub device_name: String,
    pub device_type: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub battery_percentage: Option<i32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub is_charging: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub storage_free_bytes: Option<i64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub storage_total_bytes: Option<i64>,
    pub client_version: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub last_sync_at: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub sync_status: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DeviceStatusResponse {
    pub success: bool,
    pub message: String,
    pub server_time: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UploadResponse {
    pub success: bool,
    pub photo_id: String,
    pub relative_path: String,
    pub message: String,
}

/// Represents one node in the library folder tree returned to the frontend.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FolderNode {
    /// Display label (folder name or library root path)
    pub label: String,
    /// Absolute path on disk
    pub path: String,
    /// Number of indexed photos directly under this node
    pub photo_count: i64,
    /// Whether this node is a library root (added by the user)
    pub is_library_root: bool,
    /// Sub-folders
    pub children: Vec<FolderNode>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ErrorResponse {
    pub code: String,
    pub message: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub details: Option<String>,
}
