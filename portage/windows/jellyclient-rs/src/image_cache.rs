/// Cache d'images — télécharge via reqwest (HTTPS natif Windows), convertit en textures egui.
use std::collections::{HashMap, HashSet};
use std::sync::mpsc::{channel, Receiver, Sender};
use egui::{ColorImage, Context, TextureHandle, TextureOptions};

pub struct ImageCache {
    textures: HashMap<String, TextureHandle>,
    pending:  HashSet<String>,
    failed:   HashSet<String>,
    tx:       Sender<(String, Option<ColorImage>)>,
    rx:       Receiver<(String, Option<ColorImage>)>,
}

impl ImageCache {
    pub fn new() -> Self {
        let (tx, rx) = channel();
        Self {
            textures: HashMap::new(),
            pending:  HashSet::new(),
            failed:   HashSet::new(),
            tx,
            rx,
        }
    }

    /// Appeler chaque frame pour intégrer les images téléchargées
    pub fn poll(&mut self, ctx: &Context) {
        while let Ok((url, maybe_img)) = self.rx.try_recv() {
            self.pending.remove(&url);
            match maybe_img {
                Some(img) => {
                    let tex = ctx.load_texture(&url, img, TextureOptions::LINEAR);
                    self.textures.insert(url, tex);
                }
                None => { self.failed.insert(url); }
            }
        }
    }

    /// Retourne la texture si disponible, lance le téléchargement sinon.
    pub fn get(&mut self, url: &str) -> Option<&TextureHandle> {
        if self.textures.contains_key(url) {
            return self.textures.get(url);
        }
        if !self.pending.contains(url) && !self.failed.contains(url) {
            self.pending.insert(url.to_string());
            let tx  = self.tx.clone();
            let url = url.to_string();
            std::thread::spawn(move || {
                let result = download_image(&url);
                let _ = tx.send((url, result));
            });
        }
        None
    }

    pub fn clear(&mut self) {
        self.textures.clear();
        self.pending.clear();
        self.failed.clear();
    }
}

fn download_image(url: &str) -> Option<ColorImage> {
    let bytes = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(10))
        .build()
        .ok()?
        .get(url)
        .send()
        .ok()?
        .bytes()
        .ok()?;

    let img   = image::load_from_memory(&bytes).ok()?;
    let rgba  = img.to_rgba8();
    let (w, h) = rgba.dimensions();
    Some(ColorImage::from_rgba_unmultiplied(
        [w as usize, h as usize],
        &rgba,
    ))
}
