-- Configuration du répertoire pour le datapump
CREATE OR REPLACE DIRECTORY PROD_DATAPUMP AS '/opt/oracle/backup';

-- Accorder les privilèges nécessaires
grant read,write on directory PROD_DATAPUMP to system;
grant datapump_exp_full_database to system;
grant datapump_imp_full_database to system;

-- Quitter la connexion
exit;
