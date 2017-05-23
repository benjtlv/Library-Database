DEALLOCATE PREPARE cherche_document_emprunte;
DEALLOCATE PREPARE emprunte_exemplaire;

\echo 'Liste des différents clients : '
\echo '-----------------------------------------------------------------------------------'

SELECT client.id_client, client.nom, client.prenom, client.type_abonnement, client.penalites FROM client;

\prompt 'Choisir le numéro d"identifiant du client qui va faire un emprunt : ' identifiant_client


\echo 'Liste des différents documents : '
\echo '-----------------------------------------------------------------------------------'

SELECT document.id_document, document.titre FROM document;
	

\prompt 'Choisir le numéro du document à emprunter : ' num_document

PREPARE cherche_document_emprunte(INTEGER) AS
	SELECT document.titre, id_exemplaire, id_bibliotheque, nom, support
		FROM document
		NATURAL JOIN bibliotheque
		NATURAL JOIN exemplaire
			WHERE id_document = $1
			AND id_exemplaire NOT IN (SELECT id_exemplaire FROM emprunts WHERE date_rendu IS NULL)
			AND id_exemplaire NOT IN (SELECT id_exemplaire FROM reserve);
			
\echo 'Liste des différents exemplaires disponibles du document et où ils sont disponibles : '
\echo '--------------------------------------------------------------------------------------'

EXECUTE cherche_document_emprunte(:num_document);			

\prompt 'Choisir le numéro d"exemplaire à emprunte : ' num_exemplaire

PREPARE emprunte_exemplaire(INTEGER,INTEGER,INTEGER) AS
	INSERT INTO emprunts(id_client,id_exemplaire,id_document,date_emprunt,date_rendu,nb_renouvellements) VALUES
		($1,$2,$3,(select date from date_courante),null,0);
	
EXECUTE emprunte_exemplaire(:identifiant_client,:num_exemplaire,:num_document);

\echo 'Liste actuelle des différents emprunts : '
SELECT * FROM emprunts;		
