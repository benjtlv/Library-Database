DROP FUNCTION IF EXISTS emprunte();
DROP FUNCTION IF EXISTS abonnement_ok();
DROP FUNCTION IF EXISTS is_late();
DROP FUNCTION IF EXISTS nb_exemplaires_en_retard();
DROP FUNCTION IF EXISTS max_limite_emprunts_40();
DROP FUNCTION IF EXISTS max_limite_emprunts_biblio();
DROP FUNCTION IF EXISTS max_limite_emprunts_DVD();
DROP FUNCTION IF EXISTS max_limite_emprunts_nouveaute();
DROP FUNCTION IF EXISTS max_limite_emprunts_ok();
DROP TRIGGER execute_emprunte ON emprunts CASCADE;
DROP FUNCTION IF EXISTS max_limite_reservation();
DROP TRIGGER execute_reservation ON reserve CASCADE;
DROP FUNCTION IF EXISTS miseAjourPenalitesDefaut();
DROP FUNCTION IF EXISTS miseAjourPenalites();
DROP FUNCTION IF EXISTS alerteRendreDans2jours();
DROP FUNCTION IF EXISTS updateDateCourante();
DROP TRIGGER execute_updateDateCourante ON date_courante CASCADE;


/*CREATE OR REPLACE FUNCTION retard_emprunt()
RETURNS TRIGGER AS $$
	DECLARE
		date_retour_prevu DATE; --la date de retour prévu du document
		nb_jours_retard INT;
		penalite_retard FLOAT;
		nb INT;
	BEGIN
		date_retour_prevu = old.date_emprunt + 21;
		IF new.date_rendu > date_retour_prevu THEN
			nb_jours_retard = new.date_rendu - date_retour_prevu;
			penalite_retard = nb_jours_retard * 0.15;
			UPDATE client SET penalites = penalite_retard
			WHERE id_client IN 
			(SELECT client.id_client FROM emprunts WHERE new.date_rendu > date_retour_prevu); 
		END IF;
		RETURN new;
	END;
$$LANGUAGE plpgsql;	*/

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

--Vérifie si un client peut encore emprunter dans la même bibliotheque par rapport au nombre d'emprunts max(20 en tout)
CREATE OR REPLACE FUNCTION max_limite_emprunts_biblio(idClient INTEGER,idBiblio INTEGER)
RETURNS BOOLEAN AS $$	
	DECLARE
		peut_emprunter BOOLEAN;
		
	BEGIN
		SELECT count(*) < 20 INTO peut_emprunter FROM emprunts
		NATURAL JOIN exemplaire
			WHERE id_client = idClient 
			AND date_rendu IS NULL
			AND id_bibliotheque = idBiblio;
			
		IF peut_emprunter = FALSE THEN
			RAISE 'Le client % a dépassé le nombre limite d"emprunts dans la bibliotheque %' ,idClient,idBiblio;
		END IF;	
		RETURN peut_emprunter;
	END;	
$$ LANGUAGE plpgsql;

--Vérifie si un client peut emprunter un nouveau DVD par rapport au nombre max d'emprunts de DVD(5 en tout)
CREATE OR REPLACE FUNCTION max_limite_emprunts_DVD(idClient INTEGER)
RETURNS BOOLEAN AS $$
	DECLARE
		peut_emprunter_DVD BOOLEAN;
		
	BEGIN
		SELECT count(*) < 5 INTO peut_emprunter_DVD FROM emprunts
		NATURAL JOIN exemplaire
			WHERE id_client = idClient
			AND date_rendu IS NULL
			AND support LIKE 'DVD';
			
		IF peut_emprunter_DVD = FALSE THEN
			RAISE 'Le client % a dépassé le nombre limite d"emprunts de DVD (5)', idClient;
		END IF;	
		RETURN peut_emprunter_DVD;
	END;		
$$ LANGUAGE plpgsql;

--Vérifie si un client peut emprunter une nouveauté par rapport au nombre max d'emprunts de nouveautés(3 en tout)
CREATE OR REPLACE FUNCTION max_limite_emprunts_nouveaute(idClient INTEGER)
RETURNS BOOLEAN AS $$
	DECLARE
		peut_emprunter_nouveaute BOOLEAN;
			
	BEGIN
		SELECT count(*) < 3 INTO peut_emprunter_nouveaute FROM emprunts
		NATURAL JOIN exemplaire
			WHERE id_client = idClient
			AND date_rendu IS NULL
			AND (select date from date_courante) - date_entree < 7;
			
		IF peut_emprunter_nouveaute = FALSE THEN
			RAISE 'Le client % a dépassé le nombre limite d"emprunts de nouveautés',idClient;
		END IF;
		RETURN peut_emprunter_nouveaute;
	END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION max_limite_emprunts_ok(idClient INTEGER,idExemplaire INTEGER,idBibliotheque INTEGER)
RETURNS BOOLEAN AS $$
	DECLARE
		exemplaire_is_nouveaute BOOLEAN;
		support_DVD exemplaire.support%TYPE;
	
	BEGIN
		SELECT (exemplaire.id_exemplaire = idExemplaire) INTO exemplaire_is_nouveaute FROM exemplaire --va dire si idExemplaire est une nouveauté ou pas
			WHERE (SELECT date FROM date_courante) - exemplaire.date_entree < 7 AND id_exemplaire = idExemplaire;
		
		/*SELECT (SELECT date FROM date_courante) - exemplaire.date_entree < 7 INTO exemplaire_is_nouveaute FROM exemplaire WHERE id_exemplaire = idExemplaire;*/
		
		SELECT exemplaire.support INTO support_DVD FROM exemplaire --va dire si idExemplaire est un DVD ou pas
			WHERE exemplaire.support LIKE 'DVD'
			AND exemplaire.id_exemplaire = idExemplaire;
		
		IF max_limite_emprunts_40(idClient) = TRUE THEN
			IF max_limite_emprunts_biblio(idClient,idBibliotheque) = TRUE THEN
				IF exemplaire_is_nouveaute = TRUE THEN
					RETURN max_limite_emprunts_nouveaute(idClient);
				ELSE 
					IF support_DVD LIKE 'DVD' THEN
						RETURN max_limite_emprunts_DVD(idClient);
					ELSE 
						RETURN TRUE;
					END IF;	
				END IF;
			ELSE 
				RETURN FALSE;
			END IF	;
		ELSE
			RETURN FALSE;
		END IF;			
	END;
$$ LANGUAGE plpgsql;	
		

			
--Vérifie si un client est en retard
CREATE OR REPLACE FUNCTION is_late(idClient INTEGER)
RETURNS BOOLEAN AS $$
	DECLARE
		late BOOLEAN;
		
	BEGIN
		SELECT count(*) > 0 INTO late FROM emprunts
			WHERE emprunts.id_client = idClient 
			AND emprunts.date_emprunt + 21 <= (SELECT date FROM date_courante) 
			AND emprunts.date_rendu IS NULL;
		RETURN late;
	END;
$$ LANGUAGE plpgsql;

--Retourne le nombre d'exemplaires en retard pour un client donné
CREATE OR REPLACE FUNCTION nb_exemplaires_en_retard(idClient INTEGER)
RETURNS INTEGER AS $$
	DECLARE
		nb_exemplaires INTEGER;
		
	BEGIN
		SELECT count(*) INTO nb_exemplaires FROM emprunts
			WHERE emprunts.id_client = idClient
			AND emprunts.date_emprunt + 21 <= (select date from date_courante)
			AND emprunts.date_rendu IS NULL;
			
		RETURN nb_exemplaires;
	END;
$$ LANGUAGE plpgsql;

--Retourne le nombre de jours en retard pour un exemplaire donné
CREATE OR REPLACE FUNCTION nb_jours_en_retard(idExemplaire INTEGER)
RETURNS INTEGER AS $$
	DECLARE
		dateCourante date_courante.date%TYPE;
		dateEmprunt emprunts.date_emprunt%TYPE;
		nb_jours INTEGER;
	
	BEGIN
		SELECT date_courante.date INTO dateCourante FROM date_courante;
		
		SELECT emprunts.date_emprunt INTO dateEmprunt
			FROM emprunts
				WHERE emprunts.id_exemplaire = idExemplaire;
		
		nb_jours = dateCourante - (dateEmprunt + 21);
		
		RETURN nb_jours;
	END;
$$ LANGUAGE plpgsql;	

--Vérifie si un client peut emprunter selon son type d'abonnement
CREATE OR REPLACE FUNCTION abonnement_ok(idClient INTEGER, idExemplaire INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
	support exemplaire.support%TYPE;
	type_abo client.type_abonnement%TYPE;
	
BEGIN
	SELECT exemplaire.support INTO support 
		FROM exemplaire 
			WHERE exemplaire.id_exemplaire = idExemplaire;
			
	SELECT client.type_abonnement INTO type_abo 
		FROM client 
			WHERE client.id_client = idClient;
			
	IF support LIKE 'DVD' THEN
		IF type_abo LIKE 'CD/DVD' THEN
			RETURN TRUE;
		ELSE
			RAISE NOTICE 'le client % veut emprunter un DVD mais ne dispose pas de labonnement CD/DVD',idClient;
			RETURN FALSE;
		END IF;
	ELSIF support LIKE 'CD-ROM' THEN 
		IF type_abo LIKE 'CD' OR type_abo LIKE 'CD/DVD' THEN
			RETURN TRUE;
		ELSE
			RAISE NOTICE 'le client % veut emprunter un CD-ROM mais ne dispose pas de labonnement CD',idClient;
			RETURN FALSE;
		END IF;
	ELSE
		RETURN TRUE;
	END IF;
END;
$$ LANGUAGE plpgsql;

--/////////////////////////////////////////////

--Vérifie si un client peut emprunté un exemplaire d'un document(pas plus de 15€ de pénalité,exemplaire pas emprunté,pas réservé etc..) 
CREATE OR REPLACE FUNCTION emprunte()
RETURNS TRIGGER AS $$
	DECLARE is_emprunte BOOLEAN;
	DECLARE is_reserve BOOLEAN;
	DECLARE bloque BOOLEAN := FALSE;
	DECLARE idBiblio exemplaire.id_bibliotheque%TYPE;
	
	BEGIN
		SELECT (NEW.id_exemplaire = emprunts.id_exemplaire) INTO is_emprunte 
			FROM emprunts
				WHERE emprunts.id_exemplaire = NEW.id_exemplaire AND emprunts.date_rendu IS NULL;
		
		SELECT (NEW.id_exemplaire = reserve.id_exemplaire) INTO is_reserve 
			FROM reserve
				WHERE reserve.id_exemplaire = NEW.id_exemplaire;
		
		SELECT client.penalites >= 15 INTO bloque 
			FROM client
				WHERE NEW.id_client = client.id_client;
		
		SELECT exemplaire.id_bibliotheque INTO idBiblio --va récupérer dans idBiblio, l'id de la bibliotheque où on va emprunter
			FROM exemplaire
				WHERE exemplaire.id_exemplaire = NEW.id_exemplaire;
		
		IF bloque = FALSE THEN
			IF abonnement_ok(NEW.id_client,NEW.id_exemplaire) = TRUE THEN
				IF is_late(NEW.id_client) = FALSE THEN
					IF is_emprunte = TRUE THEN
						RAISE 'impossible d"emprunter, exemplaire % déjà emprunté',NEW.id_exemplaire;
					ELSIF is_reserve = TRUE THEN
						RAISE 'impossible d"emprunter, exemplaire % déjà réservé',NEW.id_exemplaire;
					ELSIF max_limite_emprunts_ok(NEW.id_client,NEW.id_exemplaire,idBiblio) = TRUE THEN --dernière condition pour emprunter
						RAISE NOTICE 'exemplaire % du document % emprunté par le client %',NEW.id_exemplaire,NEW.id_document,NEW.id_client;
					END IF;
				ELSE
					RAISE 'le client % est en retard, il doit rendre tous ses exemplaires empruntés => pas d"emprunts',NEW.id_client;
				END IF;
			ELSE
				RETURN NULL;
			END IF;
		ELSE
			RAISE 'client % bloqué : emprunts non autorisés',NEW.id_client;
		END IF;
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER execute_emprunte
	BEFORE INSERT OR UPDATE OF id_exemplaire ON emprunts
	FOR EACH ROW EXECUTE PROCEDURE emprunte();

--//////////////////////////////////////////////////////////

--Vérifie si un client peut encore emprunter par rapport au nombre d'emprunts max(40 en tout)
CREATE OR REPLACE FUNCTION max_limite_reservation(idClient INTEGER)
RETURNS BOOLEAN AS $$
	DECLARE
		peut_reserver BOOLEAN;
		
	BEGIN
		SELECT count(*) < 5 FROM reserve INTO peut_reserver
			WHERE reserve.id_client = idClient
			AND reserve.id_exemplaire IN
				(SELECT emprunts.id_exemplaire FROM emprunts 
					WHERE emprunts.date_rendu IS NULL); --AND emprunts.id_client != idClient si on veut pas que le client réserve un exemplaire que lui même à emprunter
		IF peut_reserver = FALSE THEN
			RAISE 'Le client % a dépassé le nombre limite de réservations',idClient;
		END IF;	
		RETURN peut_reserver;
	END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION reservation()
RETURNS TRIGGER AS $$
	DECLARE 
		is_emprunte BOOLEAN;
		is_reserve BOOLEAN;
		bloque BOOLEAN := FALSE;
		
	BEGIN
		SELECT (NEW.id_exemplaire = emprunts.id_exemplaire) INTO is_emprunte 
			FROM emprunts
				WHERE emprunts.id_exemplaire = NEW.id_exemplaire AND emprunts.date_rendu IS NULL;
		
		SELECT (NEW.id_exemplaire = reserve.id_exemplaire) INTO is_reserve 
			FROM reserve
				WHERE reserve.id_exemplaire = NEW.id_exemplaire;
		
		SELECT client.penalites >= 15 INTO bloque 
			FROM client
				WHERE NEW.id_client = client.id_client;
		
		IF bloque = FALSE THEN
			IF abonnement_ok(NEW.id_client,NEW.id_exemplaire) = TRUE THEN
				IF is_emprunte = TRUE THEN
					IF is_late(NEW.id_client) = FALSE THEN
						IF max_limite_reservation(NEW.id_client) = TRUE THEN
							RAISE NOTICE 'exemplaire % du document % emprunté par le client %',NEW.id_exemplaire,NEW.id_document,NEW.id_client;
						END IF;	
					ELSE
						RAISE 'le client % est en retard, il doit rendre tous ses exemplaires empruntés => pas de réservation',NEW.id_client;
					END IF;
				ELSE
					RAISE 'le client % ne peut pas réserver l"exemplaire % car il faut que cet exemplaire soit emprunté',NEW.id_client,NEW.id_exemplaire;
				END IF;	
			ELSE
				RETURN NULL;
			END IF;
		ELSE
			RAISE 'client % bloqué : réservations non autorisées',NEW.id_client;
		END IF;
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;
				
CREATE TRIGGER execute_reservation
	BEFORE INSERT OR UPDATE OF id_exemplaire ON reserve
	FOR EACH ROW EXECUTE PROCEDURE reservation();
	
--/////////////////////////////////////////////////////////////////////////

--Mise a jour des jour des pénalités des clients en retard, par défaut	
CREATE OR REPLACE FUNCTION miseAjourPenalitesDefaut()
RETURNS VOID AS $$
	DECLARE
		nb_jours_retard INTEGER;
		idClient client.id_client%TYPE;
		penalites_client client.penalites%TYPE;
		dateCourante date_courante.date%TYPE;
		dateEmprunt emprunts.date_emprunt%TYPE;
		
	BEGIN
		SELECT date_courante.date FROM date_courante INTO dateCourante;
		
		FOR idClient IN SELECT client.id_client FROM client LOOP
			IF is_late(idClient) = TRUE THEN
				SELECT emprunts.date_emprunt FROM emprunts INTO dateEmprunt
					WHERE emprunts.id_client = idClient;
				
				nb_jours_retard = dateCourante - (dateEmprunt + 21);
					
				UPDATE client
				SET penalites = nb_jours_retard * 0.15
				WHERE id_client = idClient;
				RAISE NOTICE 'nb de jours de retard du client % = %',idClient, nb_jours_retard;
				RAISE NOTICE 'penalites client % = %', idClient, nb_jours_retard * 0.15;
			END IF;
		END LOOP;			
	END;
$$ LANGUAGE plpgsql;

--Pour lancer directement la fonction en lançant ce fichier
SELECT miseAjourPenalitesDefaut();		

/*--Mise à jour quotidienne des pénalités des clients en retard sur leurs exemplaires empruntés, après avancement de la date courante
CREATE OR REPLACE FUNCTION miseAjourPenalites()
RETURNS TRIGGER AS $$
	DECLARE
		nb_jours_retard INTEGER;
		idClient client.id_client%TYPE;
		penalites_client client.penalites%TYPE; --conserver l'ancienne valeur des pénalités
	
	BEGIN
	
		nb_jours_retard = NEW.date - OLD.date;
		FOR idClient IN SELECT client.id_client FROM client LOOP
			IF is_late(idClient) = TRUE THEN
				SELECT client.penalites INTO penalites_client
					FROM client
						WHERE client.id_client = idClient; 		
						
				UPDATE client 
				SET penalites = penalites_client + 0.15 * nb_jours_retard
				WHERE id_client = idClient;
				RAISE NOTICE 'penalites actuelle du client % = %', idClient, penalites_client + 0.15 * nb_jours_retard;
			END IF;
		END LOOP;
		RETURN NEW;		
	END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER execute_miseAjourPenalites
	AFTER UPDATE OF date ON date_courante
	FOR EACH ROW EXECUTE PROCEDURE MiseAjourPenalites();


		
--///////////////////////////////////////////////////////

--Avertir que le client a atteint l'amende de 15 euros
CREATE OR REPLACE FUNCTION alerte15euros()
RETURNS TRIGGER AS $$
	DECLARE
		idClient client.id_client%TYPE;
		
	BEGIN
		SELECT client.id_client INTO idClient
			FROM client WHERE client.penalites = NEW.penalites;
		
		IF NEW.penalites >= 15 THEN
			RAISE NOTICE 'Le montant de pénalités du client % a attend au minimum 15 euros', idClient;
		END IF;
		RETURN NEW;
	END
$$ LANGUAGE plpgsql;

CREATE TRIGGER execute_alerte15euros
	AFTER INSERT OR UPDATE OF penalites ON client
	FOR EACH ROW EXECUTE PROCEDURE alerte15euros();
		
--////////////////////////////////////////////////////////////////

--Avertir que le client doit rendre le livre dans 2 jours
CREATE OR REPLACE FUNCTION alerteRendreDans2jours()
RETURNS TRIGGER AS $$
	DECLARE
		idClient client.id_client%TYPE;
		dateCourante date_courante.date%TYPE;
		dateEmprunt emprunts.date_emprunt%TYPE;
	
	BEGIN
		SELECT date_courante.date INTO dateCourante FROM date_courante;
		
		FOR idClient IN SELECT client.id_client FROM client LOOP
			
			SELECT emprunts.date_emprunt INTO dateEmprunt FROM emprunts
			WHERE emprunts.id_client = idClient
		
*/

--Mise à jour quotidienne des pénalités des clients en retard sur leurs exemplaires empruntés
CREATE OR REPLACE FUNCTION miseAjourPenalites(idClient INTEGER, nb_jours_retard INTEGER)
RETURNS VOID AS $$
	DECLARE
		penalites_client client.penalites%TYPE;
		nouvelles_penalites client.penalites%TYPE;
		
	BEGIN
		IF is_late(idClient) = TRUE THEN
			SELECT client.penalites INTO penalites_client 
				FROM client
					WHERE client.id_client = idClient;
			
			nouvelles_penalites = penalites_client + 0.15 * nb_jours_retard;
					
			UPDATE client 
			SET penalites = nouvelles_penalites
			WHERE id_client = idClient;
			RAISE NOTICE 'penalites actuelle du client % = %', idClient, nouvelles_penalites;
			
			IF nouvelles_penalites >= 15 THEN 
				RAISE NOTICE 'Le montant de pénalités du client % a attend au minimum 15 euros', idClient;
			END IF;
		END IF;
	END;
$$ LANGUAGE plpgsql;

--Alerte quand le client doit rendre le livre dans 2 jours
CREATE OR REPLACE FUNCTION alerteRendreDans2jours(idClient INTEGER)
RETURNS VOID AS $$
	DECLARE
		dateCourante date_courante.date%TYPE;
		dateEmpruntClient emprunts.date_emprunt%TYPE;
	
	BEGIN
		SELECT date_courante.date INTO dateCourante FROM date_courante;
		
		SELECT emprunts.date_emprunt INTO dateEmpruntClient
			FROM emprunts
				WHERE emprunts.id_client = idClient;
				
		IF dateCourante = dateEmpruntClient + 19 THEN
			RAISE NOTICE 'Le client % doit rendre dans 2 jours l"exemplaire emprunté',idClient;
		END IF;		
	END;
$$ LANGUAGE plpgsql;	


CREATE OR REPLACE FUNCTION updateDateCourante()
RETURNS TRIGGER AS $$
	DECLARE
		idClient client.id_client%TYPE;
		nb_jours_retard INTEGER;
		
	BEGIN
		nb_jours_retard = NEW.date - OLD.date;
		
		FOR idClient IN SELECT client.id_client FROM client LOOP
			PERFORM miseAjourPenalites(idClient,nb_jours_retard);
			PERFORM alerteRendreDans2jours(idClient);
		END LOOP;
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER execute_updateDateCourante
	AFTER INSERT OR UPDATE OF date ON date_courante
	FOR EACH ROW EXECUTE PROCEDURE updateDateCourante();		

--Va dire si un client donné a fait une réservation sur un exemplaire donné
CREATE OR REPLACE FUNCTION a_fait_reservation(idClient INTEGER, idExemplaire INTEGER)
RETURNS BOOLEAN AS $$
	DECLARE
		reservation_faite BOOLEAN;
	
	BEGIN
		SELECT count(*) > 0 INTO reservation_faite FROM reserve
			WHERE reserve.id_client = idClient
			AND reserve.id_exemplaire = idExemplaire;
			
		RETURN reservation_faite;
			
	END;
$$ LANGUAGE plpgsql;
	
--Va faire en sorte que si un client a fait une réservation sur un exemplaire, il pourra l'emprunter automatiquement si un autre l'a rendu
CREATE OR REPLACE FUNCTION emprunter_apres_reservation()		
RETURNS TRIGGER AS $$
	DECLARE
		idClient client.id_client%TYPE;
		idExemplaire emprunts.id_exemplaire%TYPE;
		idDocument emprunts.id_document%TYPE;
	
	BEGIN
		SELECT emprunts.id_exemplaire INTO idExemplaire FROM emprunts --on sélectionne l'exemplaire qui vient d'être rendu
			WHERE NEW.date_rendu IS NOT NULL;
			
		SELECT emprunts.id_document INTO idDocument FROM emprunts --on sélectionne le document qui vient d'être rendu
			WHERE NEW.date_rendu IS NOT NULL;	
			
		RAISE NOTICE 'exemplaire % et document %', idExemplaire, idDocument;
		RAISE NOTICE 'nouvelle date rendu %', NEW.date_rendu;
		
		FOR idClient IN SELECT client.id_client FROM client LOOP
			IF a_fait_reservation(idClient,idExemplaire) = TRUE THEN
				INSERT INTO emprunts(id_client,id_exemplaire,id_document,date_emprunt,date_rendu) VALUES
					(idClient,idExemplaire,idDocument,NEW.date_rendu,null);
			END IF;
		END LOOP;
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER execute_emprunter_apres_reservation
	AFTER UPDATE OF date_rendu ON emprunts
	FOR EACH ROW EXECUTE PROCEDURE emprunter_apres_reservation();
	
--/////////////////////////////////////////////////////////////////////				

