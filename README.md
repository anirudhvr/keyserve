Keyserve
========

Keyserve is a Web service that stores and serves encryption keys for use
with other applications. The main motivation behind Keyserve is to
centralize the management of various types of encryption keys, and to
ensure that keys are backed-up and rotated appropriately.

Keyserve allows applications to created, read, update, and delete keys
based using a REST-style API that returns JSON-encoded responses. 

This project is a work in progress.


Installation & Usage
--------------------

Keyserve is a Sinatra application that is designed to host, serve, and
manage encryption keys for various applications. 

To use, it's best if you have a modern Ruby environment set up with
rvm/rbenv and bundler. Clone the repository and run `bundle install` to
pull dependencies. Then run `rackup` to run the development server.

### Usage

This is one component of software to secure your application; the other
client-side component should perform key retrieval, and for better
security, key encryption (using a passphrase) before pushing to
Keyserve. This type of functionality is being built, for example, into
the HIPAARails Rails 3 module https://github.com/oakenshield/hipaarails.

### Admin
See config.rb to set the admin username, email and password. Only the
admin can add and create new users (via the API). Each new user gets an
api key which must be provided with each request. 

API
---

### Basic operations

Each user can have several encryption keys, but only one API key. The
API key must be provided with each request as the username, with an
empty password. For example: 

`curl -u 9627f30495f26b8f02f500d80c0ad171: https://localhost:9292/keys`

1. `GET /keys`: Get the keys for a user. Outputs a JSON encoded list of keys.
2. `GET /key/3`: Gets the details for key ID 3 for the specified usero
3. `POST /keys`: Creates and returns a new key. POST parameters include
the key type, description, and user ID it is for. 
4. `PUT /key/3`: Updates key ID 3 with specified arguments
5. `DELETE /key/3`: Deletes key ID 3

### Being worked on

0. HTTPS support. Not really much to do at my end, but config options
would be nice. Can be done with Webrick/Sinatra as outlined here:
http://stackoverflow.com/questions/3696558/how-to-make-sinatra-work-over-https-ssl
1. Storage services: Currently, the data is stored in an sqlite database
but I want to add multiple backend choices including Amazon S3, MySQL, etc.
2. Automated key expiration and rotation. Key expiration is easy to implement, but
rotation will require support from the client side.
2. Assembling key from multiple sources: To add extra redundancy and
security, we want to allow the user to store a key at n multiple locations
and be able to reconstruct the key from k of these locations (where k < n)
3. Web frontend. Will show the stuff available as JSON in a pretty
format. Early screenshots here: blog.nouvou.com/introducing-nouvous-key-management-service

