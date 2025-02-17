-- Basculer vers la PDB directement depuis la CDB
ALTER SESSION SET CONTAINER = XEPDB1;

-- Arrêter la PDB
ALTER PLUGGABLE DATABASE XEPDB1 CLOSE IMMEDIATE;

-- Ouvrir la PDB en mode restrictif
ALTER PLUGGABLE DATABASE XEPDB1 OPEN RESTRICTED;

-- Changer le jeu de caractères
ALTER DATABASE CHARACTER SET INTERNAL_USE WE8MSWIN1252;

-- Fermer et ouvrir la PDB pour appliquer les modifications
ALTER PLUGGABLE DATABASE XEPDB1 CLOSE IMMEDIATE;
ALTER PLUGGABLE DATABASE XEPDB1 OPEN;

-- Quitter la connexion
exit;
