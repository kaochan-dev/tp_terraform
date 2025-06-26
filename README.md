# 🚀 Déploiement AWS avec Terraform

Ce projet permet de déployer une infrastructure de base sur AWS via Terraform.

---

## 📁 Fichiers Terraform

### 1. `main.tf`
Contient la définition des **ressources principales** :
- VPC, Subnets publics/privés
- Load Balancer (ALB)
![ALB](images/alb.png)
- Groupes de sécurité
![sg](images/sg.png)
- Target Groups et autres composants réseau
- 2 instance
![instance](images/instance.png)

C’est le **cœur** de l’infrastructure.



---

### 2. `variables.tf`
Déclare toutes les **variables d’entrée** utilisées dans `main.tf` :
- CIDR, zones de disponibilité (az1, az2)
- Noms, ports, etc.

Permet de personnaliser l’infra sans modifier le code principal.

---

### 3. `outputs.tf`
Affiche les **informations utiles** après l’exécution :
- URL du Load Balancer
- IDs des subnets, VPC, etc.

Facilite la récupération rapide des ressources créées.

---

### 4. `Instance web`
Voici les captures prouvant que les instances derrière le Load Balancer répondent correctement :
- Instance 1 : ![teste instance-1](images/instance1.png)
- Instance 2 : ![teste instance-2](images/instance2.png)

Facilite la récupération rapide des ressources créées.

---

## ▶️ Commandes de base

```bash
terraform init     # Initialise Terraform
terraform apply    # Déploie l'infrastructure
