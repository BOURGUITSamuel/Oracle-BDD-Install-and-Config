-- Modifier les paramètres de sécurité du profil par défaut des utilisateurs
alter profile default limit failed_login_attempts unlimited password_life_time unlimited;

-- Quitter la connexion
exit;
