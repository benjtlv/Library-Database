DEALLOCATE PREPARE cherche_document_reserve;
DEALLOCATE PREPARE reserve_exemplaire;

\echo 'Liste des différents clients : '
\echo '-----------------------------------------------------------------------------------'
\echo 

SELECT client.id_client, client.nom, client.prenom, client.type_abonnement, client.penalites FROM client;

\prompt 'Choisir le numéro d"identifiant du client qui va faire une réservation : ' identifiant_client
\echo 


\echo 'Liste des différents exemplaires que l"on peut réserver : '
\echo '-----------------------------------------------------------------------------------'
\echo 

SELECT document.titre, emprunts.id_exemplaire, emprunts.id_document, exemplaire.support
	FROM emprunts
	NATURAL JOIN document
	NATURAL JOIN exemplaire;

\prompt 'Choisir le numéro d"exemplaire à réserver : ' num_exemplaire
\echo 

PREPARE reserve_exemplaire(INTEGER,INTEGER) AS
	INSERT INTO reserve(id_client,id_exemplaire,id_document) VALUES
		($1,$2,(select id_document from emprunts where id_exemplaire = $2));
	
EXECUTE reserve_exemplaire(:identifiant_client,:num_exemplaire);

\echo 'Liste actuelle des différentes réservations : '
\echo 
SELECT * FROM reserve;		
