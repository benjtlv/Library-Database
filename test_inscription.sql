DEALLOCATE PREPARE inscription_client;

\echo 'Liste des personnes inscrites aux bibliothèques de Paris : '
\echo '-----------------------------------------------------------------------------------'

SELECT nom,prenom,date_naissance,type_abonnement,date_inscription,penalites
FROM client;

\prompt 'Choisir le nom de la personne à inscrire (AVEC DES GUILLEMETS SIMPLES !) : ' nom_user
\prompt 'Choisir le prénom de la personne à inscrire (AVEC DES GUILLEMETS SIMPLES !) : ' prenom_user
\prompt 'Choisir la date_naissance de la personne à inscrire (AVEC DES GUILLEMETS SIMPLES !) : ' dateNaissance_user
\prompt 'Choisir le téléphone de la personne à inscrire (AVEC DES GUILLEMETS SIMPLES !) : ' telephone_user
\prompt 'Choisir l"adresse de la personne à inscrire (AVEC DES GUILLEMETS SIMPLES !) : ' adresse_user
\prompt 'Choisir le code postal de la personne à inscrire (AVEC DES GUILLEMETS SIMPLES !) : ' codePostal_user
\prompt 'Choisir la ville de la personne à inscrire (AVEC DES GUILLEMETS SIMPLES !) : ' ville_user
\prompt 'Choisir le type d"abonnement de la personne à inscrire (AVEC DES GUILLEMETS SIMPLES !) : ' typeAbo_user

PREPARE inscription_client(VARCHAR,VARCHAR,DATE,VARCHAR,VARCHAR,VARCHAR,VARCHAR,VARCHAR) AS
	INSERT INTO client(nom,prenom,date_naissance,telephone,adresse,codePostal,ville,type_abonnement,date_inscription,penalites) VALUES
		($1,$2,$3,$4,$5,$6,$7,$8,(select date from date_courante),0);
		
		
		
EXECUTE inscription_client(:nom_user,:prenom_user,:dateNaissance_user,:telephone_user,:adresse_user,:codePostal_user,:ville_user,:typeAbo_user);		

--EXECUTE inscription_client('freud','jacck','1965-03-03','0678523438','39 rue des gravilliers','75003','paris','CD','1995-05-22',0);
