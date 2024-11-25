#!/bin/bash

# Emplacement du fichier de journalisation
LOG_FILE="/var/log/alter_default_profile.log"

# Emplacement du fichier .bash_profile
BASH_PROFILE="${HOME}/.bash_profile"

# Configuration des identifiants de connexion
ORACLE_USER="sys"
ORACLE_PASSWORD="manager"
HOST="localhost"
SSH_PORT="1521"

# Configuration du fichier SQL à exécuter
ALTER_PROFILE_SQL_FILE="/tmp/alter_default_profile.sql"

# Fonction pour afficher un message dans le journal et à l'écran
log_message() {
    local message="$1"
    echo "$(date +"%Y-%m-%d %H:%M:%S") - ${message}" | tee -a "${LOG_FILE}"
}

# Fonction pour afficher un message d'erreur dans le journal et quitter
log_error() {
    local error_message="$1"
    log_message "Erreur : ${error_message}"
    exit 1
}

# Fonction pour modifier le profil utilisateur pour une instance Oracle spécifique
modify_profile() {
    local ORACLE_SID="$1"
    log_message "Modification du profil utilisateur pour l'instance ${ORACLE_SID}..."

    # Exécution du fichier SQL pour modifier le profil utilisateur
    sqlplus_output=$(sqlplus "${ORACLE_USER}/${ORACLE_PASSWORD}@${HOST}:${SSH_PORT}/${ORACLE_SID}" as sysdba @"${ALTER_PROFILE_SQL_FILE}" 2>&1)
    sqlplus_exit_code=$?

    # Vérification de l'exécution du fichier SQL
    if [ ${sqlplus_exit_code} -ne 0 ]; then
        log_message "Erreur SQL*Plus : ${sqlplus_output}"
        log_error "Échec de l'exécution du fichier SQL. Consultez le fichier de log pour plus de détails."
    else
        log_message "Le fichier SQL a été exécuté avec succès pour l'instance ${ORACLE_SID}. Le profil a été modifié."
    fi
}

# Fonction pour vérifier la modification du profil pour une instance Oracle spécifique
check_profile_modification() {
    local ORACLE_USER="system"
    local ORACLE_SID="$1"

    log_message "Vérification de la modification du profil pour l'instance ${ORACLE_SID}..."

    # Commandes pour vérifier les paramètres FAILED_LOGIN_ATTEMPTS et PASSWORD_LIFE_TIME
    failed_login_attempts=$(sqlplus -s ${ORACLE_USER}/${ORACLE_PASSWORD}@${HOST}:${SSH_PORT}/${ORACLE_SID} <<EOF
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
select LIMIT from dba_profiles where PROFILE='DEFAULT' and RESOURCE_NAME='FAILED_LOGIN_ATTEMPTS';
EOF
)

    password_life_time=$(sqlplus -s ${ORACLE_USER}/${ORACLE_PASSWORD}@${HOST}:${SSH_PORT}/${ORACLE_SID} <<EOF
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
select LIMIT from dba_profiles where PROFILE='DEFAULT' and RESOURCE_NAME='PASSWORD_LIFE_TIME';
EOF
)

    # Vérification des résultats
    if [[ "${failed_login_attempts}" == "UNLIMITED" ]] && [[ "${password_life_time}" == "UNLIMITED" ]]; then
        log_message "Le profil a été correctement modifié pour l'instance ${ORACLE_SID} :"
        log_message "FAILED_LOGIN_ATTEMPTS est défini à : ${failed_login_attempts}"
        log_message "PASSWORD_LIFE_TIME est défini à : ${password_life_time}"
        return 0
    else
        log_message "Le profil n'a pas été correctement modifié pour l'instance ${ORACLE_SID} :"
        log_message "FAILED_LOGIN_ATTEMPTS est actuellement défini à : ${failed_login_attempts}"
        log_message "PASSWORD_LIFE_TIME est actuellement défini à : ${password_life_time}"
        return 1
    fi
}

# Fonction pour supprimer le fichier SQL après utilisation
cleanup_sql_file() {
    local sql_file="$1"

    if [[ -f "${sql_file}" ]]; then
        rm -f "${sql_file}"
        log_message "Le fichier ${sql_file} a été supprimé."
    else
        log_message "Le fichier ${sql_file} n'existe pas."
    fi
}

# Fonction principale
main() {

    # Recharger le bash_profile
    source "${BASH_PROFILE}"

    # Modifier et vérifier le profil pour XE
    if ! check_profile_modification "XE"; then
        modify_profile "XE"
        check_profile_modification "XE"
    fi

    # Modifier et vérifier le profil pour XEPDB1
    if ! check_profile_modification "XEPDB1"; then
        modify_profile "XEPDB1"
        check_profile_modification "XEPDB1"
    fi
    
    # Supprimer le fichier de configuration après modification du profil
    cleanup_sql_file "${ALTER_PROFILE_SQL_FILE}"
    log_message "Configuration du profil par défaut terminée avec succès."

    exit 0
}

# Appel de la fonction principale
main
