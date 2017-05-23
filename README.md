------------------------DATA BASE PROJECT-----------------------------
------------------------Christ MUSENGA & Benjamin ELKRIEFF----------------

The purpose of the project was to model a database to be used by a Library.
You can registrer users and borrow medias (books,DVDs,etc...)

In this package :
- tables modelling (modelisation.pdf)
- project report
- several files :
	- creation files :
		* create_table.sql : contains all the create table instructions

		* insert_table.sql : insert data into tables

		* create_trigger.sql : create sql functions and triggers
	
	- testing files (with prompt command) :

		* test_reservation.sql : make a media reservation
		
		* test_inscription.sql : insert a new registrant

		* test_chercheExemplaire.sql : search for an available copy of a media

		* test_rendreExemplaire.sql : return back a copy to the library

		* test_remboursement.sql : reimburse a registrant

		* test_statistiquesEmprunt.sql : get the percentage of borrowing for a given library
		* test_renouvelExemplaire.sql : renew the borrowing of a copy

		* tets_renouvelInscription.sql : renew a registrant's subscription
