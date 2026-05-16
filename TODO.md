# JellyClient — TODO

> Les TODO par plateforme sont dans les fichiers dédiés :
> - **`LINUX.md`** (section "Ce qui reste à faire") — 2 items (card hover élargie, palette_generator)
> - **`WINDOWS.md`** (section "Checklist de test") — portage à compiler + 4 adaptations à tester

## Résumé

### Linux
- [ ] Card hover élargie (scale + popup débordant, style Netflix desktop)
- [ ] Remplacer `palette_generator` (discontinued)

### Windows
- [ ] Adapter `platform_utils.dart` : `xdg-open` → `cmd /c start <url>`
- [ ] Tester `ProcessStartMode.normal` (VLC survit-il à la fermeture de l'app ?)
- [ ] Tester `flutter_secure_storage` (tokens persistent via Credential Manager ?)
- [ ] Tester instance unique (PID lock sur `%APPDATA%`)
- [ ] Compiler sur PC Windows avec VS2022 et valider la checklist `WINDOWS.md`
