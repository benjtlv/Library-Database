DEALLOCATE PREPARE stat_biblio;

\echo 'Liste des différentes bibliotheques : '
\echo '-----------------------------------------------------------------------------------'
\echo

SELECT * FROM bibliotheque;

\prompt 'Choisir le numéro de la bibliotheque afin de calculer ses pourcentages d"emprunts : ' num_biblio
\echo


PREPARE stat_biblio(INTEGER) AS
	SELECT round((nb_emprunts_biblio($1)/nb_emprunts_total()::numeric*100),2) AS pourcentage_emprunts;
	
	
\echo 'Pourcentage d"emprunt dans la bibliotheque choisi : '
\echo		
EXECUTE stat_biblio(:num_biblio);
