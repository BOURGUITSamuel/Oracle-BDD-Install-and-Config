#!/bin/bash

# Rechargement de du fichier .bash_profile
source ${HOME}/.bash_profile

# Identifiants de connexion
ORACLE_USER="system"
ORACLE_PASSWORD="manager"
PDB_NAME="XEPDB1"
HOST_NAME=$(hostname)
SSH_PORT="1521"
SERVICE_NAME="XEPDB1"

# Configuration du paramètre NLS_LANG
NLS_LANG="FRENCH_FRANCE.WE8MSWIN1252"

LOG_FILE="/var/log/restart_listener.log"

# Fonction pour afficher un message dans le journal et à l'écran
log_message() {
    local message="$1"
    echo "$(date +"%Y-%m-%d %H:%M:%S") - ${message}" | tee -a "${LOG_FILE}"
}

# Fonction pour afficher un message d'erreur dans le journal et quitter
log_error_and_exit() {
    local error_message="$1"
    log_message "Erreur : ${error_message}"
    exit 1
}

# Fonction pour redémarrer le listener et vérifier son statut
restart_listener() {
    log_message "Redémarrage du listener..."
    su oracle -c "lsnrctl stop"
    su oracle -c "lsnrctl start"
    log_message "Vérification du statut du listener..."
    su oracle -c "lsnrctl status"
}

# Fonction pour tester la connexion avec tnsping
test_tnsping() {
    log_message "Test de la connexion au listener avec tnsping..."
    result=$(tnsping ${SERVICE_NAME})
    if [[ "$result" == *"OK"* ]]; then
        log_message "tnsping réussi."
    else
        log_error_and_exit "Échec de tnsping. Veuillez vérifier les paramètres du listener."
    fi
}

# Fonction pour tester la connexion à la base de données
test_connection() {
    log_message "Vérification de la connexion à la base de données Oracle..."
    # Export du NLS_LANG
    export NLS_LANG=${NLS_LANG}
    log_message "Tentative de connexion à la base de données ${PDB_NAME}..."
    # Tentative de connexion avec sqlplus et exécution d'une requête simple
    result=$(sqlplus -s /nolog <<EOF
connect ${ORACLE_USER}/${ORACLE_PASSWORD}@${PDB_NAME}
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
SELECT 'Connexion réussie.' FROM DUAL;
EOF
)
    # Comparer le résultat avec la sortie de la requête SQL
    if [[ "${result}" == "Connexion réussie." ]]; then
        log_message "Connexion à la base de données Oracle réussie."
    else
        log_error_and_exit "Échec de la connexion à la base de données Oracle. Veuillez vérifier les paramètres et l'état du service."
    fi
}

# Fonction principale
main() {
    
    # Redémarrer le listener et vérifier son statut
    restart_listener

    # Attendre le redémarrage du Listener
    sleep 12

    # Tester la connexion au listener avec tnsping
    test_tnsping

    # Attendre que le Listener soit en écoute 
    sleep 50

    # Tester la connexion à la base de données
    test_connection

    log_message "Redémarrage du Listener effectué avec succès."
}

# Exécuter la fonction principale
main
