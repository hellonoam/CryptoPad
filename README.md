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


Security
--------
The data you transfer with the application will be as secure as it can possibly be with any other software you might use. It usually boils down to the password the user chooses. If it's a simple password it might be relatively easy to break (I'll get to this in a bit) a complex password (8 characters with numbers) shouldn't be breakable in the foreseeable future.

Here is a break down of how things work (assuming you choose server side encryption - which is safer):
you type in your message it gets sent to the server over https (meaning no one can read it along the way)
server encrypts the data with the password you provided (AES 256 CBC cipher)
the server saves the encrypted data on it's own database or Amazon S3 (if it's a file)

When trying to decrypt the data here is what happens:
1) you open the link and type in a password (if the password is incorrect too many times the pad/data will be destroyed automatically)
2) data is decrypted and sent back over https
3) the data is completely deleted after the user clicks delete or after it expires (default expiry is 7 days)

Here are the vulnerabilities of the system (these are common vulnerabilities for all application you might choose instead - no system can mitigate this further)
1) trying different password for a given pad - if the password is something really easy like password1 it might take one try to get the data. However as mentioned before after a few failed attempts the throttling mechanism will kick in and will disallow further attempts before waiting a certain time. Another few failures will result in the pad being auto deleted.
3) Gaining control over the server - This will allow the attacker to get the encrypted data from the database. This is not a big deal since even offline attacks will take years (that is with a strong password).
