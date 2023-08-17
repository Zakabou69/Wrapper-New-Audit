#!/bin/bash

while [ -z "$AuditName" ]; do
    read -p 'Entrez le nom du nouvel audit de sécurité : ' AuditName
done

valid_types=("pentest" "root-me" "tryhackme" "htb" "bounty" "OSCP")
while [ -z "$Type" ] || ! [[ " ${valid_types[@]} " =~ " ${Type} " ]]; do
    read -p "Quelle catégorie : pentest? root-me? tryhackme? htb? bounty? OSCP : " Type
done

if [ -d "/data/$Type/$AuditName" ]; then
    echo "Impossible de créer le répertoire, il existe déjà."
else
    echo "Création de $Type/$AuditName" 
    mkdir -p "/data/$Type/$AuditName" && cd "/data/$Type/$AuditName"
    touch user.txt pass.txt notes.txt
    mkdir -p "/data/$Type/$AuditName/nmap"
    mkdir -p "/data/$Type/$AuditName/logs"

    while [ -z "$Cible" ]; do
        read -p "Donnez le nom ou l'IP de la cible : " Cible
    done

    echo "Patientez pendant que nmap s'exécute..."
    nmap -p- -v -Pn -oN "/data/$Type/$AuditName/nmap/nmap_all.txt" "$Cible"  # Exécuter nmap en arrière-plan


    echo "Voici les ports ouverts sur la machine cible:"
    cat "/data/$Type/$AuditName/nmap/nmap_all.txt" | grep -Po '\d+\/' | sort | cut -d "/" -f1 | tee "/data/$Type/$AuditName/ports_ouverts.txt"


    echo "Lancement d'un nouveau scan Nmap sur les ports ouverts..."
    nmap -A -p $(cat "/data/$Type/$AuditName/ports_ouverts.txt" | tr '\n' ',') "$Cible" -oN "/data/$Type/$AuditName/nmap/nmap_agg.txt"
    
    if grep -q '80/' "/data/$Type/$AuditName/nmap/nmap_all.txt"; then
        echo "Port 80 est ouvert. Exécution de la commande nuclei..."
        nuclei -u "http://$Cible" -o "/data/$Type/$AuditName/logs/nuclei_output.txt"
        echo "Exécution de la commande nikto..."
        nikto -h "$Cible" -o "/data/$Type/$AuditName/logs/nikto_output.txt"

        echo "Exécution de la commande gobuster..."
        gobuster dir -u "http://$Cible" -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -o "/data/$Type/$AuditName/logs/gobuster_output.txt"

        echo "Exécution de la commande amass..."
        amass enum -d "$Cible" -o "/data/$Type/$AuditName/logs/amass_output.txt"
    
    fi
fi
