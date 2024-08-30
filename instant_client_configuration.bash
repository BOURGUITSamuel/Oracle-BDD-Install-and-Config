#!/bin/bash

# Définition du répertoire contenant les fichiers d'installation
INSTANT_CLIENT_DIR="/tmp"

# Définition de la version de l'Instant Client
CLIENT_VERSION="12.2.0.1.0"

# Chemin complet du répertoire d'installation souhaité
INSTALL_PATH="/opt/oracle/"

# Chemin complet du dossier instant Client
INSTANT_CLIENT_PATH="/opt/oracle/instantclient_12_2/"

# Fichier de journal
LOG_FILE="/var/log/instantclient_install.log"

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

# Fonction pour vérifier les prérequis
check_prerequisites() {
    command -v unzip >/dev/null 2>&1 || log_error "unzip n'est pas installé. Veuillez installer unzip et réessayer."
}

# Fonction pour vérifier si le dossier instant client existe déjà
check_existing_installation() {
    if [ -d "${INSTANT_CLIENT_PATH}" ]; then
        log_message "Le dossier instant client existe déjà. L'Instant Client version ${CLIENT_VERSION} est déjà configuré sur le serveur."
        exit 0
    else
        log_message "Le dossier instant client version ${CLIENT_VERSION} n'existe pas. Procédure d'installation en cours."
    fi
}

# Fonction pour vérifier l'existence du répertoire de téléchargement
check_instant_client_dir() {
    if [ ! -d "${INSTANT_CLIENT_DIR}" ]; then
        log_error "Le répertoire contenant les fichiers d'installation n'existe pas."
    else
        log_message "Le répertoire contenant les fichiers d'installation existe bien."
    fi
}

# Fonction pour vérifier l'existence des fichiers d'installation
check_instant_client_files() {
    local files=("${INSTANT_CLIENT_DIR}/instantclient-basic-linux.x64-${CLIENT_VERSION}.zip"
                 "${INSTANT_CLIENT_DIR}/instantclient-sqlplus-linux.x64-${CLIENT_VERSION}.zip"
                 "${INSTANT_CLIENT_DIR}/instantclient-sdk-linux.x64-${CLIENT_VERSION}.zip")
    local missing_files=()

    for file in "${files[@]}"; do
        if [ -f "${file}" ]; then
            log_message "Le fichier ${file} est bien présent."
        else
            missing_files+=("${file}")
        fi
    done

    if [ ${#missing_files[@]} -ne 0 ]; then
        log_message "Les fichiers suivants n'existent pas : ${missing_files[*]}"
        log_error "Un ou plusieurs fichiers de configuration sont absents."
    fi
}

# Fonction pour vérifier l'existence des fichiers décompressés
check_decompressed_files() {
    local files=("libclntsh.so" "libocci.so")
    for file in "${files[@]}"; do
        if [ -f "${INSTANT_CLIENT_PATH}/${file}" ]; then
            log_message "Le fichier décompressé ${file} existe déjà."
        else
            log_message "Le fichier décompressé ${file} n'existe pas."
        fi
    done
}

# Fonction pour créer le répertoire d'installation s'il n'existe pas
create_install_dir() {
    if [ ! -d "${INSTALL_PATH}" ]; then
        mkdir -p "${INSTALL_PATH}" || log_error "Impossible de créer le répertoire d'installation."
    fi
    log_message "Répertoire d'installation créé avec succès."
}

# Fonction pour décompresser un fichier
unzip_file() {
    local zip_file="${INSTANT_CLIENT_DIR}/$1"
    unzip -o "${zip_file}" -d "${INSTALL_PATH}" >> "${LOG_FILE}" 2>&1
    if [ $? -ne 0 ]; then
        log_error "La décompression de ${zip_file} a échoué."
    else
        log_message "Fichier ${zip_file} décompressé avec succès."
    fi
}

# Fonction pour décompresser les fichiers Instant Client
unzip_instant_client_files() {
    local files=("instantclient-basic-linux.x64-${CLIENT_VERSION}.zip"
                 "instantclient-sqlplus-linux.x64-${CLIENT_VERSION}.zip"
                 "instantclient-sdk-linux.x64-${CLIENT_VERSION}.zip")
    for file in "${files[@]}"; do
        chmod 755 ${INSTANT_CLIENT_DIR}/"${file}"
        unzip_file "${file}"
    done
}

# Fonction pour créer les liens symboliques nécessaires
create_symbolic_links() {
    if [ -L "${INSTANT_CLIENT_PATH}/libclntsh.so" ]; then
        log_message "Le lien symbolique libclntsh.so existe déjà."
    else
        ln -s ${INSTANT_CLIENT_PATH}/libclntsh.so.* ${INSTANT_CLIENT_PATH}/libclntsh.so
    fi

    if [ -L "${INSTANT_CLIENT_PATH}/libocci.so" ]; then
        log_message "Le lien symbolique libocci.so existe déjà."
    else
        ln -s ${INSTANT_CLIENT_PATH}/libocci.so.* ${INSTANT_CLIENT_PATH}/libocci.so
    fi

    if [ -L "${INSTANT_CLIENT_PATH}/libocci.so" ] && [ -L "${INSTANT_CLIENT_PATH}/libclntsh.so" ]; then
        log_message "Liens symboliques créés."
    else
        log_error "La création des liens symboliques a échoué."
    fi

    # Modifier les droits et le propriétaire
    chmod -R 750 ${INSTANT_CLIENT_PATH}
    chown -R oracle:oinstall ${INSTANT_CLIENT_PATH}
}

# Fonction pour supprimer les fichiers ZIP après l'installation
cleanup_files() {
    log_message "Nettoyage en cours..."
    local files=("instantclient-basic-linux.x64-${CLIENT_VERSION}.zip"
                 "instantclient-sqlplus-linux.x64-${CLIENT_VERSION}.zip"
                 "instantclient-sdk-linux.x64-${CLIENT_VERSION}.zip")
    for file in "${files[@]}"; do
        rm -f "${INSTANT_CLIENT_DIR}/${file}"
        if [ $? -ne 0 ]; then
            log_message "la suppression de ${file} a échoué."
        else
            log_message "Fichier ${file} supprimé avec succès."
        fi
    done
}

# Intégration dans la fonction principale
main() {
    check_prerequisites
    check_existing_installation
    check_instant_client_dir
    check_instant_client_files
    check_decompressed_files
    create_install_dir
    unzip_instant_client_files
    create_symbolic_links
    cleanup_files
    log_message "Installation de l'Oracle Instant Client version ${CLIENT_VERSION} terminée avec succès."
}

# Appel de la fonction principale
main
