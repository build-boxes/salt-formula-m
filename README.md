# Salt-Formula-M
An inependent salt minion container image for use with [salt-formula-x (Salt-Master)](https://github.com/build-boxes/salt-formula-x) and the Compose file [Docker/Podman Compose file for Salt](https://github.com/build-boxes/salt-compose.git)

## Build Podman Image
```
podman build . -t hammadrauf/saltm

OR

docker build . -t hammadrauf/saltm
```

## Launching the Container (Locally)
```
podman run -d --systemd=true  --name saltm01 --hostname saltm01 -it hammadrauf/saltm
podman run -d --name saltm01 --hostname saltm01 -it hammadrauf/saltm

OR

docker run -d --privileged  --name saltm01 --hostname saltm01 -it hammadrauf/saltm
```

## Launching the Container (From Quay.io)
```
podman run -d --name saltm01 --hostname saltm01 -it quay.io/hammadrauf/saltm
```

## Launching the Container - with SSH Key
```
podman run -d --name saltm01 --hostname saltm01 -e SSH_PUB_KEY="$(cat ~/.ssh/id_rsa_salt.pub)" -it quay.io/hammadrauf/saltm
```

## Connect to Running Container - via Podman Exec
```
podman exec -it saltm01 /bin/bash
```

## Connect to Running Container - via SSH
- Default root password (if SSH_PUB_KEY is not used) = minion!
```
ssh-keygen -R localhost
OR
mv ~/.ssh/known_hosts ~/.ssh/known_hosts.old 
ssh root@localhost -p 2232
```

## Stop and Destroy the Container
```
podman stop saltm01
OR
podman container stop saltm01

podman rm saltm01
OR
podman container rm saltm01
podman image rm hammadrauf/saltm

OR

docker kill saltm01
docker rm saltm01
docker image rm hammadrauf/saltm
```

## List and Delete Unwanted Images
```
podman image ls

podman image rm <Image-ID01> [<Image-ID02>/<ImageName-02> ...}
```

## Manually Upload Image to Repositories
You should have an account with DockerHub.io or Quay.io to push built images.
```
podman push ....
```

## Pairing the independent Container based Salt Master

The best way to use this minion in combination with the hammadrauf/saltx Salt-Master is to use the Docker/Podman Compose file at [Docker/Podman Compose file for Salt](https://github.com/build-boxes/salt-compose.git)
```
$ cd podman-compose-folder
$ podman compose up -d
OR
$ docker compose up -d
```
After testing is complete, bring down the containers with the following command.
```
podman compose down
OR
docker compose down
```

## How To Run Serverspec Tests Manually
1. Place your formula Tests inside the "test" folder on Salt-Master Container:
    ```
    x
    ├── formula
    │   ├── ntp
    │   │   ├── init.sls
    │   │   └── test
    │   │       └── ntp_spec.rb
    │   └── timezone
    │       ├── init.sls
    │       └── test
    │           └── timezone_spec.rb
    ├── pillar
    │   ├── ntp.sls
    │   ├── timezone.sls
    │   └── top.sls
    └── top.sls
    ```
1. All serverspec files should:
    - named like "*_spec.rb"
    - contain a first line of:
        ```
        require '/opt/serverspec/spec_helper'
        ```
1. You should login to the Container (either via SSH or podman exec).
    ```
    cd /srv/salt/formula
    rspec timezone/test/timezone_spec.rb
    rspec ntp/test/ntp_spec.rb
    ```
1. To run all tests, run the following from any folder:
    ```
    $ /opt/serverspec/run_all_tests.sh
    OR
    $ run_all_tests.sh
    ```

