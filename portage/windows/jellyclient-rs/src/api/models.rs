use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AuthResult {
    #[serde(rename = "AccessToken")]
    pub access_token: String,
    #[serde(rename = "ServerId")]
    pub server_id: String,
    #[serde(rename = "User")]
    pub user: UserDto,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserDto {
    #[serde(rename = "Id")]
    pub id: String,
    #[serde(rename = "Name")]
    pub name: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ItemsResponse {
    #[serde(rename = "Items")]
    pub items: Vec<JellyItem>,
    #[serde(rename = "TotalRecordCount")]
    pub total: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct JellyItem {
    #[serde(rename = "Id")]
    pub id: String,
    #[serde(rename = "Name")]
    pub name: String,
    #[serde(rename = "Type")]
    pub item_type: Option<String>,
    #[serde(rename = "Overview")]
    pub overview: Option<String>,
    #[serde(rename = "ProductionYear")]
    pub production_year: Option<i32>,
    #[serde(rename = "CommunityRating")]
    pub community_rating: Option<f32>,
    #[serde(rename = "RunTimeTicks")]
    pub run_time_ticks: Option<i64>,
    #[serde(rename = "CollectionType")]
    pub collection_type: Option<String>,
    #[serde(rename = "SeriesId")]
    pub series_id: Option<String>,
    #[serde(rename = "SeriesName")]
    pub series_name: Option<String>,
    #[serde(rename = "UserData")]
    pub user_data: Option<UserData>,
}

impl JellyItem {
    pub fn is_series(&self) -> bool {
        self.item_type.as_deref() == Some("Series")
    }
    pub fn progress_pct(&self) -> f32 {
        self.user_data
            .as_ref()
            .and_then(|u| u.played_percentage)
            .unwrap_or(0.0) as f32
            / 100.0
    }
    pub fn is_played(&self) -> bool {
        self.user_data.as_ref().map(|u| u.played).unwrap_or(false)
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserData {
    #[serde(rename = "Played")]
    pub played: bool,
    #[serde(rename = "PlaybackPositionTicks")]
    pub playback_position_ticks: Option<i64>,
    #[serde(rename = "PlayedPercentage")]
    pub played_percentage: Option<f64>,
    #[serde(rename = "UnplayedItemCount")]
    pub unplayed_item_count: Option<i32>,
}

/// Session active après authentification
#[derive(Debug, Clone)]
pub struct Session {
    pub server_url: String,
    pub user_id: String,
    pub token: String,
    pub username: String,
}

impl Session {
    pub fn image_url(&self, item_id: &str, image_type: &str, max_width: u32) -> String {
        format!(
            "{}/Items/{}/Images/{}?maxWidth={}&quality=80&api_key={}",
            self.server_url, item_id, image_type, max_width, self.token
        )
    }

    pub fn stream_url(&self, item_id: &str) -> String {
        format!(
            "{}/Videos/{}/stream?Static=true&MediaSourceId={}&DeviceId=jellyclient-rs&api_key={}",
            self.server_url, item_id, item_id, self.token
        )
    }
}
