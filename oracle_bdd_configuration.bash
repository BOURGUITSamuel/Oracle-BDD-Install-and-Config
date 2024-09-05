#!/bin/bash

# Version d'oracle
ORACLE_VERSION="21c"

# Configuration des variables d'environnement
ORACLE_BASE="/opt/oracle/"
LD_LIBRARY_PATH="/opt/oracle/product/21c/dbhomeXE/lib"
ORACLE_HOME="/opt/oracle/product/21c/dbhomeXE"
TNS_ADMIN="\$ORACLE_BASE/homes/OraDBHome21cXE/network/admin"
PATH_1="\$ORACLE_BASE/product/21c/dbhomeXE/bin"
PATH_2="/usr/bin"
ORACLE_SID="XE"

# Configuration des identifiants de connexion
ORACLE_USER="system"
ORACLE_PASSWORD="manager"
HOST="localhost"
SSH_PORT="1521"

# Configuration du Data Pump
DATA_PUMP="PROD_DATAPUMP"
DATAPUMP_DIR="/opt/oracle/backup"
DATAPUMP_FILE="/tmp/export_datapump.sql"
DUMPFILE="expdp.dmp"
DATAPUMP_LOG_FILE="expdp.log"

# Configuration du jeu de caractères
CHARACTER_SET_FILE="/tmp/config_character_set.sql"
CHARACTER_SET="WE8MSWIN1252"

# Emplacement du fichier de journalisation
LOG_FILE="/var/log/oracle_configuration.log"

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

# Fonction pour vérifier la définition de la variable HOME
check_home_variable() {
    if [ -z "${HOME}" ]; then
        log_error "la variable d'environnement \${HOME} n'est pas définie."
    fi
}

# Fonction pour vérifier si les fichiers de configuration existent
check_conf_files() {
    local files=(
        "/tmp/export_datapump.sql"
        "/tmp/config_character_set.sql"
    )

    local missing_files=()
    
    # Boucle pour vérifier chaque fichier
    for file in "${files[@]}"; do
        if [[ ! -f "${file}" ]]; then
            missing_files+=("${file}")
        fi
    done

    # Gestion des cas selon les résultats
    if [[ ${#missing_files[@]} -eq 0 ]]; then
        log_message "Les fichiers de configuration sont présents sur le serveur."
    else
        log_message "Les fichiers suivants sont manquants :"
        for missing_file in "${missing_files[@]}"; do
            echo "- ${missing_file}"
        done
        log_error "La configuration d'Oracle ne peut pas continuer sans les fichiers nécessaires."
    fi
}

# Fonction pour ajouter une variable au bash_profile si elle n'existe pas déjà
add_to_bash_profile() {
    log_message "Configuration des variables d'environnement..."
    local variable_name="$1"
    local variable_value="$2"
    local profile_file="${HOME}/.bash_profile"

    if ! grep -q "^export ${variable_name}=" "${profile_file}"; then
        echo "export ${variable_name}=${variable_value}" >> "${profile_file}"
        log_message "${variable_name} ajouté à ${profile_file}"
    else
        log_message "${variable_name} existe déjà dans ${profile_file}"
    fi
}

# Fonction pour ajouter une valeur à la variable PATH dans le bash_profile si elle n'existe pas déjà
add_path_in_bash_profile() {
    log_message "Configuration des variables d'environnement..."
    local path_value="$1"
    local profile_file="${HOME}/.bash_profile"

    if ! grep -q "^export PATH=.*${path_value}" "${profile_file}"; then
        echo "export PATH=${path_value}:\$PATH" >> "${profile_file}"
        log_message "PATH mis à jour avec ${path_value}"
    else
        log_message "Le chemin ${path_value} existe déjà dans PATH."
    fi
}

# Fonction pour vérifier si le répertoire de backup existe
create_backup_directory() {
    log_message "Création du répertoire de backup..."
    # Vérifie si le répertoire existe
    if [ -d "${DATAPUMP_DIR}" ]; then
        log_message "Le répertoire ${DATAPUMP_DIR} existe déjà."
    else
        log_message "Le répertoire ${DATAPUMP_DIR} n'existe pas, création en cours..."
        mkdir -p "${DATAPUMP_DIR}"
        chmod 755 "${DATAPUMP_DIR}"
        chown oracle:oinstall "${DATAPUMP_DIR}"
    fi
}

# Fonction pour exécuter un fichier SQL via SQL*Plus : Création du Data Pump
create_data_pump() {
    local ORACLE_USER="system"
    local ORACLE_SID="XEPDB1"
    log_message "Création du Data Pump..."
    # Exécution du fichier SQL pour créer le répertoire et les privilèges
    sqlplus_output=$(sqlplus "${ORACLE_USER}/${ORACLE_PASSWORD}@${HOST}:${SSH_PORT}/${ORACLE_SID}" @"${DATAPUMP_FILE}" 2>&1)
    sqlplus_exit_code=$?

    # Vérification de l'exécution du fichier SQL
    if [ ${sqlplus_exit_code} -ne 0 ]; then
        log_message "Erreur SQL*Plus : ${sqlplus_output}"
        log_error "Échec de l'exécution du fichier SQL. Consultez le fichier de log pour plus de détails."
    else
        log_message "Le fichier SQL a été exécuté avec succès."
    fi
}

# Fonction pour vérifier le Data Pump Directory
check_datapump_directory() {
    local ORACLE_USER="system"
    local ORACLE_SID="XEPDB1"
    # Commande pour vérifier la configuration du Data Pump
    result=$(sqlplus -s ${ORACLE_USER}/${ORACLE_PASSWORD}@${HOST}:${SSH_PORT}/${ORACLE_SID} <<EOF
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
SELECT directory_path FROM dba_directories WHERE directory_name='${DATA_PUMP}';
EOF
)

    # Comparer le résultat avec la variable DATAPUMP_DIR
    if [[ "${result}" == "${DATAPUMP_DIR}" ]]; then
        log_message "Le répertoire Data Pump est correctement défini. Le répertoire actuellement configuré est : ${DATAPUMP_DIR}"
    else
        log_error "Le répertoire Data Pump n'est pas correctement défini. Le répertoire actuellement configuré est : ${result}"
    fi
}

# Fonction pour effectuer l'exportation Data Pump
perform_data_pump_export() {
    local ORACLE_SID="XEPDB1"
    log_message "Vérification de l'exportation du Data Pump..."
    # Commande d'exportation Data Pump
    expdp_output=$(expdp "${ORACLE_USER}/${ORACLE_PASSWORD}@${HOST}:${SSH_PORT}/${ORACLE_SID}" DIRECTORY="${DATA_PUMP}" DUMPFILE="${DUMPFILE}" LOGFILE="${DATAPUMP_LOG_FILE}" FULL=Y 2>&1)
    expdp_exit_code=$?

    # Vérification de l'exécution de la commande Data Pump
    if [ ${expdp_exit_code} -ne 0 ]; then
        log_message "Erreur Data Pump : ${expdp_output}"
        log_error "Échec de l'exportation Data Pump. Consultez le fichier de log pour plus de détails."
    else
        log_message "La commande Data Pump a été exécutée avec succès."
    fi

    # Vérification de la création du fichier de dump
    if [ -f "${DATAPUMP_DIR}/${DUMPFILE}" ]; then
        log_message "Le fichier de dump Data Pump a été créé avec succès : ${DUMPFILE}"
    else
        log_error "Le fichier de dump Data Pump est introuvable : ${DUMPFILE}"
    fi
}

# Fonction pour vérifier l'existence du fichier de log et du fichier dump après export
check_datapump_log_file() {
    log_message "Vérification du fichier de log d'exportation..."
    # Vérification de l'existence du fichier de log
    if [ -f "${DATAPUMP_DIR}/${DATAPUMP_LOG_FILE}" ]; then
        log_message "Le fichier de log Data Pump a été créé avec succès : ${DATAPUMP_LOG_FILE}"

        # Vérification des erreurs dans le fichier de log
        if grep -q "ORA-" "${DATAPUMP_DIR}/${DATAPUMP_LOG_FILE}"; then
            log_message "Erreur : Il y a eu des erreurs pendant l'exportation Data Pump. Vérifiez le fichier de log : ${DATAPUMP_LOG_FILE}"
        else
            log_message "L'exportation Data Pump s'est terminée avec succès. Aucune erreur trouvée dans le fichier de log."
        fi
    else
        log_error "Le fichier de log Data Pump est introuvable : ${DATAPUMP_LOG_FILE}"
    fi
}

# Fonction pour exécuter un fichier SQL via SQL*Plus : Configuration du jeu de caractères
config_character_set() {
    local ORACLE_USER="sys"
    log_message "Configuration du jeu de caractères ..."
    # Exécution du fichier SQL pour configurer les jeu de caractères
    sqlplus_output=$(sqlplus "${ORACLE_USER}/${ORACLE_PASSWORD}@${HOST}:${SSH_PORT}/${ORACLE_SID}" as sysdba @"${CHARACTER_SET_FILE}" 2>&1)
    sqlplus_exit_code=$?

    # Vérification de l'exécution du fichier SQL
    if [ ${sqlplus_exit_code} -ne 0 ]; then
        log_message "Erreur SQL*Plus : ${sqlplus_output}"
        log_error "Échec de l'exécution du fichier SQL. Consultez le fichier de log pour plus de détails."
    else
        log_message "Le fichier SQL a été exécuté avec succès."
    fi
}

# Fonction pour vérifier la configuration du jeu de caractères
check_character_set() {
    local ORACLE_USER="system"
    local ORACLE_SID="XEPDB1"
    # Commande pour vérifier la configuration jeu de caractères
    result=$(sqlplus -s ${ORACLE_USER}/${ORACLE_PASSWORD}@${HOST}:${SSH_PORT}/${ORACLE_SID} <<EOF
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
select value from NLS_DATABASE_PARAMETERS where PARAMETER = 'NLS_CHARACTERSET';
EOF
)

    # Comparer le résultat avec la variable CHARACTER_SET
    if [[ "${result}" == "${CHARACTER_SET}" ]]; then
        log_message "Le jeu de caractères est correctement défini. Le jeu de caractères actuellement configuré est : ${CHARACTER_SET}"
    else
        log_error "Le jeu de caractères n'est pas correctement défini. Le jeu de caractères actuellement configuré est : ${result}"
    fi
}

# Fonction pour supprimer les fichiers après l'installation
cleanup_files() {
    log_message "Nettoyage en cours..."
    # Suppression des fichiers sql
    local path="tmp"
    local files=("config_character_set.sql"
                 "export_datapump.sql")
    for file in "${files[@]}"; do
        rm -f "/${path}/${file}"
        if [ $? -ne 0 ]; then
            log_error "La suppression de ${file} a échoué."
        else
            log_message "Fichier ${file} supprimé avec succès."
        fi
    done
    
    # Suppression du fichier de sauvegarde
    local backup_file="/opt/oracle/backup/expdp.dmp"
    rm -f "${backup_file}"
    if [ $? -ne 0 ]; then
        log_error "La suppression de ${backup_file} a échoué."
    else
        log_message "Fichier ${backup_file} supprimé avec succès."
    fi

    # Suppression du fichier log de la sauvegarde
    local log_file="/opt/oracle/backup/expdp.log"
    rm -f "${log_file}"
    if [ $? -ne 0 ]; then
        log_error "La suppression de ${log_file} a échoué."
    else
        log_message "Fichier ${log_file} supprimé avec succès."
    fi
}

# Intégration dans la fonction principale
main() {

    check_home_variable
    check_conf_files

    local setup_title="# Oracle Home Configuration"
    local profile_file="${HOME}/.bash_profile"

    if ! grep -Fxq "${setup_title}" "${profile_file}"; then
        echo "" >> "${HOME}/.bash_profile"
        echo "# Oracle Home Configuration" >> "${HOME}/.bash_profile"
    else
        log_message "Le titre de configuration est déjà présent."
    fi

    add_to_bash_profile "ORACLE_BASE" "${ORACLE_BASE}"
    add_to_bash_profile "LD_LIBRARY_PATH" "${LD_LIBRARY_PATH}"
    add_to_bash_profile "ORACLE_HOME" "${ORACLE_HOME}"
    add_to_bash_profile "TNS_ADMIN" "${TNS_ADMIN}"
    add_path_in_bash_profile "${PATH_1}"
    add_path_in_bash_profile "${PATH_2}"
    add_to_bash_profile "ORACLE_SID" "${ORACLE_SID}"

    # Recharger le bash_profile
    source "${profile_file}"

    create_backup_directory
    create_data_pump
    check_datapump_directory
    perform_data_pump_export
    check_datapump_log_file
    config_character_set
    check_character_set
    cleanup_files

    log_message "Configuration de Oracle Database Express Edition ${ORACLE_VERSION} terminée avec succès."
}

# Appel de la fonction principale
main
