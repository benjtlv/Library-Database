DEALLOCATE cherche_exemplaire_client;
DEALLOCATE rendre_exemplaire;


\echo 'Liste des différents clients qui ont un emprunt en cours : '
\echo '-----------------------------------------------------------------------------------'
\echo

SELECT id_client, nom, prenom 
	FROM client
	NATURAL JOIN emprunts
	GROUP BY id_client;

\prompt 'Choisir le numéro du client qui va rendre un exemplaire : ' num_client
\echo

PREPARE cherche_exemplaire_client(INTEGER) AS
	SELECT emprunts.id_exemplaire, emprunts.date_emprunt, emprunts.date_rendu
		FROM emprunts
			WHERE emprunts.id_client = $1
			AND emprunts.date_rendu IS NULL;
			
\echo 'Liste des différents exemplaires emprunté par le client choisi : '
\echo '--------------------------------------------------------------------------------------'
\echo

EXECUTE cherche_exemplaire_client(:num_client);

\prompt 'Choisir le numéro d"exemplaire à rendre : ' num_exemplaire
\echo

PREPARE rendre_exemplaire(INTEGER) AS
	UPDATE emprunts
	SET date_rendu = (select date from date_courante)
	WHERE id_exemplaire = $1;
	
EXECUTE rendre_exemplaire(:num_exemplaire);	

\echo 'Liste actuelle des différents emprunts : '
\echo '--------------------------------------------------------------------------------------'
\echo

SELECT emprunts.id_client, emprunts.id_exemplaire, emprunts.date_emprunt, emprunts.date_rendu FROM emprunts;
