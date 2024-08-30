#!/bin/bash

# Configuration du téléchargement du fichier d'installation
ORACLE_VERSION="21c"
XE_VERSION="1.0-1"
INSTALL_FILE="oracle-database-xe-${ORACLE_VERSION}-${XE_VERSION}.ol8.x86_64.rpm"
DOWNLOAD_URL="https://download.oracle.com/otn-pub/otn_software/db-express/${INSTALL_FILE}"

# Identifiants de connexion
ORACLE_HOME="/opt/oracle/product/21c/dbhomeXE"
HOST="localhost"
SSH_PORT="1521"
ORACLE_USER="sys"
ORACLE_PASSWORD="manager"
ORACLE_SID="XE"

# Configuration du paramètre NLS_LANG
NLS_LANG="FRENCH_FRANCE.WE8MSWIN1252"

# Nom du service à redémarrer
SERVICE_NAME="oracle-xe-21c"

# Fichier de journalisation
LOG_FILE="/var/log/oracle_installation.log"

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

# Fonction pour télécharger Oracle XE
download_oracle_xe() {
    log_message "Téléchargement de Oracle Database Express Edition ${ORACLE_VERSION}."
    wget -O "/tmp/${INSTALL_FILE}" "${DOWNLOAD_URL}" || log_error "Le téléchargement a échoué."
}

# Fonction pour installer Oracle XE
install_oracle_xe() {
    log_message "Installation de Oracle Database Express Edition ${ORACLE_VERSION}."
    yum localinstall -y "/tmp/${INSTALL_FILE}" || log_error "L'installation a échoué."
}

# Fonction pour configurer Oracle XE
configure_oracle_xe() {
    log_message "Configuration de Oracle Database Express Edition ${ORACLE_VERSION}."
    /etc/init.d/${SERVICE_NAME} configure <<EOF
${ORACLE_PASSWORD}
${ORACLE_PASSWORD}
EOF
}

# Fonction pour démarrer Oracle XE
start_oracle_xe() {
    log_message "Démarrage de Oracle Database Express Edition ${ORACLE_VERSION}."

    # Recharger les fichiers de configuration des services
    systemctl daemon-reload
    if [ $? -ne 0 ]; then
        log_error "La commande systemctl daemon-reload a échoué."
    fi
    
    systemctl start --quiet ${SERVICE_NAME} || log_error "Le démarrage a échoué."
    systemctl enable --quiet ${SERVICE_NAME} || log_error "L'activation du service au démarrage du système a échoué."

    # Vérification du statut après le démarrage
    if systemctl is-active --quiet ${SERVICE_NAME}; then
        log_message "Oracle Database Express Edition ${ORACLE_VERSION} a démarré avec succès."
    else
        log_error "Le démarrage a échoué après tentative."
    fi

    # Vérification si le service est activé au démarrage
    if systemctl is-enabled --quiet ${SERVICE_NAME}; then
        log_message "Le service ${SERVICE_NAME} est configuré pour démarrer au boot."
    else
        log_error "Le service ${SERVICE_NAME} n'est pas configuré pour démarrer au boot."
    fi
}

# Fonction pour vérifier la connexion à la base de données Oracle
check_database_connection() {
    echo "Vérification de la connexion à la base de données Oracle..."
    # Export du path Oracle
    export ORACLE_HOME=${ORACLE_HOME}
    # Export du NLS_LANG
    export NLS_LANG=${NLS_LANG}
    # Tentative de connexion avec sqlplus et exécution d'une requête simple
    result=$(${ORACLE_HOME}/bin/sqlplus -S ${ORACLE_USER}/${ORACLE_PASSWORD}@${HOST}:${SSH_PORT}/${ORACLE_SID} as sysdba <<EOF
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

# Fonction pour supprimer les fichiers après l'installation
cleanup_files() {
    log_message "Nettoyage en cours..."

    # Suppression du fichier d'installation
    rm -f "/tmp/${INSTALL_FILE}"
    if [ $? -ne 0 ]; then
        log_error "La suppression de ${INSTALL_FILE} a échoué."
    else
        log_message "Fichier ${INSTALL_FILE} supprimé avec succès."
    fi
}

# Fonction principale
main() {
    download_oracle_xe
    install_oracle_xe
    configure_oracle_xe
    start_oracle_xe
    check_database_connection
    cleanup_files
    log_message "Installation de Oracle Database Express Edition ${ORACLE_VERSION} terminée avec succès."
}

# Exécuter la fonction principale
main
