CryptoPad
============================
Developed by Noam Szpiro & Snir Kodesh

Description
-----------
A simple way to share sensitive information between colleagues and friends.
Many other similar services exist (such as wickr). The problem with most of them is that it requires both parties to have the app/service installed. The benefits of this webapp is that no one needs an account on the system. The user can simply share a link with anyone. The user can choose if they want to encrypt the data client side or server side, or simply decide that an obscure url is secure enough.

The webapp allows uploading of up to 4 files. There are various security options for the advanced user that define when the data shared will be destroyed (e.g. after multiple failed attempts, after X amount of days etc).

Intructions
-----------
Use the Procfile to run the server locally (Foreman start). Run bundle install beforehand. The migration files are in the db/migrations folder. To run them, run bin/run_db_migrations

If you host your own solution make sure, you run the command "rake delete_expired_pads" once a day. 
