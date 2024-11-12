# Oracle-BDD-Install-and-Config

Bash script for installing and configuring an Oracle database.

## Getting Started

Ces scripts Bash permettent de déployer et configurer une base de données Oracle Express Edition version 21c dans un environnement de production.
Le projet a été conçu pour une application web nécessitant de stocker ses données dans un SGBD et de faire transiter ces mêmes données entre le front-end et le back-end via un agent de synchronisation.

Le projet comprend les étapes suivantes :

- Installation d'Oracle BDD Express Edition version 21c
- Configuration de la pompe de données, du jeu de caractères, et des variables d'environnement
- Changement de la durée de validité du mot de passe dans le profil par défaut
- Installation et configuration de l'Instant Client version 12
- Configuration du fichier tnsnames.ora
- Redémarrage du listener

### Prerequisites

L'utilisation du programme nécessite l'acquisition d'un système d'exploitation Linux : Oracle Linux version 8 au minimum.

Le programme a été conçu avec le language Bash.

Télécharger les fichiers d'installation pour l'Instant Client à l'adresse suivante : https://www.oracle.com/fr/database/technologies/instant-client/linux-x86-64-downloads.html

## Installing & Using

1- Copiez les scripts dans le répertoire de votre choix

2- Ajustez les paramètres suivants selon votre situation :

- Modifier les identifiants de connexion.
- Modifier les paramètres pour la configuration de la pompe de données (Data Pump).
- Modifier la durée de validité du mot de passe (par défaut, le paramètre sera réglé sur 'unlimited')
- Modifier la version de l'Instant Client que vous souhaitez déployer (par défaut, la version 12 sera installée).
- Modifier le nom de service à configurer dans le fichier tnsnames.ora (par défaut, le service déployé sera pour XEPDB1).
- Modifier les fichiers SQL permettant de configurer le jeu de caractères et la pompe de données.

3- Vous pouvez appliquer vos propres paramètres en modifiant les scripts 

## Running the tests

Le programme a été conçu dans un environnement de développement intégré(IDE) sur l'OS Windows 11 64Bits.

Le programme a été testé sur l'OS Oracle Linux 8 64bits.

## Versioning

Version 2.0

## Authors

Jean - Samuel BOURGUIT 

Administrateur Infrastuture et Cloud

## License
Copyright 2023 Jean - Samuel BOURGUIT

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

