#!/bin/bash

# Rechargement de du fichier .bash_profile
source ${HOME}/.bash_profile

# Identifiants de connexion
ORACLE_USER="system"
ORACLE_PASSWORD="manager"
PDB_NAME="XEPDB1"
HOSTNAME=$(hostname)
SSH_PORT="1521"
SERVICE_NAME="XEPDB1"

# Configuration du paramètre NLS_LANG
NLS_LANG="FRENCH_FRANCE.WE8MSWIN1252"

# Emplacement du fichier de journalisation
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

# Fonction pour exécuter une commande en tant qu'utilisateur oracle
run_as_oracle() {
    local command="$1"
    result=$(su oracle -c "${command}" 2>&1)
    local exit_code=$?
    if [[ ${exit_code} -ne 0 ]]; then
        log_error_and_exit "Échec de la commande : ${command}. Sortie : ${result}"
    fi
    echo "${result}"
}

# Fonction pour redémarrer le listener
restart_listener() {
    log_message "Arrêt du listener..."
    run_as_oracle "lsnrctl stop" > /dev/null

    log_message "Démarrage du listener..."
    run_as_oracle "lsnrctl start" > /dev/null
}

check_listener(){   
    log_message "Vérification du statut du listener..."
    status=$(run_as_oracle "lsnrctl status")

    # Vérifier la présence de "Services Summary" et "READY" dans la sortie
    if echo "${status}" | grep -q "Services Summary"; then
        if echo "${status}" | grep -q "READY"; then
            log_message "Le listener est actif et les services sont prêts."
        else
            log_error_and_exit "Le listener est actif mais aucun service n'est prêt."
        fi
    else
        log_error_and_exit "Le listener ne semble pas fonctionner correctement."
    fi
}

# Fonction pour tester la connexion avec tnsping
test_tnsping() {
    log_message "Test de la connexion au listener avec tnsping..."
    result=$(tnsping ${SERVICE_NAME} 2>&1)
    if echo "${result}" | grep -q "OK"; then
        log_message "tnsping réussi."
    else
        log_error_and_exit "Échec de tnsping. Sortie : ${result}"
    fi
}

# Fonction pour tester la connexion à la base de données
test_connection() {
    log_message "Vérification de la connexion à la base de données Oracle..."
    export NLS_LANG=${NLS_LANG}
    log_message "Tentative de connexion à la base de données ${PDB_NAME}..."
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
    
    # Redémarrer le listener
    restart_listener

    # Attendre le redémarrage du Listener
    sleep 12

    # Tester la connexion au listener avec tnsping
    test_tnsping

    # Attendre que le Listener soit en écoute 
    sleep 50

    # Vérifier le status du listener
    check_listener

    # Tester la connexion à la base de données
    test_connection

    log_message "Redémarrage du Listener effectué avec succès sur le serveur ${HOSTNAME}."
}

# Exécuter la fonction principale
main
