-- Configuration du répertoire pour le datapump
CREATE OR REPLACE DIRECTORY OPERIS_DATAPUMP AS '/opt/oracle/backup';

-- Accorder les privilèges nécessaires
grant read,write on directory PROD_DATAPUMP to system;
grant datapump_exp_full_database to system;
grant datapump_imp_full_database to system;

-- Vérifier la configuration du datapump
SELECT directory_path FROM dba_directories WHERE directory_name='PROD_DATAPUMP';

-- Quitter la connexion
exit;
