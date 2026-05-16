pub mod models;

use models::*;
use reqwest::blocking::Client;
use reqwest::header::{HeaderMap, HeaderValue, CONTENT_TYPE};
use std::time::Duration;

pub struct JellyfinClient {
    client: Client,
}

impl JellyfinClient {
    pub fn new() -> Self {
        let client = Client::builder()
            .timeout(Duration::from_secs(15))
            .build()
            .expect("reqwest client");
        Self { client }
    }

    fn auth_header(token: &str) -> HeaderMap {
        let mut h = HeaderMap::new();
        let val = format!(
            r#"MediaBrowser Client="JellyClient-Rust", Device="Windows", DeviceId="jellyclient-rs", Version="0.1", Token="{}""#,
            token
        );
        h.insert("X-Emby-Authorization", HeaderValue::from_str(&val).unwrap());
        h.insert(CONTENT_TYPE, HeaderValue::from_static("application/json"));
        h
    }

    fn base_header() -> HeaderMap {
        let mut h = HeaderMap::new();
        h.insert(
            "X-Emby-Authorization",
            HeaderValue::from_static(
                r#"MediaBrowser Client="JellyClient-Rust", Device="Windows", DeviceId="jellyclient-rs", Version="0.1""#,
            ),
        );
        h.insert(CONTENT_TYPE, HeaderValue::from_static("application/json"));
        h
    }

    pub fn authenticate(
        &self,
        server_url: &str,
        username: &str,
        password: &str,
    ) -> Result<AuthResult, String> {
        let url = format!("{}/Users/AuthenticateByName", server_url);
        let body = serde_json::json!({ "Username": username, "Pw": password });

        let resp = self
            .client
            .post(&url)
            .headers(Self::base_header())
            .json(&body)
            .send()
            .map_err(|e| format!("Connexion impossible : {}", e))?;

        if !resp.status().is_success() {
            return Err(format!("Identifiants incorrects ({})", resp.status()));
        }

        resp.json::<AuthResult>()
            .map_err(|e| format!("Réponse inattendue : {}", e))
    }

    /// Liste tous les utilisateurs du serveur (GET /Users)
    pub fn get_users(&self, session: &Session) -> Result<Vec<models::UserDto>, String> {
        let url = format!("{}/Users", session.server_url);
        let resp = self
            .client
            .get(&url)
            .headers(Self::auth_header(&session.token))
            .send()
            .map_err(|e| e.to_string())?;
        resp.json::<Vec<models::UserDto>>().map_err(|e| e.to_string())
    }

    pub fn authenticate_user(
        &self,
        server_url: &str,
        username: &str,
        password: &str,
    ) -> Result<AuthResult, String> {
        self.authenticate(server_url, username, password)
    }

    pub fn get_libraries(&self, session: &Session) -> Result<Vec<JellyItem>, String> {
        let url = format!("{}/Users/{}/Views", session.server_url, session.user_id);
        let resp = self
            .client
            .get(&url)
            .headers(Self::auth_header(&session.token))
            .send()
            .map_err(|e| e.to_string())?;
        let data: ItemsResponse = resp.json().map_err(|e| e.to_string())?;
        Ok(data.items)
    }

    pub fn get_resume(&self, session: &Session) -> Result<Vec<JellyItem>, String> {
        let url = format!(
            "{}/Users/{}/Items/Resume?Limit=12&Fields=Overview,UserData",
            session.server_url, session.user_id
        );
        let resp = self
            .client
            .get(&url)
            .headers(Self::auth_header(&session.token))
            .send()
            .map_err(|e| e.to_string())?;
        let data: ItemsResponse = resp.json().map_err(|e| e.to_string())?;
        Ok(data.items)
    }

    pub fn get_latest(
        &self,
        session: &Session,
        parent_id: &str,
    ) -> Result<Vec<JellyItem>, String> {
        let url = format!(
            "{}/Users/{}/Items/Latest?ParentId={}&Limit=16&Fields=Overview,UserData",
            session.server_url, session.user_id, parent_id
        );
        let resp = self
            .client
            .get(&url)
            .headers(Self::auth_header(&session.token))
            .send()
            .map_err(|e| e.to_string())?;
        resp.json::<Vec<JellyItem>>().map_err(|e| e.to_string())
    }

    pub fn get_items(
        &self,
        session: &Session,
        parent_id: &str,
        start: usize,
        limit: usize,
    ) -> Result<ItemsResponse, String> {
        let url = format!(
            "{}/Users/{}/Items?ParentId={}&StartIndex={}&Limit={}\
             &SortBy=SortName&SortOrder=Ascending&Fields=Overview,UserData&Recursive=false",
            session.server_url, session.user_id, parent_id, start, limit
        );
        let resp = self
            .client
            .get(&url)
            .headers(Self::auth_header(&session.token))
            .send()
            .map_err(|e| e.to_string())?;
        resp.json::<ItemsResponse>().map_err(|e| e.to_string())
    }

    pub fn get_item(&self, session: &Session, item_id: &str) -> Result<JellyItem, String> {
        let url = format!(
            "{}/Users/{}/Items/{}?Fields=Overview,UserData,Genres,People",
            session.server_url, session.user_id, item_id
        );
        let resp = self
            .client
            .get(&url)
            .headers(Self::auth_header(&session.token))
            .send()
            .map_err(|e| e.to_string())?;
        resp.json::<JellyItem>().map_err(|e| e.to_string())
    }
}
