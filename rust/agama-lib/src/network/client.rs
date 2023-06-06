use super::model::{NetworkConnection, WirelessSettings};
use crate::error::ServiceError;

use super::proxies::ConnectionsProxy;
use super::proxies::IPv4Proxy;
use super::proxies::WirelessProxy;
use zbus::Connection;

pub struct NetworkClient<'a> {
    pub connection: Connection,
    connections_proxy: ConnectionsProxy<'a>,
}

impl<'a> NetworkClient<'a> {
    pub async fn new(connection: Connection) -> Result<NetworkClient<'a>, ServiceError> {
        Ok(Self {
            connections_proxy: ConnectionsProxy::new(&connection).await?,
            connection,
        })
    }

    pub async fn connections(&self) -> Result<Vec<NetworkConnection>, ServiceError> {
        let connection_paths = self.connections_proxy.get_connections().await?;
        let mut connections = vec![];

        for path in connection_paths {
            let mut connection = self.connection_from(path.as_str()).await?;

            if let Ok(wireless) = self.wireless_from(path.as_str()).await {
                connection.wireless = Some(wireless);
            }

            connections.push(connection);
        }

        Ok(connections)
    }
    async fn connection_from(&self, path: &str) -> Result<NetworkConnection, ServiceError> {
        let ipv4_proxy = IPv4Proxy::builder(&self.connection)
            .path(path)?
            .build()
            .await?;

        let meth = ipv4_proxy.method().await?;
        let gateway = ipv4_proxy.gateway().await?;
        let nameservers = ipv4_proxy.nameservers().await?;
        let addresses = ipv4_proxy.addresses().await?;
        let addresses = addresses
            .into_iter()
            .map(|(ip, prefix)| format!("{ip}/{prefix}"))
            .collect();

        Ok(NetworkConnection {
            name: path.to_string(),
            gateway,
            addresses,
            nameservers,
            ..Default::default()
        })
    }

    async fn wireless_from(&self, path: &str) -> Result<WirelessSettings, ServiceError> {
        let wireless_proxy = WirelessProxy::builder(&self.connection)
            .path(path)?
            .build()
            .await?;
        let wireless = WirelessSettings {
            mode: wireless_proxy.mode().await?,
            password: wireless_proxy.password().await?,
            security: wireless_proxy.security().await?,
            ssid: wireless_proxy.ssid().await?,
        };

        Ok(wireless)
    }
}
