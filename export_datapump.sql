-- Configuration du répertoire pour le datapump
CREATE OR REPLACE DIRECTORY PROD_DATAPUMP AS '/opt/oracle/backup';

-- Accorder les privilèges nécessaires
GRANT READ, WRITE ON DIRECTORY PROD_DATAPUMP TO SYSTEM;
GRANT DATAPUMP_EXP_FULL_DATABASE TO SYSTEM;
GRANT DATAPUMP_IMP_FULL_DATABASE TO SYSTEM;

-- Quitter la connexion
exit;
