DEALLOCATE renouvel_inscription;

\echo 'Liste des différents clients : '
\echo '-----------------------------------------------------------------------------------'
\echo

SELECT client.id_client, client.nom, client.prenom, client.date_inscription FROM client;

\prompt 'Choisir le numéro du client qui va renouveler son abonnment : ' num_client
\echo

PREPARE renouvel_inscription(INTEGER) AS
	SELECT renouvellement_inscription($1);
	
EXECUTE renouvel_inscription(:num_client);

\echo 'Liste actuelle des différents clients : '
\echo '-----------------------------------------------------------------------------------'
\echo
	
SELECT client.id_client, client.nom, client.prenom, client.date_inscription FROM client;
