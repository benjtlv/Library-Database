--Vérifie si un client peut encore emprunter par rapport au nombre d'emprunts max(40 en tout)
CREATE OR REPLACE FUNCTION max_limite_emprunts_40(idClient INTEGER)
RETURNS BOOLEAN AS $$
	DECLARE
		peut_emprunter BOOLEAN;
		
	BEGIN
		SELECT count(*) < 40 INTO peut_emprunter FROM emprunts 
			WHERE emprunts.id_client = idClient AND emprunts.date_rendu IS NULL;
		IF peut_emprunter = FALSE THEN
			RAISE 'Le client % a dépassé le nombre limite d"emprunts dans toutes bibliothèques (40)',idClient;
		END IF;	
		RETURN peut_emprunter;
	END;
$$ LANGUAGE plpgsql;

--Mise a jour de la date courante et donc des pénalités des clients si ils sont en retard	
CREATE OR REPLACE FUNCTION updateDateCourante()
RETURNS TRIGGER AS $$
	DECLARE
		nouvelles_penalites NUMERIC(10,2); -- nouvelle penalite quand on avance/recule la date
		penalites_client client.penalites%TYPE; 
		idClient client.id_client%TYPE;
		nb_jours_retard_rajoute INTEGER; -- difference ancienne date courante avec nouvelle
		dateRendu emprunts.date_rendu%TYPE; 
		dateEmprunt emprunts.date_emprunt%TYPE;
		dateInscription client.date_inscription%TYPE;
		
	BEGIN
		
		nb_jours_retard_rajoute = NEW.date - OLD.date;
		
		FOR idClient IN SELECT client.id_client FROM client LOOP
					
			SELECT emprunts.date_emprunt INTO dateEmprunt 
				FROM emprunts
					WHERE emprunts.id_client = idClient;
					
			SELECT client.date_inscription INTO dateInscription
				FROM client
					WHERE client.id_client = idClient;
				
			IF fin_abonnement(idClient) = TRUE THEN--Si fin d'abonnement du client
				IF is_late(idClient) = FALSE THEN 
					RAISE NOTICE 'L"abonnement datant du % pour le client % a pris fin',dateInscription, idClient;
					DELETE FROM client WHERE id_client = idClient;
				ELSE
					RAISE NOTICE 'Fin d"abonnment du client % mais exemplaires non rendus : ',idClient;
				END	IF;		
			END IF;
			
			IF is_late(idClient) = TRUE THEN
				
				 
				SELECT client.penalites INTO penalites_client --je stocke les pénalités de base pour chaque client en retard
					FROM client
						WHERE client.id_client = idClient;
				
				nouvelles_penalites = penalites_client + penalites_accumulees(idClient,nb_jours_retard_rajoute,OLD.date);
				
				UPDATE client 
				SET penalites = nouvelles_penalites
				WHERE id_client = idClient;
				RAISE NOTICE 'penalites actuelle du client % = %', idClient, nouvelles_penalites;
			
				IF nouvelles_penalites >= 15 THEN 
					RAISE NOTICE 'Le montant de pénalités du client % a atteind au minimum 15 euros', idClient;
				END IF;
			ELSE
				
				SELECT emprunts.date_rendu INTO dateRendu --je stocke la date de rendu de chaque client
					FROM emprunts 
						WHERE emprunts.id_client = idClient;
					
				IF NEW.date - dateRendu >= 60 AND dateRendu IS NOT NULL THEN --si emprunt vieux de + de 2 mois
					DELETE FROM emprunts WHERE emprunts.date_rendu = dateRendu;
					RAISE NOTICE 'emprunts du client % datant du % supprimé', idClient, dateEmprunt;
				ELSE
					PERFORM alerteRendreDans2jours(idClient);
				END IF;
			END IF;	
		END LOOP;
		RETURN NEW;				
	END;
$$ LANGUAGE plpgsql;

--NEW : insert or update 
--OLD : delete or update

CREATE TRIGGER execute_updateDateCourante
	AFTER INSERT OR UPDATE OF date ON date_courante 
	FOR EACH ROW EXECUTE PROCEDURE updateDateCourante();
	
--Vérifie si un client est en retard
/*CREATE OR REPLACE FUNCTION is_late(idClient INTEGER)
RETURNS BOOLEAN AS $$
	DECLARE
		late BOOLEAN;
		curs CURSOR FOR SELECT id_exemplaire FROM emprunts WHERE emprunts.id_client = idClient;
		
	BEGIN
		FOR ligne IN curs LOOP
			IF is_late_exemplaire(idClient,ligne.id_exemplaire) = TRUE THEN
				late = TRUE;
			ELSE
				late = FALSE;
			END IF;
		END LOOP;
		RETURN late;
	END;
$$ LANGUAGE plpgsql;*/	
