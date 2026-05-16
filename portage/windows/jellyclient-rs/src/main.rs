#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod api;
mod image_cache;
mod player;

use api::{JellyfinClient, models::*};
use egui::{Color32, RichText, Ui, Vec2};
use image_cache::ImageCache;
use std::sync::mpsc::{channel, Receiver, Sender};

// ─── Palette ──────────────────────────────────────────────────────────────────
const BG:   Color32 = Color32::from_rgb(13, 13, 13);
const CARD: Color32 = Color32::from_rgb(26, 26, 26);
const RED:  Color32 = Color32::from_rgb(229, 9, 20);
const MUTED:Color32 = Color32::from_rgb(136, 136, 136);

// ─── Événements background ────────────────────────────────────────────────────
enum AppEvent {
    AuthOk(Session),
    AuthErr(String),
    Users(Vec<UserDto>),
    Libraries(Vec<JellyItem>),
    ResumeItems(Vec<JellyItem>),
    LatestItems(String, Vec<JellyItem>),
    LibraryItems(Vec<JellyItem>, usize),
    DetailItem(JellyItem),
    Error(String),
}

// ─── Navigation ───────────────────────────────────────────────────────────────
#[derive(Clone, Debug)]
enum Screen {
    Login,
    Profiles,
    Home,
    Library { id: String, name: String, page: usize },
    Detail(String),
}

// ─── App ──────────────────────────────────────────────────────────────────────
struct JellyClientApp {
    server_input:  String,
    user_input:    String,
    pass_input:    String,
    login_loading: bool,
    error_msg:     Option<String>,

    session:       Option<Session>,
    server_url:    String,  // URL du serveur (sans user connecté)
    server_token:  String,  // token admin pour lister les users
    server_uid:    String,  // userId de l'admin

    screen:        Screen,
    nav_stack:     Vec<Screen>,

    // Données
    server_users:  Vec<UserDto>,
    libraries:     Vec<JellyItem>,
    resume_items:  Vec<JellyItem>,
    latest_items:  std::collections::HashMap<String, Vec<JellyItem>>,
    library_items: Vec<JellyItem>,
    library_total: usize,
    detail_item:   Option<JellyItem>,

    tx:            Sender<AppEvent>,
    rx:            Receiver<AppEvent>,

    images:        ImageCache,
    player_path:   String,
    exe_dir:       String,
    loading:       bool,
}

impl JellyClientApp {
    fn new(cc: &eframe::CreationContext) -> Self {
        // Thème
        let mut v = egui::Visuals::dark();
        v.panel_fill                     = BG;
        v.window_fill                    = BG;
        v.override_text_color            = Some(Color32::WHITE);
        v.widgets.noninteractive.bg_fill = CARD;
        v.widgets.inactive.bg_fill       = CARD;
        v.widgets.hovered.bg_fill        = Color32::from_rgb(40, 40, 40);
        v.widgets.active.bg_fill         = RED;
        v.selection.bg_fill              = RED;
        cc.egui_ctx.set_visuals(v);

        let exe_dir = std::env::current_exe()
            .ok()
            .and_then(|p| p.parent().map(|d| d.to_string_lossy().into_owned()))
            .unwrap_or_default();
        let player_path = player::detect_player(&exe_dir);
        let (tx, rx)    = channel();

        Self {
            server_input:  Self::load_pref("server_url").unwrap_or_default(),
            user_input:    Self::load_pref("username").unwrap_or_default(),
            pass_input:    String::new(),
            login_loading: false,
            error_msg:     None,
            session:       None,
            server_url:    String::new(),
            server_token:  String::new(),
            server_uid:    String::new(),
            screen:        Screen::Login,
            nav_stack:     vec![],
            server_users:  vec![],
            libraries:     vec![],
            resume_items:  vec![],
            latest_items:  std::collections::HashMap::new(),
            library_items: vec![],
            library_total: 0,
            detail_item:   None,
            tx, rx,
            images:        ImageCache::new(),
            player_path,
            exe_dir,
            loading:       false,
        }
    }

    fn save_pref(k: &str, v: &str) {
        if let Ok(e) = keyring::Entry::new("jellyclient-rs", k) { let _ = e.set_password(v); }
    }
    fn load_pref(k: &str) -> Option<String> {
        keyring::Entry::new("jellyclient-rs", k).ok()?.get_password().ok()
    }

    fn navigate(&mut self, s: Screen) {
        self.nav_stack.push(self.screen.clone());
        self.screen = s;
    }
    fn back(&mut self) {
        if let Some(s) = self.nav_stack.pop() { self.screen = s; }
    }

    fn poll_events(&mut self) {
        while let Ok(ev) = self.rx.try_recv() {
            self.loading = false;
            self.login_loading = false;
            match ev {
                AppEvent::AuthOk(session) => {
                    // Sauvegarder l'URL serveur pour l'écran profils
                    self.server_url   = session.server_url.clone();
                    self.server_token = session.token.clone();
                    self.server_uid   = session.user_id.clone();
                    Self::save_pref("server_url", &session.server_url);
                    Self::save_pref("username",   &session.username);
                    self.session = Some(session);
                    // Charger les utilisateurs du serveur
                    self.load_users();
                    self.screen = Screen::Profiles;
                }
                AppEvent::AuthErr(e)  => { self.error_msg = Some(e); }
                AppEvent::Users(u)    => { self.server_users = u; }
                AppEvent::Libraries(l) => { self.libraries = l; }
                AppEvent::ResumeItems(i) => { self.resume_items = i; }
                AppEvent::LatestItems(id, i) => { self.latest_items.insert(id, i); }
                AppEvent::LibraryItems(i, t) => { self.library_items = i; self.library_total = t; }
                AppEvent::DetailItem(i) => { self.detail_item = Some(i); }
                AppEvent::Error(e) => { self.error_msg = Some(e); }
            }
        }
    }

    fn do_login(&mut self) {
        if self.server_input.is_empty() || self.user_input.is_empty() { return; }
        self.login_loading = true;
        self.error_msg     = None;

        let tx       = self.tx.clone();
        let url      = self.server_input.trim_end_matches('/').to_string();
        let username = self.user_input.clone();
        let password = self.pass_input.clone();

        std::thread::spawn(move || {
            let api = JellyfinClient::new();
            match api.authenticate(&url, &username, &password) {
                Ok(a) => tx.send(AppEvent::AuthOk(Session {
                    server_url: url, user_id: a.user.id,
                    token: a.access_token, username: a.user.name,
                })).unwrap(),
                Err(e) => tx.send(AppEvent::AuthErr(e)).unwrap(),
            }
        });
    }

    fn load_users(&mut self) {
        let Some(session) = self.session.clone() else { return };
        let tx = self.tx.clone();
        std::thread::spawn(move || {
            let api = JellyfinClient::new();
            if let Ok(users) = api.get_users(&session) {
                let _ = tx.send(AppEvent::Users(users));
            }
        });
    }

    fn switch_user(&mut self, user: &UserDto) {
        // Si on switche vers le même user que la session courante → go home directement
        if let Some(session) = &self.session {
            if session.user_id == user.id {
                self.screen = Screen::Home;
                self.load_home();
                return;
            }
        }
        // Sinon authentifier comme cet utilisateur (mot de passe vide = profil sans mdp)
        // Tentative avec mot de passe vide d'abord
        let tx       = self.tx.clone();
        let url      = self.server_url.clone();
        let username = user.name.clone();

        std::thread::spawn(move || {
            let api = JellyfinClient::new();
            match api.authenticate(&url, &username, "") {
                Ok(a) => tx.send(AppEvent::AuthOk(Session {
                    server_url: url, user_id: a.user.id,
                    token: a.access_token, username: a.user.name,
                })).unwrap(),
                Err(_) => {
                    // Profil avec mot de passe : signaler qu'il faut demander le mdp
                    tx.send(AppEvent::Error(
                        format!("Mot de passe requis pour {}", username)
                    )).unwrap()
                }
            }
        });
    }

    fn load_home(&mut self) {
        let Some(session) = self.session.clone() else { return };
        let tx = self.tx.clone();
        let s1 = session.clone();
        let s2 = session.clone();
        self.loading = true;

        std::thread::spawn(move || {
            let api = JellyfinClient::new();
            if let Ok(libs) = api.get_libraries(&s1) {
                for lib in &libs {
                    let tx3 = tx.clone();
                    let s3  = s1.clone();
                    let lid = lib.id.clone();
                    let a3  = JellyfinClient::new();
                    std::thread::spawn(move || {
                        if let Ok(items) = a3.get_latest(&s3, &lid) {
                            let _ = tx3.send(AppEvent::LatestItems(lid, items));
                        }
                    });
                }
                let _ = tx.send(AppEvent::Libraries(libs));
            }
        });
        std::thread::spawn(move || {
            let api = JellyfinClient::new();
            if let Ok(items) = api.get_resume(&s2) {
                let _ = tx.clone().send(AppEvent::ResumeItems(items));
            }
        });
    }

    fn load_library(&mut self, lib_id: &str, page: usize) {
        let Some(session) = self.session.clone() else { return };
        let tx  = self.tx.clone();
        let lid = lib_id.to_string();
        self.loading = true;
        std::thread::spawn(move || {
            let api = JellyfinClient::new();
            match api.get_items(&session, &lid, page * 50, 50) {
                Ok(r) => { let _ = tx.send(AppEvent::LibraryItems(r.items, r.total as usize)); }
                Err(e) => { let _ = tx.send(AppEvent::Error(e)); }
            }
        });
    }

    fn load_detail(&mut self, id: &str) {
        let Some(session) = self.session.clone() else { return };
        let tx  = self.tx.clone();
        let iid = id.to_string();
        std::thread::spawn(move || {
            let api = JellyfinClient::new();
            match api.get_item(&session, &iid) {
                Ok(i) => { let _ = tx.send(AppEvent::DetailItem(i)); }
                Err(e) => { let _ = tx.send(AppEvent::Error(e)); }
            }
        });
    }

    fn play(&self, item: &JellyItem) {
        let Some(s) = &self.session else { return };
        let url   = s.stream_url(&item.id);
        let start = item.user_data.as_ref()
            .and_then(|u| u.playback_position_ticks).unwrap_or(0);
        if let Err(e) = player::launch(&self.player_path, &url, start) {
            eprintln!("Lecteur : {}", e);
        }
    }

    // ── Carte media ──────────────────────────────────────────────────────────
    fn show_card(&mut self, ui: &mut Ui, item: &JellyItem, img_url: &str) -> bool {
        let w = 130.0f32;
        let h = 195.0f32;
        let (rect, resp) = ui.allocate_exact_size(Vec2::new(w, h), egui::Sense::click());

        if ui.is_rect_visible(rect) {
            ui.painter().rect_filled(rect, 8.0, CARD);

            // Image
            if let Some(tex) = self.images.get(img_url) {
                let uv   = egui::Rect::from_min_max(egui::pos2(0.0, 0.0), egui::pos2(1.0, 1.0));
                let tint = if resp.hovered() { Color32::from_rgb(200, 200, 200) } else { Color32::WHITE };
                ui.painter().image(tex.id(), rect, uv, tint);
            } else {
                // Placeholder pendant le chargement
                ui.painter().rect_filled(rect, 8.0, Color32::from_rgb(30, 30, 30));
                ui.painter().text(
                    rect.center(),
                    egui::Align2::CENTER_CENTER,
                    "⏳",
                    egui::FontId::proportional(20.0),
                    MUTED,
                );
            }

            // Gradient bas
            let grad = egui::Rect::from_min_size(
                egui::pos2(rect.min.x, rect.max.y - 65.0),
                Vec2::new(w, 65.0),
            );
            ui.painter().rect_filled(
                grad,
                egui::Rounding { sw: 8.0, se: 8.0, nw: 0.0, ne: 0.0 },
                Color32::from_rgba_unmultiplied(0, 0, 0, 210),
            );

            // Titre
            let galley = ui.painter().layout(
                item.name.clone(),
                egui::FontId::proportional(11.0),
                Color32::WHITE,
                w - 12.0,
            );
            ui.painter().galley(
                egui::pos2(rect.min.x + 6.0, rect.max.y - 8.0 - galley.size().y),
                galley,
                Color32::WHITE,
            );

            // Badge vu
            if item.is_played() {
                ui.painter().circle_filled(
                    egui::pos2(rect.max.x - 9.0, rect.min.y + 9.0),
                    6.0,
                    Color32::from_rgb(76, 175, 80),
                );
            }

            // Barre progression
            let pct = item.progress_pct();
            if pct > 0.01 {
                let bar_y = rect.max.y - 3.0;
                ui.painter().line_segment(
                    [egui::pos2(rect.min.x, bar_y), egui::pos2(rect.max.x, bar_y)],
                    egui::Stroke::new(3.0, Color32::from_rgba_unmultiplied(255, 255, 255, 50)),
                );
                ui.painter().line_segment(
                    [egui::pos2(rect.min.x, bar_y), egui::pos2(rect.min.x + w * pct, bar_y)],
                    egui::Stroke::new(3.0, RED),
                );
            }

            if resp.hovered() {
                ui.painter().rect_stroke(rect, 8.0, egui::Stroke::new(2.0, Color32::WHITE));
            }
        }
        resp.clicked()
    }
}

// ─── eframe::App ─────────────────────────────────────────────────────────────
impl eframe::App for JellyClientApp {
    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        self.poll_events();
        self.images.poll(ctx);
        ctx.request_repaint_after(std::time::Duration::from_millis(200));

        // Barre du haut
        egui::TopBottomPanel::top("top")
            .frame(egui::Frame::none().fill(Color32::from_rgb(10, 10, 10)).inner_margin(8.0))
            .show(ctx, |ui| {
                ui.horizontal(|ui| {
                    ui.label(RichText::new("JellyClient").color(RED).strong().size(18.0));
                    if let Some(s) = &self.session {
                        ui.label(RichText::new(format!("  {}", s.username)).color(MUTED).size(13.0));
                    }
                    ui.with_layout(egui::Layout::right_to_left(egui::Align::Center), |ui| {
                        if self.session.is_some() {
                            if !matches!(self.screen, Screen::Login | Screen::Profiles | Screen::Home) {
                                if ui.button("← Retour").clicked() { self.back(); }
                            }
                            if ui.button("👤 Profils").clicked() {
                                self.navigate(Screen::Profiles);
                            }
                        }
                    });
                });
            });

        egui::CentralPanel::default()
            .frame(egui::Frame::none().fill(BG).inner_margin(0.0))
            .show(ctx, |ui| {
                if let Some(err) = self.error_msg.clone() {
                    egui::Frame::none().fill(Color32::from_rgb(80, 0, 0)).inner_margin(8.0).show(ui, |ui| {
                        ui.horizontal(|ui| {
                            ui.label(RichText::new(format!("⚠ {}", err)).color(Color32::WHITE));
                            if ui.button("✕").clicked() { self.error_msg = None; }
                        });
                    });
                }

                let screen = self.screen.clone();
                match screen {
                    Screen::Login    => self.show_login(ui),
                    Screen::Profiles => self.show_profiles(ui),
                    Screen::Home     => self.show_home(ui),
                    Screen::Library { id, name, page } => self.show_library(ui, &id, &name, page),
                    Screen::Detail(id) => self.show_detail(ui, &id),
                }
            });
    }
}

// ─── Login ────────────────────────────────────────────────────────────────────
impl JellyClientApp {
    fn show_login(&mut self, ui: &mut Ui) {
        ui.vertical_centered(|ui| {
            ui.add_space(70.0);
            ui.label(RichText::new("JellyClient").size(44.0).strong().color(RED));
            ui.label(RichText::new("Client Jellyfin natif Windows").size(15.0).color(MUTED));
            ui.add_space(40.0);

            egui::Frame::none().fill(CARD).rounding(12.0).inner_margin(32.0).show(ui, |ui| {
                ui.set_min_width(360.0);
                ui.set_max_width(400.0);

                ui.label(RichText::new("URL du serveur").color(MUTED).size(12.0));
                ui.add_space(4.0);
                ui.add(egui::TextEdit::singleline(&mut self.server_input)
                    .hint_text("https://streaming.votreserveur.com")
                    .min_size(Vec2::new(340.0, 36.0)));
                ui.add_space(14.0);

                ui.label(RichText::new("Nom d'utilisateur").color(MUTED).size(12.0));
                ui.add_space(4.0);
                ui.add(egui::TextEdit::singleline(&mut self.user_input)
                    .hint_text("admin")
                    .min_size(Vec2::new(340.0, 36.0)));
                ui.add_space(14.0);

                ui.label(RichText::new("Mot de passe").color(MUTED).size(12.0));
                ui.add_space(4.0);
                let pw = ui.add(egui::TextEdit::singleline(&mut self.pass_input)
                    .password(true).hint_text("••••••••").min_size(Vec2::new(340.0, 36.0)));
                if pw.lost_focus() && ui.input(|i| i.key_pressed(egui::Key::Enter)) {
                    self.do_login();
                }
                ui.add_space(22.0);

                let label = if self.login_loading { "Connexion…" } else { "Se connecter" };
                let btn   = egui::Button::new(RichText::new(label).strong().size(15.0).color(Color32::BLACK))
                    .fill(Color32::WHITE).min_size(Vec2::new(340.0, 44.0)).rounding(8.0);
                if ui.add_enabled(!self.login_loading, btn).clicked() { self.do_login(); }
            });
        });
    }
}

// ─── Profils ──────────────────────────────────────────────────────────────────
impl JellyClientApp {
    fn show_profiles(&mut self, ui: &mut Ui) {
        let Some(session) = self.session.clone() else { return };

        ui.vertical_centered(|ui| {
            ui.add_space(48.0);
            ui.label(RichText::new("Qui regarde ?").size(30.0).strong());
            ui.add_space(8.0);
            ui.label(RichText::new(&session.server_url).size(12.0).color(MUTED));
            ui.add_space(36.0);

            if self.server_users.is_empty() {
                ui.spinner();
                ui.label(RichText::new("Chargement des profils…").color(MUTED));
            } else {
                let users = self.server_users.clone();
                let cols  = (users.len().min(5)).max(1);

                ui.horizontal(|ui| {
                    // Centrer la grille
                    let card_w  = 110.0f32;
                    let total_w = cols as f32 * card_w + (cols - 1) as f32 * 20.0;
                    let margin  = ((ui.available_width() - total_w) / 2.0).max(0.0);
                    ui.add_space(margin);

                    for user in &users {
                        let is_active = session.user_id == user.id;
                        let avatar_url = format!(
                            "{}/Users/{}/Images/Primary?maxWidth=200&api_key={}",
                            session.server_url, user.id, session.token
                        );

                        ui.vertical(|ui| {
                            ui.set_min_width(card_w);
                            ui.set_max_width(card_w);

                            // Avatar
                            let av_rect = ui.allocate_exact_size(
                                Vec2::new(90.0, 90.0), egui::Sense::click()
                            );
                            let (av_r, av_resp) = av_rect;

                            if ui.is_rect_visible(av_r) {
                                // Bordure si utilisateur actif
                                if is_active {
                                    ui.painter().rect_stroke(
                                        av_r.expand(3.0), 12.0,
                                        egui::Stroke::new(3.0, Color32::WHITE),
                                    );
                                }

                                if let Some(tex) = self.images.get(&avatar_url) {
                                    let uv = egui::Rect::from_min_max(egui::pos2(0.0, 0.0), egui::pos2(1.0, 1.0));
                                    ui.painter().image(tex.id(), av_r, uv, Color32::WHITE);
                                } else {
                                    // Initiale colorée
                                    let c = user_color(&user.name);
                                    ui.painter().rect_filled(av_r, 10.0, c);
                                    let ch = user.name.chars().next().unwrap_or('?').to_uppercase().to_string();
                                    ui.painter().text(av_r.center(), egui::Align2::CENTER_CENTER,
                                        ch, egui::FontId::proportional(36.0), Color32::WHITE);
                                }

                                // Point rouge si actif
                                if is_active {
                                    ui.painter().circle_filled(
                                        egui::pos2(av_r.center().x, av_r.max.y + 6.0),
                                        5.0, RED,
                                    );
                                }
                            }

                            if av_resp.clicked() {
                                let u = user.clone();
                                self.switch_user(&u);
                            }

                            ui.add_space(8.0);
                            ui.label(RichText::new(&user.name)
                                .size(13.0)
                                .strong_if(is_active)
                                .color(if is_active { Color32::WHITE } else { Color32::from_gray(180) }));
                        });
                        ui.add_space(20.0);
                    }
                });

                ui.add_space(32.0);

                // Bouton continuer avec le compte actuel
                let btn = egui::Button::new(
                    RichText::new(format!("Continuer en tant que {}", session.username))
                        .strong().size(14.0).color(Color32::BLACK)
                ).fill(Color32::WHITE).min_size(Vec2::new(300.0, 40.0)).rounding(8.0);
                if ui.add(btn).clicked() {
                    self.screen = Screen::Home;
                    self.load_home();
                }

                ui.add_space(12.0);
                if ui.button(RichText::new("← Changer de serveur").color(MUTED).size(13.0)).clicked() {
                    self.session = None;
                    self.screen  = Screen::Login;
                }
            }
        });
    }
}

fn user_color(name: &str) -> Color32 {
    let colors = [
        Color32::from_rgb(21, 101, 192),
        Color32::from_rgb(46, 125, 50),
        Color32::from_rgb(106, 27, 154),
        Color32::from_rgb(173, 20, 87),
        Color32::from_rgb(0, 105, 92),
        Color32::from_rgb(230, 81, 0),
    ];
    let idx = name.bytes().fold(0usize, |a, b| a.wrapping_add(b as usize));
    colors[idx % colors.len()]
}

// ─── Home ─────────────────────────────────────────────────────────────────────
impl JellyClientApp {
    fn show_home(&mut self, ui: &mut Ui) {
        let Some(session) = self.session.clone() else { return };

        egui::ScrollArea::vertical().show(ui, |ui| {
            ui.add_space(16.0);

            // Bibliothèques
            if !self.libraries.is_empty() {
                ui.label(RichText::new("Bibliothèques").size(20.0).strong());
                ui.add_space(10.0);
                ui.horizontal_wrapped(|ui| {
                    let libs = self.libraries.clone();
                    for lib in &libs {
                        if ui.add(egui::Button::new(RichText::new(&lib.name).strong())
                            .fill(CARD).rounding(8.0).min_size(Vec2::new(140.0, 44.0))).clicked() {
                            let id   = lib.id.clone();
                            let name = lib.name.clone();
                            self.navigate(Screen::Library { id: id.clone(), name, page: 0 });
                            self.load_library(&id, 0);
                        }
                    }
                });
                ui.add_space(24.0);
            }

            // Continuer à regarder
            if !self.resume_items.is_empty() {
                let items = self.resume_items.clone();
                self.show_rail(ui, &session, "Continuer à regarder", &items);
                ui.add_space(24.0);
            }

            // Récents par bibliothèque
            let libs = self.libraries.clone();
            for lib in &libs {
                if let Some(items) = self.latest_items.get(&lib.id).cloned() {
                    if !items.is_empty() {
                        let title = format!("Récents — {}", lib.name);
                        self.show_rail(ui, &session, &title, &items);
                        ui.add_space(24.0);
                    }
                }
            }

            if self.loading && self.libraries.is_empty() {
                ui.vertical_centered(|ui| {
                    ui.add_space(60.0);
                    ui.spinner();
                    ui.label(RichText::new("Chargement…").color(MUTED));
                });
            }
        });
    }

    fn show_rail(&mut self, ui: &mut Ui, session: &Session, title: &str, items: &[JellyItem]) {
        ui.label(RichText::new(title).size(20.0).strong());
        ui.add_space(10.0);
        egui::ScrollArea::horizontal().id_source(title).show(ui, |ui| {
            ui.horizontal(|ui| {
                ui.spacing_mut().item_spacing = Vec2::new(10.0, 0.0);
                let items = items.to_vec();
                for item in items.iter().take(16) {
                    let img = session.image_url(&item.id, "Primary", 200);
                    let item2 = item.clone();
                    if self.show_card(ui, item, &img) {
                        let id = item2.id.clone();
                        self.navigate(Screen::Detail(id.clone()));
                        self.load_detail(&id);
                    }
                }
            });
        });
    }
}

// ─── Bibliothèque ─────────────────────────────────────────────────────────────
impl JellyClientApp {
    fn show_library(&mut self, ui: &mut Ui, lib_id: &str, lib_name: &str, page: usize) {
        let Some(session) = self.session.clone() else { return };

        ui.add_space(8.0);
        ui.horizontal(|ui| {
            ui.label(RichText::new(lib_name).size(22.0).strong());
            ui.with_layout(egui::Layout::right_to_left(egui::Align::Center), |ui| {
                ui.label(RichText::new(format!("{} médias", self.library_total)).color(MUTED));
            });
        });
        ui.add_space(12.0);

        if self.loading { ui.vertical_centered(|ui| { ui.spinner(); }); return; }

        let cols = ((ui.available_width() / 150.0) as usize).max(3).min(10);

        egui::ScrollArea::vertical().show(ui, |ui| {
            let items = self.library_items.clone();
            egui::Grid::new("lib_grid").num_columns(cols).spacing(Vec2::new(10.0, 10.0)).show(ui, |ui| {
                for (i, item) in items.iter().enumerate() {
                    let img = session.image_url(&item.id, "Primary", 220);
                    let item2 = item.clone();
                    if self.show_card(ui, item, &img) {
                        let id = item2.id.clone();
                        self.navigate(Screen::Detail(id.clone()));
                        self.load_detail(&id);
                    }
                    if (i + 1) % cols == 0 { ui.end_row(); }
                }
            });

            // Pagination
            if self.library_total > 50 {
                ui.add_space(16.0);
                ui.horizontal(|ui| {
                    let lid = lib_id.to_string();
                    let nam = lib_name.to_string();
                    if page > 0 && ui.button("← Précédent").clicked() {
                        self.screen = Screen::Library { id: lid.clone(), name: nam.clone(), page: page - 1 };
                        self.load_library(&lid, page - 1);
                    }
                    ui.label(format!("Page {} / {}", page + 1, (self.library_total + 49) / 50));
                    if (page + 1) * 50 < self.library_total && ui.button("Suivant →").clicked() {
                        self.screen = Screen::Library { id: lid.clone(), name: nam.clone(), page: page + 1 };
                        self.load_library(&lid, page + 1);
                    }
                });
            }
        });
    }
}

// ─── Détail ───────────────────────────────────────────────────────────────────
impl JellyClientApp {
    fn show_detail(&mut self, ui: &mut Ui, item_id: &str) {
        let Some(session) = self.session.clone() else { return };
        let Some(item) = self.detail_item.clone() else {
            ui.vertical_centered(|ui| { ui.add_space(60.0); ui.spinner(); });
            return;
        };
        if item.id != item_id {
            ui.vertical_centered(|ui| { ui.spinner(); });
            return;
        }

        egui::ScrollArea::vertical().show(ui, |ui| {
            // Backdrop
            let bk_url = session.image_url(&item.id, "Backdrop", 1280);
            let bk_h   = 240.0f32;
            let bk_rect = ui.allocate_exact_size(Vec2::new(ui.available_width(), bk_h), egui::Sense::hover()).0;
            if let Some(tex) = self.images.get(&bk_url) {
                let uv = egui::Rect::from_min_max(egui::pos2(0.0, 0.0), egui::pos2(1.0, 1.0));
                ui.painter().image(tex.id(), bk_rect, uv, Color32::WHITE);
            } else {
                ui.painter().rect_filled(bk_rect, 0.0, Color32::from_rgb(20, 20, 20));
            }
            // Gradient sur le backdrop
            ui.painter().rect_filled(
                egui::Rect::from_min_size(egui::pos2(bk_rect.min.x, bk_rect.max.y - 80.0), Vec2::new(bk_rect.width(), 80.0)),
                0.0, Color32::from_rgba_unmultiplied(13, 13, 13, 220),
            );

            ui.add_space(12.0);
            ui.horizontal_top(|ui| {
                ui.add_space(16.0);
                // Poster
                let po_url  = session.image_url(&item.id, "Primary", 300);
                let po_rect = ui.allocate_exact_size(Vec2::new(130.0, 195.0), egui::Sense::hover()).0;
                if let Some(tex) = self.images.get(&po_url) {
                    let uv = egui::Rect::from_min_max(egui::pos2(0.0,0.0), egui::pos2(1.0,1.0));
                    ui.painter().image(tex.id(), po_rect, uv, Color32::WHITE);
                } else {
                    ui.painter().rect_filled(po_rect, 8.0, CARD);
                }

                ui.add_space(16.0);
                ui.vertical(|ui| {
                    ui.label(RichText::new(&item.name).size(26.0).strong());
                    ui.add_space(6.0);
                    ui.horizontal(|ui| {
                        if let Some(y) = item.production_year {
                            ui.label(RichText::new(y.to_string()).color(MUTED).size(13.0));
                        }
                        if let Some(r) = item.community_rating {
                            ui.label(RichText::new(format!("  ★ {:.1}", r)).color(Color32::from_rgb(255, 184, 0)).size(13.0));
                        }
                        if let Some(t) = item.run_time_ticks {
                            let m = t / 600_000_000;
                            ui.label(RichText::new(format!("  {}h {}min", m/60, m%60)).color(MUTED).size(13.0));
                        }
                    });
                    ui.add_space(18.0);

                    let has_prog = item.user_data.as_ref()
                        .and_then(|u| u.playback_position_ticks).unwrap_or(0) > 0;
                    let lbl = if has_prog { "▶  Reprendre" } else { "▶  Lire" };
                    let play_btn = egui::Button::new(RichText::new(lbl).strong().size(15.0).color(Color32::BLACK))
                        .fill(Color32::WHITE).min_size(Vec2::new(180.0, 42.0)).rounding(8.0);
                    if ui.add(play_btn).clicked() {
                        self.play(&item);
                    }
                });
            });

            if let Some(ov) = &item.overview {
                if !ov.is_empty() {
                    ui.add_space(16.0);
                    ui.add(egui::Separator::default());
                    ui.add_space(10.0);
                    ui.label(RichText::new("Synopsis").size(18.0).strong());
                    ui.add_space(6.0);
                    ui.label(RichText::new(ov).size(14.0).color(Color32::from_gray(200)));
                }
            }
        });
    }
}

// ─── main ─────────────────────────────────────────────────────────────────────
fn main() -> eframe::Result<()> {
    let icon = eframe::icon_data::from_png_bytes(include_bytes!("../assets/icon.png"))
        .unwrap_or_default();

    eframe::run_native(
        "JellyClient",
        eframe::NativeOptions {
            viewport: egui::ViewportBuilder::default()
                .with_title("JellyClient")
                .with_inner_size([1280.0, 720.0])
                .with_min_inner_size([800.0, 500.0])
                .with_icon(icon),
            ..Default::default()
        },
        Box::new(|cc| Ok(Box::new(JellyClientApp::new(cc)))),
    )
}

// ─── Extensions RichText ──────────────────────────────────────────────────────
trait RichTextExt {
    fn strong_if(self, cond: bool) -> Self;
}
impl RichTextExt for RichText {
    fn strong_if(self, cond: bool) -> Self {
        if cond { self.strong() } else { self }
    }
}
