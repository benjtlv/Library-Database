DROP TABLE IF EXISTS client CASCADE;
DROP TABLE IF EXISTS genre CASCADE;
DROP TABLE IF EXISTS document CASCADE;
DROP TABLE IF EXISTS livre CASCADE;
DROP TABLE IF EXISTS editeur CASCADE;
DROP TABLE IF EXISTS maison_production CASCADE;
DROP TABLE IF EXISTS media CASCADE;
DROP TABLE IF EXISTS bibliotheque CASCADE;
DROP TABLE IF EXISTS exemplaire CASCADE;
DROP TABLE IF EXISTS emprunts CASCADE;
DROP TABLE IF EXISTS reserve CASCADE;
DROP TABLE IF EXISTS doitRembourser CASCADE;
DROP TABLE IF EXISTS date_courante CASCADE;

CREATE TABLE client(
       id_client SERIAL PRIMARY KEY,
       nom VARCHAR(100) NOT NULL,
       prenom VARCHAR(100) NOT NULL,
       date_naissance DATE,
       telephone VARCHAR(10),
       adresse VARCHAR(100),
       codePostal VARCHAR(5),
       ville VARCHAR(20),
       type_abonnement VARCHAR CHECK (type_abonnement IN ('normale','CD','CD/DVD')),
       date_inscription DATE,
       penalites NUMERIC(10,2)/*CHECK (penalites > 0 AND penalites <100)*/,
       UNIQUE(nom,prenom,date_naissance,telephone,adresse,codePostal,ville,type_abonnement) --pas d'inscription d'une même personne
);

CREATE TABLE genre(
       id_genre SERIAL PRIMARY KEY,
       nom_genre VARCHAR(100),
       UNIQUE(nom_genre)
);


CREATE TABLE document(
       id_document SERIAL PRIMARY KEY,
       id_genre INTEGER REFERENCES genre,
       titre VARCHAR NOT NULL,
       annee INT CHECK (annee > 0 AND annee < 2017)
);

CREATE TABLE editeur(
       id_editeur SERIAL PRIMARY KEY,
       nom_editeur VARCHAR(100) NOT NULL,
       UNIQUE(nom_editeur)
);

CREATE TABLE livre(
       id_document INTEGER REFERENCES document(id_document),
       id_editeur INTEGER REFERENCES editeur(id_editeur),
       nombre_pages INTEGER CHECK (nombre_pages > 0),
       auteurs VARCHAR(100) NOT NULL,
       PRIMARY KEY(id_document)
);

CREATE TABLE maison_production(
       id_maison SERIAL PRIMARY KEY,
       nom_maison VARCHAR(100) NOT NULL,
       UNIQUE(nom_maison)
);

CREATE TABLE media(
       id_document INTEGER REFERENCES document(id_document),
       id_maison INTEGER REFERENCES maison_production(id_maison),
       duree TIME NOT NULL,
       PRIMARY KEY(id_document)
);

CREATE TABLE bibliotheque(
       id_bibliotheque SERIAL PRIMARY KEY,
       nom VARCHAR(100) NOT NULL,
       adresse VARCHAR NOT NULL,
       codePostal VARCHAR(5) NOT NULL,
       ville VARCHAR(100) NOT NULL,
       UNIQUE(nom,adresse,codePostal,ville)
);

CREATE TABLE exemplaire( 
       id_exemplaire SERIAL,	   
       id_document INTEGER REFERENCES document(id_document),
       id_bibliotheque INTEGER REFERENCES bibliotheque(id_bibliotheque),
       support VARCHAR(10) CHECK (support IN ('livre','livre audio','partition','DVD','CD-ROM')),
       langue VARCHAR(20) NOT NULL,
       prix_achat NUMERIC(5,2) CHECK (prix_achat > 0),
       date_entree DATE NOT NULL,
       PRIMARY KEY(id_exemplaire,id_document)
);

CREATE TABLE emprunts(
       id_client INTEGER REFERENCES client(id_client) ON DELETE CASCADE,
       id_exemplaire INTEGER,
       id_document INTEGER,
       date_emprunt DATE NOT NULL,
       date_rendu DATE,
       nb_renouvellements INTEGER CHECK (nb_renouvellements <= 2),
       PRIMARY KEY(id_client,id_exemplaire,id_document,date_emprunt),
       FOREIGN KEY (id_exemplaire,id_document) REFERENCES exemplaire(id_exemplaire,id_document)
);

CREATE TABLE reserve(
       id_client INTEGER REFERENCES client(id_client) ON DELETE CASCADE,
       id_exemplaire INTEGER,
       id_document INTEGER,
       PRIMARY KEY(id_client,id_exemplaire,id_document),
       FOREIGN KEY (id_exemplaire,id_document) REFERENCES exemplaire(id_exemplaire,id_document)
);

CREATE TABLE doitRembourser(
       id_client INTEGER REFERENCES client(id_client),
       id_exemplaire INTEGER,
       id_document INTEGER,
       PRIMARY KEY(id_client,id_exemplaire,id_document),
       FOREIGN KEY (id_exemplaire,id_document) REFERENCES exemplaire(id_exemplaire,id_document)
);

CREATE TABLE date_courante(
       date DATE
);
