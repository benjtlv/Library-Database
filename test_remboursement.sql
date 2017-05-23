


\echo 'Liste des différents clients : '
\echo '-----------------------------------------------------------------------------------'
\echo 

SELECT client.id_client, client.nom, client.prenom, client.penalites FROM client;

\prompt 'Choisir le numéro d"identifiant du client qui souhaite effectuer un remboursement : ' identifiant_client
\echo 


PREPARE remboursement_penalites(INTEGER) AS
	UPDATE client 
	SET penalites = 0
	WHERE id_client = $1;
	
EXECUTE remboursement_penalites(:identifiant_client);

\echo 'Liste actuelle des clients : '
\echo 

SELECT client.id_client, client.nom, client.prenom, client.penalites FROM client;
