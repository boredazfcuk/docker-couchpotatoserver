# docker-couchpotato
An Alpine Linux Docker container for CouchPotato's CouchPotatoServer

# IMPORTANT INFO

This image is designed to be a single component in a stack.

The purpose of the stack is to manage all of your media, provide a central database for metadata, allow remote access to your collection while also providing security and anonymity.

This service in the stack depends on a separate container with an OpenVPN connection and it's web-based interface should be accessed using an NGINX reverse proxy which is secured with LetsEncrypt certificates.

Those containers are available as boredafcuk/docker-openvpnpia and boredazfcuk/docker-nginx on Github and are on Docker Hub as boredazfcuk/openvpnpia and boredazfcuk/nginx.

The stack's docker-compose.yaml is available as boredazfcuk/steve

# Information beneath is now obsolete and will be removed once I have documented my other containers appropriately 

### DEFAULT ENVIRONMENT VARIABLES

USER: This is name of the user account that you wish to create within the container. This can be anything you choose, but ideally you would set this to match the name of the user on the host system which has access to your storage. If this variable is not set, it will default to 'user'

UID: This is the User ID number of the above user account. This can be any number that isn't already in use. Ideally, you should set this to be the same ID number as the USER's ID on the host system. This will avoid permissions issues on the host system. If this variable is not set, it will default to '1000'

GROUP: This is name of the group account that you wish to create within the container. This can be anything you choose, but ideally you would set this to match the name of the user's primary group on the host system. If this variable is not set, it will default to 'group'

GID: This is the Group ID number of the above group. This can be any number that isn't already in use. Ideally, you should set this to be the same Group ID number as the user's primary group on the host system. If this variable is not set, it will default to '1000'

### VOLUME CONFIGURATION

This container requires a named volume mapped to /config/ This is where is stores the couchpotato configuration, database and logs. If this isn't created as a named volume, then you risk losing your DB and config when recreating the container.

This container also requires a bind mount, in which your movies are stored, and it should be mapped to /storage/

### CREATING A CONTAINER

To create a container, run the following command from a shell on the host, filling in the details as per your requirements:

```
docker create \
   --name <Contrainer Name> \
   --network <Name of Docker network, or container network to connect to> \
   --restart=always \
   --env USER=<User Name> \
   --env UID=<User ID> \
   --env GROUP=<Group Name> \
   --env GID=<Group ID> \
   --env TZ=<The local time zone> \
   --volume <Named volume which is mapped to /config> \
   --volume /path/to/your/root/movie/directory/:/storage/ \
   boredazfcuk/couchpotatoserver
   ```
   
   This is an example of the command I run to create a container on my own machine:
   
   ```
docker create \
   --name CouchPotato \
   --network container:MyVPNContainer \
   --restart always \
   --env USER=media \
   --env UID=3311 \
   --env GROUP=couchpotato \
   --env GID=3342 \
   --env TZ=Europe/London \
   --volume couchpotato_config:/config/ \
   --volume /storage/videos/:/storage/ \
   boredazfcuk/couchpotatoserver
   ```
   