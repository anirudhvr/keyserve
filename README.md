Keyserve
========

Keyserve is a Web service that stores and serves encryption keys for use
with other applications. The main motivation behind Keyserve is to
centralize the management of various types of encryption keys, and to
ensure that keys are backed-up and rotated appropriately.

Keyserve allows applications to created, read, update, and delete keys
based using a REST-style API that returns JSON-encoded responses. 

This project is a work in progress.

Features
--------

1. Has users, each of whom can have many keys. The first user is
automatically created ('admin', password set in the config). Subsequent
users can be added by users with admin privileges (tbd).
2. Keys, of which a user can have many. 
    A new key can be created by POSTing to /keys with the appropriate
    post params. 
    A key can be retrieved by 'GET'ing a unique URL (e.g., GET /key/1).
    A key can be updated by 'PUT'ing to /key/:id
    A key can be deleted by sending HTTP DELETE to /key/:id
3. Encrypted backup of the key database on shutdown to an S3 bucket, and
secure retrieval of the bucket on startup
4. All API requests are served over HTTPS

Installation & Usage
--------------------

Keyserve is a Sinatra application that is designed to host, serve, and
manage encryption keys for various applications. 

To use, it's best if you have a modern Ruby environment set up with
rvm/rbenv and bundler. Clone the repository and run `bundle install` to
pull dependencies. Then run `rackup` to run the development server.

### Running
$ `bundle install`
$ `rackup config/config.ru`

### Usage

This is one component of software to secure your application; the other
client-side component should perform key retrieval, and for better
security, key encryption (using a passphrase) before pushing to
Keyserve. This type of functionality is being built, for example, into
the HIPAARails Rails 3 module https://github.com/oakenshield/hipaarails.

### Admin
1. See config/config.rb to set the admin username, email and password.
Only the admin can add and create new users (via the API). Each new user
gets an api key which must be provided with each request. 
2. To enable S3 backup/retrieval, you will want to create a file with
your AWS access credentials and the encryption key and initiailization
vector (to encrypt the DB), and put these in your environment variable.
For example, if you are using bash, put the following in a file and
source it before running the app. 

`export AMAZON_ACCESS_KEY_ID='mykeyid'`

`export AMAZON_SECRET_ACCESS_KEY='mysecret'`

`export DB_ENCRYPTION_KEY="myenckey"`

`export DB_ENCRYPTION_IV="myenciv"`

3. You can create keys/IVs for your chosen encryption algo using
`scripts/create_key_iv.rb`

API
---

### Basic operations

Each user can have several encryption keys, but only one API key. The
API key must be provided with each request as the username, with an
empty password. For example: 

`curl -u 9627f30495f26b8f02f500d80c0ad171: https://localhost:8443/keys`

1. `GET /keys`: Get the keys for a user. Outputs a JSON encoded list of keys.
2. `GET /key/3`: Gets the details for key ID 3 for the specified usero
3. `POST /keys`: Creates and returns a new key. POST parameters include
the key type, description, and user ID it is for. 
4. `PUT /key/3`: Updates key ID 3 with specified arguments
5. `DELETE /key/3`: Deletes key ID 3

### Being worked on

* Automated key expiration and rotation. Key expiration is easy to implement, but rotation will require support from the client side.
* Multiple users and roles. 
* Storage services: Currently, the data is stored in an sqlite databaseand backed up to S3, but perhaps there could be other choices such as MySQL, Redis, etc. 
* Assembling key from multiple sources: To add extra redundancy and security, we want to allow the user to store a key at n multiple locations and be able to reconstruct the key from k of these locations (where k < n)
* Web frontend. Will show the stuff available as JSON in a pretty format. Early screenshots here: blog.nouvou.com/introducing-nouvous-key-management-service


### Bug reports

Bug reports would be greatly appreciated. Please file through Github or send me email!
