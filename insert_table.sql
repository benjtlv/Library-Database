INSERT INTO client(nom,prenom,date_naissance,telephone,adresse,codePostal,ville,type_abonnement,date_inscription,penalites) VALUES

('freud','jean','1965-03-03','0678523438','39 rue des gravilliers','75003','paris','CD','2016-02-23',0),
('diallo','mamadou','1975-09-05','0634651298','34 avenue jean jaurès','93000','bobigny','normale','2016-01-07',0),
('rodriguez','ricardo','1983-09-09','0645985656','22 rue du fort','94400','vitry','CD/DVD','2016-01-01',0),
('smahi','bilel','1994-08-06','0756343423','22 rue paul gauguin','94000','creteil','normale','2016-01-03',0),
('mangala','robert','1992-09-01','0678789898','18 rue pasteur','91350','grigny','normale','2016-01-06',0),
('uzenat','eric','1993-06-18','0689564323','5 rue de lappe','75011','paris','CD/DVD','2016-01-01',0),
('elkrieff','benjamin','1992-10-21','0626227379','4 rue auguste renoir','78360','montesson','CD/DVD','2016-01-01',0),
('hainaut','jean','1957-04-03','0634346565','5 rue du chevaleret','75013','paris','CD','2016-01-01',0);
                                                   
INSERT INTO genre(nom_genre) VALUES
('aventure'), --1
('action'),   --2
('fantastique'), --3
('policier'), --4
('drame'), --5
('comedie'),--6
('documentaire'), --7
('thriller'), --8
('animation'), --9
('histoire'), --10
('horreur'), --11
('guerre'), --12
('arts martiaux'), --13
('biographie'), --14
('science fiction'), --15
('science'), --16
('geographie'), --17
('economie'), --18
('arts'), --19
('romantique'), --20
('course'), --21
('musique'), --22
('dictionnaire'); --23

INSERT INTO document(id_genre,titre,annee) VALUES
(16,'PHP',2006),
(9,'titeuf',2002),
(18,'critique de léconomie politique',1859),
(17,'encyclopédie de géographie',2012),
(23,'le robert',1998),
(22,'marc lavoine',2005),
(22,'juicy j',1994), --j'aime ça ;)
(13,'karate Kid',2010),
(2,'le transporteur',2005);


INSERT INTO editeur(nom_editeur) VALUES
('flammarion'),
('glénat'),
('dunod'),
('armand colin'),
('bayol'),
('berangel'),
('findakly'),
('larousse'),
('laroque'),
('livre de poche'),
('picard'),
('seuil'),
('tabary'),
('fleuve noir');

INSERT INTO livre(id_document,id_editeur,nombre_pages,auteurs) VALUES
(1,3,400,'karim nour'),
(2,2,60,'zep'),
(3,4,100,'bernard jean'),
(4,7,140,'loic legrand'),
(5,1,120,'boris villet');

INSERT INTO maison_production(nom_maison) VALUES
('columbia pictures'),
('blue sky studios'),
('cannon group'),
('dreamworks'),
('three 6 mafia'),
('fox 2000 pictures'),
('gaumont'),
('hbo films'),
('gafer'),
('toggle productions');

INSERT INTO media(id_document,id_maison,duree) VALUES
(6,1,'01:45:00'),
(7,2,'02:12:00'),
(8,3,'02:20:00'),
(9,4,'01:30:00');

INSERT INTO bibliotheque(nom,adresse,codePostal,ville) VALUES
('Bibliothèque Nationale de France','Quai François Mauriac','75013','paris'),
('Bibliothèque Faidherbe','20 Rue Faidherbe','75011','paris'),
('Bibliothèque Parmentier','20 Avenue Parmentier','75011','paris'),
('Bibliothèque Diderot','42 Avenue Daumesnil','75012','paris'),
('Bibliothèques Saint-Eloi','23 Rue du Colonel Rozanoff','75012','paris'),
('Bibliothèque de lArsenal','1 Rue de Sully','75012','paris'),
('Bibliothèque Buffon','15 Rue Buffon','75005','paris'),
('Médiathèque Hélène Berr','70 Rue de Picpus','75012','paris'),
('Bibliothèque Forney','1 Rue du Figuier','75005','paris'),
('Bibliothèque Louise Michel','35 Rue des Haies','75020','paris'),
('Bibliothèque Arthur Rimbaud','2 Place Baudoyer','75004','paris'),
('Bibliothèque Mazarine','23 Quai de Conti','75006','paris'),
('BNF- Site Richelieu','58 Rue de Richelieu','75002','paris'),
('Bibliothèque Charlotte Delbo','2 Passage des Petits Pères','75002','paris'),
('Médiathèque Marguerite Duras','115 Rue de Bagnolet','75020','paris');

INSERT INTO exemplaire(id_document,id_bibliotheque,support,langue,prix_achat,date_entree) VALUES
(1,1,'livre','français',30,'2011-12-01'),
(1,1,'livre','français',30,'2011-12-01'),
(1,1,'livre','français',30,'2016-05-05'),
(1,2,'livre','français',30,'2011-12-02'),
(1,2,'livre','français',30,'2011-12-02'),
(1,3,'livre','français',30,'2011-12-03'),
(1,3,'livre','français',30,'2011-12-03'),
(1,7,'livre','français',30,'2011-12-04'),
(1,7,'livre','français',30,'2011-12-04'),
(1,9,'livre','français',30,'2011-12-05'),
(1,9,'livre','français',30,'2011-12-05'),
(2,1,'livre','français',56.50,'1998-03-03'),
(2,1,'livre','français',56.50,'1998-03-03'),
(2,2,'livre','anglais',60,'1998-03-03'),
(2,2,'livre','anglais',60,'1998-03-03'),
(2,8,'livre','anglais',56.99,'2000-03-01'),
(2,8,'livre','anglais',56.99,'2000-03-01'),
(3,4,'livre','français',20,'2009-05-23'),
(3,5,'livre','anglais',20,'2009-05-23'),
(3,5,'livre','français',20,'2009-05-23'),
(3,6,'livre','russe',20,'2009-05-23'),
(3,7,'livre','espagnol',25,'2009-05-23'),
(4,1,'livre','français',12,'1970-05-23'),
(4,9,'livre','français',12,'1970-05-23'),
(4,11,'livre','français',12,'1970-05-23'),
(4,11,'livre','français',12,'1970-05-23'),
(4,11,'livre','français',12,'1970-05-23'),
(5,1,'livre','français',20,'1991-07-27'),
(5,2,'livre','français',20,'1991-07-27'),
(5,3,'livre','français',20,'1991-07-27'),
(5,4,'livre','français',20,'1991-07-27'),
(5,12,'livre','français',20,'1991-07-27'),
(6,1,'DVD','français',20,'2016-05-05'),
(6,7,'DVD','français',20,'2016-05-05'),
(6,8,'CD-ROM','français',20,'2016-05-05'),
(6,8,'CD-ROM','anglais',20,'2016-05-05'),
(6,9,'partition','français',20,'2016-05-05'),
(6,9,'partition','français',20,'2016-05-05'),
(7,8,'DVD','français',20,'2016-05-05'),
(7,8,'DVD','français',20,'2016-05-05'),
(7,9,'partition','français',20,'2000-03-06'),
(7,9,'partition','français',20,'2000-03-06'),
(7,13,'DVD','français',20,'2000-03-06'),
(8,2,'CD-ROM','français',10.50,'2012-09-20'),
(8,6,'DVD','moldave',10.50,'2012-09-20'),
(8,9,'DVD','espagnol',10.50,'2012-09-20'),
(8,10,'DVD','anglais',10.50,'2012-09-20'), --A partir de la : exemplaire de la même biblio (id_biblio = 10)
(1,10,'livre','anglais',10.50,'2012-09-20'),
(1,10,'livre','espagnol',10.50,'2012-09-20'),
(1,10,'livre','anglais',10.50,'2012-09-20'),
(1,10,'livre','anglais',10.50,'2012-09-20'),
(1,10,'livre','anglais',10.50,'2012-09-20'),
(2,10,'livre','anglais',10.50,'2012-09-20'),
(2,10,'livre','anglais',10.50,'2012-09-20'),
(2,10,'livre','anglais',10.50,'2012-09-20'),
(2,10,'livre','anglais',10.50,'2012-09-20'),
(2,10,'livre','anglais',10.50,'2012-09-20'),
(3,10,'livre','anglais',10.50,'2012-09-20'),
(3,10,'livre','anglais',10.50,'2012-09-20'),
(3,10,'livre','anglais',10.50,'2012-09-20'),
(3,10,'livre','anglais',10.50,'2012-09-20'),
(3,10,'livre','anglais',10.50,'2012-09-20'),
(4,10,'livre','anglais',10.50,'2012-09-20'),
(4,10,'livre','anglais',10.50,'2012-09-20'),
(4,10,'livre','anglais',10.50,'2012-09-20'),
(5,10,'livre','anglais',10.50,'2012-09-20'),
(5,10,'livre','anglais',10.50,'2012-09-20'),
(5,10,'livre','anglais',10.50,'2012-09-20'),
(5,10,'livre','anglais',10.50,'2012-09-20'), --Fin des exemplaires de la même biblio
(1,11,'livre','français',10.50,'2007-04-04'),
(1,11,'livre','français',10.50,'2007-04-04'),
(1,12,'livre','français',10.50,'2007-04-04'),
(1,12,'livre','français',10.50,'2007-04-04'),
(2,11,'livre','français',10.50,'2007-04-04'),
(2,11,'livre','français',10.50,'2007-04-04'),
(2,12,'livre','français',10.50,'2007-04-04'),
(3,11,'livre','français',10.50,'2007-04-04'),
(3,12,'livre','français',10.50,'2007-04-04'),
(3,13,'livre','français',10.50,'2007-04-04'),
(4,12,'livre','français',10.50,'2007-04-04'),
(4,13,'livre','français',10.50,'2007-04-04'),
(4,14,'livre','français',10.50,'2007-04-04'),
(4,13,'livre','français',10.50,'2007-04-04'),
(5,14,'livre','français',10.50,'2007-04-04'),
(5,14,'livre','français',10.50,'2007-04-04'),
(6,15,'livre','français',10.50,'2007-04-04'),
(6,15,'livre','français',10.50,'2007-04-04'),
(7,15,'livre','français',10.50,'2007-04-04');

INSERT INTO emprunts(id_client,id_exemplaire,id_document,date_emprunt,date_rendu,nb_renouvellements) VALUES
(2,5,1,'2016-05-11',null,0),
(2,6,1,'2016-05-11',null,0),
(1,1,1,'2016-04-10',null,0),
(1,2,1,'2016-04-10',null,0),
(3,75,2,'2016-04-12',null,0),
(3,76,2,'2016-04-12',null,0),
(3,77,3,'2016-04-14',null,0),
(3,78,3,'2016-04-15',null,0),
(3,79,3,'2016-04-16',null,0),
(3,80,4,'2016-04-20',null,0),
(8,87,6,'2016-04-20',null,0),
(7,81,4,'2016-04-18',null,0);



--INSERT INTO reserve(id_client,id_exemplaire,id_document) VALUES


INSERT INTO date_courante(date) VALUES
--('2016-05-11');

('2016-05-10');
