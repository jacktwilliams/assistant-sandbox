Run AI assistance in a sandbox Docker container. This uses a Docker Compose file so that you can have different containers with your instructions, settings, and repositories mapped into the container file system for the setup.

1. Run 'Gemini' outside the container. These credentials can be mounted into the containers. 
2. For claude code, you need to run the login inside one container, and then all your containers can share. (It doesn't seem like you can share authorization between mac and containers, tokens don't seem to be stored in the file system. Perhaps they are stored in the keychain.)
