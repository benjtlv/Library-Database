DEALLOCATE PREPARE cherche_exemplaire_client;
DEALLOCATE PREPARE renouvel_exemplaire;

\echo 'Liste des différents clients qui ont un emprunt en cours : '
\echo '-----------------------------------------------------------------------------------'
\echo

SELECT id_client, nom, prenom 
	FROM client
	NATURAL JOIN emprunts
	GROUP BY id_client;

\prompt 'Choisir le numéro du client qui va renouveler un exemplaire : ' num_client
\echo

PREPARE cherche_exemplaire_client(INTEGER) AS
	SELECT emprunts.id_exemplaire 
		FROM emprunts
			WHERE emprunts.id_client = $1;
			
\echo 'Liste des différents exemplaires emprunté par le client choisi : '
\echo '--------------------------------------------------------------------------------------'
\echo

EXECUTE cherche_exemplaire_client(:num_client);

\prompt 'Choisir le numéro d"exemplaire à renouveler : ' num_exemplaire
\echo

PREPARE renouvel_exemplaire(INTEGER) AS
	SELECT renouvellement_exemplaire($1);
	
EXECUTE renouvel_exemplaire(:num_exemplaire);

\echo 'Liste actuelle des différents emprunts en cours : '	
\echo '-----------------------------------------------------------------------------------'
\echo

SELECT * FROM emprunts;

