use std::path::Path;
use std::process::Command;

#[cfg(windows)]
use std::os::windows::process::CommandExt;

/// Détecte le lecteur disponible (VLC portable > installé > fallback)
pub fn detect_player(exe_dir: &str) -> String {
    // 1. VLC portable bundlé à côté de l'exe
    let bundled = format!(r"{}\vlc\vlc.exe", exe_dir);
    if Path::new(&bundled).exists() {
        return bundled;
    }

    // 2. Installations Windows standard
    for path in &[
        r"C:\Program Files\VideoLAN\VLC\vlc.exe",
        r"C:\Program Files (x86)\VideoLAN\VLC\vlc.exe",
    ] {
        if Path::new(path).exists() {
            return path.to_string();
        }
    }

    // 3. Fallback PATH
    "vlc".to_string()
}

pub fn launch(player: &str, url: &str, start_ticks: i64) -> Result<(), String> {
    let start_secs = start_ticks / 10_000_000;

    let mut args: Vec<String> = vec![url.to_string()];

    let name = Path::new(player)
        .file_name()
        .and_then(|n| n.to_str())
        .unwrap_or("")
        .to_lowercase();

    if name.contains("vlc") {
        args.push("--fullscreen".into());
        args.push("--sub-track=-1".into());
        if start_secs > 0 {
            args.push(format!("--start-time={}", start_secs));
        }
    } else if name.contains("mpv") {
        args.push("--fs".into());
        args.push("--no-sub".into());
        args.push("--hwdec=no".into());
        if start_secs > 0 {
            args.push(format!("--start={}", start_secs));
        }
    }

    #[cfg(windows)]
    {
        Command::new(player)
            .args(&args)
            .creation_flags(0x00000008) // DETACHED_PROCESS
            .spawn()
            .map_err(|e| format!("Impossible de lancer '{}' : {}", player, e))?;
    }
    #[cfg(not(windows))]
    {
        Command::new(player)
            .args(&args)
            .spawn()
            .map_err(|e| format!("Impossible de lancer '{}' : {}", player, e))?;
    }

    Ok(())
}

/// Ouvre une URL dans le navigateur par défaut
pub fn open_url(url: &str) {
    #[cfg(windows)]
    {
        let _ = Command::new("cmd").args(["/c", "start", "", url]).spawn();
    }
    #[cfg(target_os = "linux")]
    {
        let _ = Command::new("xdg-open").arg(url).spawn();
    }
    #[cfg(target_os = "macos")]
    {
        let _ = Command::new("open").arg(url).spawn();
    }
}
