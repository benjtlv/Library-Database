DEALLOCATE PREPARE cherche_exemplaire;

\echo 'Liste des différents documents : '
\echo '-----------------------------------------------------------------------------------'

SELECT document.titre FROM document;

\prompt 'Choisir le titre du document à chercher (AVEC DES GUILLEMETS SIMPLES !) : ' titre_exemplaire

PREPARE cherche_exemplaire(VARCHAR) AS
	SELECT document.titre, id_exemplaire, id_bibliotheque, nom
		FROM document
		NATURAL JOIN bibliotheque
		NATURAL JOIN exemplaire
			WHERE titre LIKE $1
			AND id_exemplaire NOT IN (SELECT id_exemplaire FROM emprunts WHERE date_rendu IS NULL)
			AND id_exemplaire NOT IN (SELECT id_exemplaire FROM reserve);
			
\echo 'Liste des différents exemplaires disponibles du document choisi et où ils sont disponibles : '
\echo '--------------------------------------------------------------------------------------'

EXECUTE cherche_exemplaire(:titre_exemplaire);			
