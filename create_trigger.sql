DROP FUNCTION IF EXISTS nb_emprunts_biblio(INTEGER);
DROP FUNCTION IF EXISTS nb_emprunts_total();
DROP FUNCTION IF EXISTS abonnement_ok(INTEGER,INTEGER);
DROP FUNCTION IF EXISTS get_duree_emprunt(DATE);
DROP FUNCTION IF EXISTS is_late_exemplaire(INTEGER,INTEGER);
DROP FUNCTION IF EXISTS is_late(INTEGER);
DROP FUNCTION IF EXISTS nb_jours_en_retard(INTEGER);
DROP FUNCTION IF EXISTS est_a_3semaines_finAbo(INTEGER);
DROP FUNCTION IF EXISTS max_limite_emprunts_40(INTEGER);
DROP FUNCTION IF EXISTS max_limite_emprunts_biblio(INTEGER,INTEGER);
DROP FUNCTION IF EXISTS max_limite_emprunts_DVD(INTEGER);
DROP FUNCTION IF EXISTS max_limite_emprunts_nouveaute(INTEGER);
DROP FUNCTION IF EXISTS max_limite_emprunts_ok(INTEGER,INTEGER,INTEGER);
DROP FUNCTION IF EXISTS emprunte();
DROP TRIGGER execute_emprunte ON emprunts CASCADE; --ok
DROP FUNCTION IF EXISTS max_limite_reservation(INTEGER);
DROP FUNCTION IF EXISTS reservation();
DROP TRIGGER execute_reservation ON reserve CASCADE; --ok
DROP FUNCTION IF EXISTS actualisationPenalites(INTEGER);--a voir a la fin
DROP FUNCTION IF EXISTS actualisationPenalitesDefaut();--a voir a la fin
DROP FUNCTION IF EXISTS penalites_accumulees(INTEGER,INTEGER,DATE);
DROP FUNCTION IF EXISTS alerteRendreDans2jours(INTEGER);
DROP FUNCTION IF EXISTS fin_abonnement(INTEGER);
DROP FUNCTION IF EXISTS renouvellement_inscription(INTEGER);
DROP FUNCTION IF EXISTS avancer_date(INTEGER);
DROP FUNCTION IF EXISTS reculer_date(INTEGER);
DROP FUNCTION IF EXISTS updateDateCourante();
DROP TRIGGER execute_updateDateCourante ON date_courante CASCADE; --ok
DROP FUNCTION IF EXISTS renouvellement_exemplaire(INTEGER);
DROP FUNCTION IF EXISTS a_fait_reservation(INTEGER,INTEGER);
DROP FUNCTION IF EXISTS alerte_rendu_exemplaire();
DROP TRIGGER execute_alerte_rendu_exemplaire ON emprunts CASCADE;



CREATE OR REPLACE FUNCTION nb_emprunts_biblio(idBiblio INTEGER)
RETURNS INTEGER AS $$
	DECLARE
		nb_emprunts INTEGER;
		
	BEGIN
		SELECT count(*) INTO nb_emprunts
			FROM exemplaire
			NATURAL JOIN emprunts
				WHERE exemplaire.id_bibliotheque = idBiblio;
		
		RETURN nb_emprunts;		
	END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION nb_emprunts_total()
RETURNS INTEGER AS $$
	DECLARE
		nb_total INTEGER;
		
	BEGIN
		SELECT count(*) INTO nb_total FROM emprunts;
		
		RETURN nb_total;
	END;	
$$ LANGUAGE plpgsql;


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
			RAISE 'Le client % a dépassé le nombre limite d"emprunts dans la bibliothèque %' ,idClient,idBiblio;
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
			AND (SELECT date FROM date_courante) - date_entree < 7;
			
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

--Renvoie la durée d'emprunt en fonction d'une date donné
CREATE OR REPLACE FUNCTION get_duree_emprunt(d DATE)
RETURNS INTEGER AS $$
	BEGIN
		IF EXTRACT(MONTH FROM d) BETWEEN EXTRACT(MONTH FROM DATE '2016-06-21') AND EXTRACT(MONTH FROM DATE '2016-09-20') THEN
			return 42;
		ELSE	
			return 21;
		END IF;
	END;
$$ LANGUAGE plpgsql;
		
--Vérifie si un exemplaire donné d'un client donné est en retard
CREATE OR REPLACE FUNCTION is_late_exemplaire(idClient INTEGER, idExemplaire INTEGER)
RETURNS BOOLEAN AS $$
	DECLARE
		ligne RECORD;
		
	BEGIN
		SELECT date_emprunt,date_rendu INTO ligne
			FROM emprunts
				WHERE emprunts.id_client = idClient
				AND emprunts.id_exemplaire = idExemplaire;
				
		IF ligne.date_emprunt + get_duree_emprunt(ligne.date_emprunt) <= (SELECT date FROM date_courante) AND ligne.date_rendu IS NULL THEN
			RETURN TRUE;
		ELSE
			RETURN FALSE;
		END IF;
	END;
$$ LANGUAGE plpgsql;
			
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

CREATE OR REPLACE FUNCTION is_late(idClient INTEGER)
RETURNS BOOLEAN AS $$
	DECLARE
		late BOOLEAN;
		--curs CURSOR FOR SELECT id_exemplaire FROM emprunts WHERE emprunts.id_client = idClient;
		--idExemplaire emprunts.id_exemplaire%TYPE;
	BEGIN
		SELECT count(*) > 0 INTO late FROM emprunts 
			WHERE emprunts.id_client = idClient
			AND is_late_exemplaire(idClient,emprunts.id_exemplaire) = TRUE;
		RETURN late;
	END;
$$ LANGUAGE plpgsql;



--Retourne le nombre de jours de retard d'un exemplaire donné depuis la date prevu de retour de cet exemplaire
CREATE OR REPLACE FUNCTION nb_jours_en_retard(idExemplaire INTEGER)
RETURNS INTEGER AS $$
	DECLARE
		dateCourante date_courante.date%TYPE;
		dateEmprunt emprunts.date_emprunt%TYPE;
	
	BEGIN
		SELECT date_courante.date INTO dateCourante FROM date_courante;
		
		SELECT emprunts.date_emprunt INTO dateEmprunt
			FROM emprunts
				WHERE emprunts.id_exemplaire = idExemplaire
				AND emprunts.date_rendu IS NULL;
		
		RETURN dateCourante - (dateEmprunt + get_duree_emprunt(dateEmprunt));
	END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION est_a_3semaines_finAbo(idClient INTEGER)
RETURNS BOOLEAN AS $$
	DECLARE
		dateInscription client.date_inscription%TYPE;
		dateCourante date_courante.date%TYPE;
		
	BEGIN
		SELECT client.date_inscription INTO dateInscription
			FROM client
				WHERE client.id_client = idClient;
				
		SELECT date_courante.date INTO dateCourante FROM date_courante;
		
		IF (dateInscription + 365) - dateCourante <= 21 THEN --Si on est dans la période des 3 semaines avant la fin d'inscription		 
			RETURN TRUE;
		ELSE
			RETURN FALSE;
		END IF;
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
				RAISE NOTICE 'le client % veut emprunter/réserver un DVD mais ne dispose pas de labonnement CD/DVD',idClient;
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
	DECLARE is_emprunte BOOLEAN; --vérifie si il est déja emprunté par qqn d'autre
	DECLARE is_reserve BOOLEAN;
	DECLARE bloque BOOLEAN := FALSE;
	DECLARE idBiblio exemplaire.id_bibliotheque%TYPE;
	
	BEGIN
		SELECT (NEW.id_exemplaire = emprunts.id_exemplaire) INTO is_emprunte 
			FROM emprunts
				WHERE emprunts.id_exemplaire = NEW.id_exemplaire
				AND emprunts.id_client <> NEW.id_client
				AND emprunts.date_rendu IS NULL;
		
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
						IF est_a_3semaines_finAbo(NEW.id_client) = FALSE THEN
							RAISE NOTICE 'exemplaire % du document % emprunté par le client %',NEW.id_exemplaire,NEW.id_document,NEW.id_client;
						ELSE
							RAISE 'impossible d"emprunter l"exemplaire %, le client % doit renouveler son abonnement',NEW.id_exemplaire,NEW.id_client;
						END IF;
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
	BEFORE INSERT ON emprunts
	FOR EACH ROW EXECUTE PROCEDURE emprunte();
	
	

--//////////////////////////////////////////////////////////

--Vérifie si un client peut encore emprunter par rapport au nombre de réservations max(5 en tout)
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
				IF is_emprunte = FALSE THEN
					RAISE 'le client % ne peut pas réserver l"exemplaire % car il faut que cet exemplaire soit emprunté',NEW.id_client,NEW.id_exemplaire;
				ELSIF is_reserve = TRUE THEN
					RAISE 'Le client % ne peut pas réserver l"exemplaire % car il est déja réservé par un autre client',NEW.id_client,NEW.id_exemplaire;
				ELSE
					IF is_late(NEW.id_client) = FALSE THEN
						IF max_limite_reservation(NEW.id_client) = TRUE THEN
							IF est_a_3semaines_finAbo(NEW.id_client) = FALSE THEN
								RAISE NOTICE 'exemplaire % du document % réservé par le client %',NEW.id_exemplaire,NEW.id_document,NEW.id_client;
							ELSE
								RAISE 'impossible de réserver l"exemplaire %, le client % doit renouveler son abonnement',NEW.id_exemplaire,NEW.id_client;
							END IF;	
						END IF;	
					ELSE
						RAISE 'le client % est en retard, il doit rendre tous ses exemplaires empruntés => pas de réservation',NEW.id_client;
					END IF;
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

--Mise à jour des pénalités d'un client donné

CREATE OR REPLACE FUNCTION actualisationPenalites(idClient INTEGER)
RETURNS VOID AS $$
	DECLARE
		idExemplaire emprunts.id_exemplaire%TYPE;
		penalites_client client.penalites%TYPE;
		nouvelles_penalites NUMERIC(10,2);
		
	BEGIN
		SELECT client.penalites INTO penalites_client
			FROM client
				WHERE client.id_client = idClient;
		
		nouvelles_penalites = 0;		
		
		FOR idExemplaire IN SELECT emprunts.id_exemplaire FROM emprunts WHERE emprunts.id_client = idClient 
																		AND is_late_exemplaire(idClient,emprunts.id_exemplaire) = TRUE LOOP
													
			nouvelles_penalites = nouvelles_penalites + (0.15 * nb_jours_en_retard(idExemplaire));

		END LOOP;
		
		UPDATE client 
		SET penalites = nouvelles_penalites
		WHERE id_client = idClient;
		
	END;
$$ LANGUAGE plpgsql;

--Mise a jour des jour des pénalités des clients en retard, par défaut
CREATE OR REPLACE FUNCTION actualisationPenalitesDefaut()
RETURNS VOID AS $$
	DECLARE
		idClient client.id_client%TYPE;
		penalites_client client.penalites%TYPE;
		
	BEGIN
		FOR idClient IN SELECT client.id_client FROM client LOOP
			IF is_late(idClient) = TRUE THEN
				PERFORM actualisationPenalites(idClient);
				
				SELECT client.penalites INTO penalites_client
					FROM client
						WHERE client.id_client = idClient;
				
				RAISE NOTICE 'penalites du client %  = %', idClient, penalites_client;
			END IF;
		END LOOP;
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
				WHERE emprunts.id_client = idClient
				AND emprunts.date_rendu IS NULL;
				
		IF dateCourante = dateEmpruntClient + (get_duree_emprunt(dateEmpruntClient) - 2) THEN
			RAISE NOTICE 'Le client % doit rendre dans 2 jours l"exemplaire emprunté',idClient;
		END IF;		
	END;
$$ LANGUAGE plpgsql;

--Retourne les pénalités accumulées d'un client donné, en fonction du nombre de jours de retard rajouté n
--prev pour savoir si on a avancé la date courante à partir d'un jour avant la date butoire
CREATE OR REPLACE FUNCTION penalites_accumulees(idClient INTEGER, n INTEGER, prev DATE)
RETURNS NUMERIC AS $$
	DECLARE
		dateCourante date_courante.date%TYPE;
		dateButoire DATE;
		ligne RECORD;
		pen_accumule NUMERIC(10,2);
		
	BEGIN
		SELECT date_courante.date INTO dateCourante FROM date_courante;
	
		pen_accumule = 0;
		
		FOR ligne IN SELECT emprunts.id_exemplaire, emprunts.date_emprunt FROM emprunts WHERE emprunts.id_client = idClient 
																		AND is_late_exemplaire(idClient,emprunts.id_exemplaire) = TRUE LOOP
			
			dateButoire = ligne.date_emprunt + get_duree_emprunt(ligne.date_emprunt);
			
			IF prev < dateButoire AND dateCourante - dateButoire >= 0 THEN
					pen_accumule = pen_accumule + (0.15 * (dateCourante - dateButoire));
			ELSE
				pen_accumule = pen_accumule + (0.15 * n);
			END IF;
			
		END LOOP;
		RETURN pen_accumule;
	END;
$$ LANGUAGE plpgsql;

--Vérifie si le client est arrivé à terme de son abonnement
CREATE OR REPLACE FUNCTION fin_abonnement(idClient INTEGER)
RETURNS BOOLEAN AS $$
	DECLARE
		fin_abo BOOLEAN;
		dateCourante date_courante.date%TYPE;
	
	BEGIN
		
		SELECT date INTO dateCourante FROM date_courante;
	
		SELECT count(*) > 0 INTO fin_abo
			FROM client
				WHERE dateCourante > client.date_inscription + 365
				AND client.id_client = idClient;
		
		RETURN fin_abo;		
	END;
$$ LANGUAGE plpgsql;

--Va renouveler l'inscription du client pris en paramètre
CREATE OR REPLACE FUNCTION renouvellement_inscription(idClient INTEGER)
RETURNS VOID AS $$
	DECLARE
		dateInscription client.date_inscription%TYPE;
	
	BEGIN
		IF is_late(idClient) = TRUE THEN
			RAISE 'Le client % ne peut pas renouveler son abonnement car il est en retard sur ses exemplaires',idClient;
		ELSE
			IF est_a_3semaines_finAbo(idClient) = FALSE THEN
				RAISE 'Le client % ne peut pas renouveler son abonnement car ce n"est pas la période',idClient;
			ELSE	
				UPDATE client
				SET date_inscription = date_inscription + 365
				WHERE id_client = idClient;
			END IF;	
		END IF;	
	END;
$$ LANGUAGE plpgsql;

--Va avancer la date courante de nbJours		
CREATE OR REPLACE FUNCTION avancer_date(nbJours INTEGER)
RETURNS VOID AS $$
	BEGIN
		UPDATE date_courante
		SET date = date + nbJours
		WHERE date = (SELECT date FROM date_courante);
	END;
$$ LANGUAGE plpgsql;

--Va reculer la date courante de nbJours		
CREATE OR REPLACE FUNCTION reculer_date(nbJours INTEGER)
RETURNS VOID AS $$
	BEGIN
		UPDATE date_courante
		SET date = date - nbJours
		WHERE date = (SELECT date FROM date_courante);
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

CREATE TRIGGER execute_updateDateCourante
	AFTER INSERT OR UPDATE OF date ON date_courante
	FOR EACH ROW EXECUTE PROCEDURE updateDateCourante();
	
--//////////////////////////////////////////////////////////////////////////////

--Va renouveler l'emprunt d'un client
CREATE OR REPLACE FUNCTION renouvellement_exemplaire(idExemplaire INTEGER)
RETURNS VOID AS $$
	DECLARE
		dateCourante date_courante.date%TYPE;
		idClient emprunts.id_client%TYPE;
		is_reserve BOOLEAN;
		
		
	BEGIN
		SELECT date INTO dateCourante FROM date_courante;
		
		SELECT emprunts.id_client INTO idClient 
			FROM emprunts 
				WHERE emprunts.id_exemplaire = idExemplaire;
				
		SELECT count(*) > 1 INTO is_reserve
			FROM reserve
				WHERE reserve.id_exemplaire = idExemplaire;
				
		IF is_late(idClient) = FALSE THEN
			IF is_reserve = FALSE THEN
				UPDATE emprunts
				SET date_emprunt = dateCourante, nb_renouvellements = nb_renouvellements + 1 --on incrémente le nb de renouvellements
				WHERE id_exemplaire = idExemplaire;
				RAISE NOTICE 'Exemplaire % renouvelé ! ',idExemplaire;
			ELSE
				RAISE NOTICE 'Le client % ne peut pas renouveler son emprunt de l"exemplaire % car il est déja réservé',idClient,idExemplaire;
			END IF;
		ELSE
			RAISE NOTICE 'Le client % ne peut pas renouveler son emprunt de l"exemplaire % car il est en retard',idClient,idExemplaire;
		END IF;	
	END;
$$ LANGUAGE plpgsql;	

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

--Va faire une alerte si un exemplaire a été rendu
--Va faire en sorte que si un client a fait une réservation sur un exemplaire, il pourra l'emprunter automatiquement si un autre l'a rendu
CREATE OR REPLACE FUNCTION alerte_rendu_exemplaire()
RETURNS TRIGGER AS $$
	DECLARE
		idExemplaire emprunts.id_exemplaire%TYPE;
		idClient emprunts.id_client%TYPE;
		idDocument emprunts.id_document%TYPE;
		
	BEGIN
		IF NEW.date_rendu IS NOT NULL THEN
				
			SELECT emprunts.id_exemplaire INTO idExemplaire
				FROM emprunts
					WHERE emprunts.date_rendu = NEW.date_rendu;
			
			SELECT emprunts.id_document INTO idDocument
				FROM emprunts
					WHERE emprunts.date_rendu = NEW.date_rendu;
					
			RAISE NOTICE 'L"exemplaire % vient d"être rendu', idExemplaire;				
			
			FOR idClient IN SELECT client.id_client FROM client LOOP
				IF a_fait_reservation(idClient,idExemplaire) = TRUE THEN
					DELETE FROM reserve WHERE reserve.id_client = idClient;
					INSERT INTO emprunts(id_client,id_exemplaire,id_document,date_emprunt,date_rendu,nb_renouvellements) VALUES
						(idClient,idExemplaire,idDocument,NEW.date_rendu,null,0);
				END IF;
			END LOOP;	
		END IF;
		RETURN NEW;			
	END;
$$ LANGUAGE plpgsql;
			
CREATE TRIGGER execute_alerte_rendu_exemplaire
	AFTER INSERT OR UPDATE OF date_rendu ON emprunts
	FOR EACH ROW EXECUTE PROCEDURE alerte_rendu_exemplaire();
	
SELECT actualisationPenalitesDefaut();		

