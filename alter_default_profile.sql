-- Modifier les paramètres de sécurité du profil par défaut des utilisateurs
ALTER PROFILE DEFAULT LIMIT FAILED_LOGIN_ATTEMPTS UNLIMITED PASSWORD_LIFE_TIME UNLIMITED;

-- Quitter la connexion
exit;
