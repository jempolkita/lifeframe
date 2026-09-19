use std::fs::File;
use std::io::BufReader;
use std::path::Path;
use crate::models::{ExifData, GeoLocation};

pub struct ParsedMetadata {
    pub date_taken: Option<String>,
    pub exif: Option<ExifData>,
    pub gps: Option<GeoLocation>,
}

/// Fast-path extraction of embedded JPEG preview thumbnail directly from camera/smartphone
/// EXIF headers without decoding full 24-48MP raw image data (~1ms response time).
pub fn extract_exif_thumbnail(path: &Path) -> Option<Vec<u8>> {
    let file = File::open(path).ok()?;
    let mut reader = BufReader::new(file);
    let exif_reader = exif::Reader::new();
    let exif = exif_reader.read_from_container(&mut reader).ok()?;

    // Check IFD1 (In::THUMBNAIL) first, then fallback to In::PRIMARY
    let (offset_field, len_field) = match (
        exif.get_field(exif::Tag::JPEGInterchangeFormat, exif::In::THUMBNAIL),
        exif.get_field(exif::Tag::JPEGInterchangeFormatLength, exif::In::THUMBNAIL),
    ) {
        (Some(o), Some(l)) => (o, l),
        _ => match (
            exif.get_field(exif::Tag::JPEGInterchangeFormat, exif::In::PRIMARY),
            exif.get_field(exif::Tag::JPEGInterchangeFormatLength, exif::In::PRIMARY),
        ) {
            (Some(o), Some(l)) => (o, l),
            _ => return None,
        },
    };

    let offset = offset_field.value.get_uint(0)? as usize;
    let len = len_field.value.get_uint(0)? as usize;
    if len == 0 {
        return None;
    }

    // 1. Try reading from exif.buf() (TIFF-relative offset)
    let buf = exif.buf();
    if offset + len <= buf.len() {
        let slice = &buf[offset..offset + len];
        if slice.len() >= 2 && slice[0] == 0xFF && slice[1] == 0xD8 {
            return Some(slice.to_vec());
        }
    }

    // 2. Fallback: Try reading from file directly (in case offset is file-absolute)
    use std::io::{Read, Seek, SeekFrom};
    if let Ok(mut f) = File::open(path) {
        if f.seek(SeekFrom::Start(offset as u64)).is_ok() {
            let mut thumb_buf = vec![0u8; len];
            if f.read_exact(&mut thumb_buf).is_ok() {
                if thumb_buf.starts_with(&[0xFF, 0xD8]) {
                    return Some(thumb_buf);
                }
            }
        }
    }

    None
}

pub fn parse_exif(path: &Path) -> ParsedMetadata {
    let file = match File::open(path) {
        Ok(f) => f,
        Err(_) => {
            return ParsedMetadata {
                date_taken: None,
                exif: None,
                gps: None,
            }
        }
    };

    let mut reader = BufReader::new(file);
    let exif_reader = exif::Reader::new();
    let exif = match exif_reader.read_from_container(&mut reader) {
        Ok(e) => e,
        Err(_) => {
            return ParsedMetadata {
                date_taken: None,
                exif: None,
                gps: None,
            }
        }
    };

    let mut date_taken = None;
    let mut exif_data = ExifData::default();
    let mut has_exif = false;

    // Date Taken
    if let Some(field) = exif.get_field(exif::Tag::DateTimeOriginal, exif::In::PRIMARY) {
        date_taken = Some(field.display_value().to_string());
    } else if let Some(field) = exif.get_field(exif::Tag::DateTime, exif::In::PRIMARY) {
        date_taken = Some(field.display_value().to_string());
    }

    // Format EXIF date "YYYY:MM:DD HH:MM:SS" to ISO "YYYY-MM-DDTHH:MM:SS"
    if let Some(ref dt) = date_taken {
        let parts: Vec<&str> = dt.split_whitespace().collect();
        if parts.len() == 2 {
            let date_part = parts[0].replace(':', "-");
            date_taken = Some(format!("{}T{}", date_part, parts[1]));
        }
    }

    // Camera Make & Model
    if let Some(field) = exif.get_field(exif::Tag::Make, exif::In::PRIMARY) {
        exif_data.make = Some(field.display_value().to_string().trim_matches('"').to_string());
        has_exif = true;
    }
    if let Some(field) = exif.get_field(exif::Tag::Model, exif::In::PRIMARY) {
        exif_data.model = Some(field.display_value().to_string().trim_matches('"').to_string());
        has_exif = true;
    }
    if let Some(field) = exif.get_field(exif::Tag::LensModel, exif::In::PRIMARY) {
        exif_data.lens = Some(field.display_value().to_string().trim_matches('"').to_string());
        has_exif = true;
    }

    // Exposure & Optics
    if let Some(field) = exif.get_field(exif::Tag::ExposureTime, exif::In::PRIMARY) {
        exif_data.exposure_time = Some(field.display_value().to_string());
        has_exif = true;
    }
    if let Some(field) = exif.get_field(exif::Tag::FNumber, exif::In::PRIMARY) {
        if let exif::Value::Rational(ref vec) = field.value {
            if let Some(val) = vec.first() {
                exif_data.f_number = Some(val.to_f32());
                has_exif = true;
            }
        }
    }
    if let Some(field) = exif.get_field(exif::Tag::FocalLength, exif::In::PRIMARY) {
        if let exif::Value::Rational(ref vec) = field.value {
            if let Some(val) = vec.first() {
                exif_data.focal_length = Some(val.to_f32());
                has_exif = true;
            }
        }
    }
    if let Some(field) = exif.get_field(exif::Tag::PhotographicSensitivity, exif::In::PRIMARY) {
        if let exif::Value::Short(ref vec) = field.value {
            if let Some(val) = vec.first() {
                exif_data.iso = Some(*val as u32);
                has_exif = true;
            }
        }
    }

    // GPS coordinates
    let gps = parse_gps(&exif);

    ParsedMetadata {
        date_taken,
        exif: if has_exif { Some(exif_data) } else { None },
        gps,
    }
}

fn parse_gps(exif: &exif::Exif) -> Option<GeoLocation> {
    let lat_field = exif.get_field(exif::Tag::GPSLatitude, exif::In::PRIMARY)?;
    let lat_ref = exif.get_field(exif::Tag::GPSLatitudeRef, exif::In::PRIMARY)?;
    let lon_field = exif.get_field(exif::Tag::GPSLongitude, exif::In::PRIMARY)?;
    let lon_ref = exif.get_field(exif::Tag::GPSLongitudeRef, exif::In::PRIMARY)?;

    let lat = convert_dms_to_deg(&lat_field.value)?;
    let lon = convert_dms_to_deg(&lon_field.value)?;

    let lat_mult = if lat_ref.display_value().to_string().starts_with('S') { -1.0 } else { 1.0 };
    let lon_mult = if lon_ref.display_value().to_string().starts_with('W') { -1.0 } else { 1.0 };

    let mut altitude = None;
    if let Some(alt_field) = exif.get_field(exif::Tag::GPSAltitude, exif::In::PRIMARY) {
        if let exif::Value::Rational(ref vec) = alt_field.value {
            if let Some(val) = vec.first() {
                altitude = Some(val.to_f64());
            }
        }
    }

    Some(GeoLocation {
        latitude: lat * lat_mult,
        longitude: lon * lon_mult,
        altitude,
    })
}

fn convert_dms_to_deg(val: &exif::Value) -> Option<f64> {
    if let exif::Value::Rational(ref vec) = *val {
        if vec.len() >= 3 {
            let deg = vec[0].to_f64();
            let min = vec[1].to_f64();
            let sec = vec[2].to_f64();
            return Some(deg + (min / 60.0) + (sec / 3600.0));
        }
    }
    None
}
