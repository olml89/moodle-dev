# Moodle Docker Development Environment
This project provides a **dockerized Moodle installation** tailored for local plugin development. 
It allows developers to quickly spin up a
[moodle](https://github.com/moodle/moodle)
instance with all dependencies configured, 
making it easy to test and develop Moodle plugins without modifying a production environment.

## How to run it
Clone this repository:

```bash
git clone https://github.com/olml89/moodle-dev.git moodle/dev
cd moodle/dev
```

Create a .env file:
```bash
cp .env.example .env
```

Edit the env variables with the desired values.

Map the plugins you are developing in the **docker-compose.yml**.

Run:
```bash
docker compose build
docker compose up -d
```

This will spin up a moodle container with your plugins added to the Moodle core source code: the Moodle source code
is mounted into /usr/src/moodle, and it runs the installation cli if required. Then it copies it into
/var/www/html/moodle. Your plugins will live in /var/www/html/moodle/plugins/*.

## How to debug it
The container is provided with xdebug to make debugging easy, but in order to make it work you will have to
configurate the path mappings properly in your IDE.

In order to do so, do the following:
```bash
git clone https://github.com/moodle/moodle.git ../core
```

This will create a core directory inside the moodle one, containing the Moodle source code. The dev directory with
this repository will also live there. It is recommended that you create a third plugins directory, containing
the plugins you are developing.

Taking moodle as the root of the project, map the Moodle source code you have just cloned locally into core to 
/var/www/html/moodle in the container. For every plugin in plugins you should also add a particular mapping to
/var/www/html/moodle/plugins/* in the container. This should be enough to be able to debug your the Moodle
core and also the plugins.
