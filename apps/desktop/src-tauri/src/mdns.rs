use mdns_sd::{ServiceDaemon, ServiceInfo};
use std::collections::HashMap;

pub struct MdnsHandle {
    daemon: ServiceDaemon,
    fullname: String,
}

impl MdnsHandle {
    pub fn unregister(self) {
        let _ = self.daemon.unregister(&self.fullname);
        let _ = self.daemon.shutdown();
    }
}

pub fn register_service(port: u16) -> Result<MdnsHandle, Box<dyn std::error::Error + Send + Sync>> {
    let daemon = ServiceDaemon::new()?;

    let service_type = "_http._tcp.local.";
    let instance_name = "Lifeframe Desktop";
    let host = std::env::var("COMPUTERNAME")
        .or_else(|_| std::env::var("HOSTNAME"))
        .unwrap_or_else(|_| "lifeframe-host".to_string());
    let host_name = format!("{}.local.", host);

    let mut properties = HashMap::new();
    properties.insert("name".to_string(), "Lifeframe Server".to_string());
    properties.insert("version".to_string(), "1.0.0".to_string());
    properties.insert("server_id".to_string(), "lifeframe-desktop-server".to_string());
    properties.insert("api_path".to_string(), "/api/manifest".to_string());

    // Resolve local IPv4
    let ip_str = local_ip_address::local_ip()
        .map(|ip| ip.to_string())
        .unwrap_or_else(|_| "127.0.0.1".to_string());

    let service_info = ServiceInfo::new(
        service_type,
        instance_name,
        &host_name,
        &ip_str,
        port,
        properties,
    )?;

    let fullname = service_info.get_fullname().to_string();
    daemon.register(service_info)?;

    Ok(MdnsHandle { daemon, fullname })
}
