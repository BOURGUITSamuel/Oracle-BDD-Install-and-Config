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

# Chemin du dossier de configuration du fichier tnsnames.ora
TNS_ADMIN="${ORACLE_BASE}homes/OraDBHome21cXE/network/admin"

# Chemin du fichier tnsnames.ora
TNSNAMES_FILE="${TNS_ADMIN}/tnsnames.ora"

# Fichier de journalisation
LOG_FILE="/var/log/tns_configuration.log"

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

# Fonction pour définir TNS_ADMIN
setup_oracle_environment() {
    local oracle_bin
    oracle_bin=$(which sqlplus)
    if [ -z "${oracle_bin}" ] && [ -z "${ORACLE_HOME}"] ; then
        log_error "Oracle Database semble ne pas être installé sur le système. sqlplus n'est pas disponible."
    else
        log_message "Oracle Database est bien installé sur le système."
    fi

    # Vérifier l'existence du répertoire TNS_ADMIN
    if [ ! -d "${TNS_ADMIN}" ]; then
        log_error "Répertoire ${TNS_ADMIN} introuvable. Veuillez vérifier votre installation Oracle."
    else
        log_message "Répertoire ${TNS_ADMIN} présent."
    fi

    log_message "ORACLE_HOME défini sur ${ORACLE_HOME}"
    log_message "TNS_ADMIN défini sur ${TNS_ADMIN}"
}

# Fonction pour sauvegarder le fichier tnsnames.ora avant modification
check_backup_file() {
    if [ ! -f "${TNSNAMES_FILE}" ]; then
        log_error "Le fichier ${TNSNAMES_FILE} n'existe pas. Vérifiez le chemin et les permissions."
    else
        log_message "Le fichier ${TNSNAMES_FILE} est bien présent."
        if [ -f  "${TNSNAMES_FILE}.bak" ]; then
            log_message "Le fichier ${TNSNAMES_FILE}.bak existe déjà."
        else
            log_message "Le fichier ${TNSNAMES_FILE}.bak n'existe pas, sauvegarde du fichier en cours... "
            cp -r "${TNSNAMES_FILE}" "${TNSNAMES_FILE}.bak"
        fi
    fi
}

# Fonction pour vérifier si le tnsnames.ora est déjà configuré
is_tnsnames_configured() {
    if grep -q "${PDB_NAME}" "${TNSNAMES_FILE}"; then
        log_message "${PDB_NAME} est déjà configuré dans ${TNSNAMES_FILE}."
        return 0
    else
        log_message "${PDB_NAME} n'est pas configuré dans ${TNSNAMES_FILE}."
        return 1
    fi
}

# Fonction pour configurer le TNS
configure_tns_listener() {
    log_message "Configuration de ${TNSNAMES_FILE} pour ${PDB_NAME}..."
    
    echo "${PDB_NAME} =" >> "${TNSNAMES_FILE}"
    echo "  (DESCRIPTION =" >> "${TNSNAMES_FILE}"
    echo "    (ADDRESS = (PROTOCOL = TCP)(HOST = ${HOST_NAME})(PORT = ${SSH_PORT}))" >> "${TNSNAMES_FILE}"
    echo "    (CONNECT_DATA =" >> "${TNSNAMES_FILE}"
    echo "      (SERVER = DEDICATED)" >> "${TNSNAMES_FILE}"
    echo "      (SERVICE_NAME = ${SERVICE_NAME})" >> "${TNSNAMES_FILE}"
    echo "    )" >> "${TNSNAMES_FILE}"
    echo "  )" >> "${TNSNAMES_FILE}"

    log_message "Configuration ajoutée pour ${PDB_NAME} dans ${TNSNAMES_FILE}."
}

# Fonction pour tester la connexion
test_connection() {
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
        log_error "Échec de la connexion à la base de données Oracle. Veuillez vérifier les paramètres et l'état du service."
    fi
}

# Intégration dans la fonction principale
main() {
    setup_oracle_environment
    check_backup_file
    # Vérifier si le tnsnames.ora est déjà configuré et procéder à la configuration si nécessaire
    if ! is_tnsnames_configured; then
        configure_tns_listener
    else
        log_message "Aucune configuration supplémentaire n'est nécessaire pour ${PDB_NAME}."
    fi
    
    test_connection
    log_message "Configuration du TNS terminée avec succès."
}

# Appel de la fonction principale
main
