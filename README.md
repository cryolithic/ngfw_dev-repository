This is the server-side code in charge of processing Debian packages
built by Travis from GitHub pull requests.

# Summary

We use aptly to add and publish packages, before serving them through
the usual Apache setup.

# Using packages

Right now the exposed repository is not signed, so your sources.list
should look like this:

  `deb [trusted=yes] http://package-server.untangle.int/dev/buster <PR-branch> main non-free`
  
Here's a full example, for a branch named `NGFW-12345-my-fix`:

  ```
  echo 'deb [trusted=yes] http://package-server.untangle.int/dev/buster NGFW-12345-my-fix main non-free' > /etc/apt/sources.list.d/NGFW-12345-my-fix.list
  apt update
  apt install [...]
  ```

# Deployment on package-server

## Code

This code is checked out under `/srv/ngfw_dev-repository`.

## apt access

A symlink is used to expose the repository via Apache:

  `ln -sf /srv/ngfw_dev-repository/www /var/www/dev`

## Upload permissions

Travis uploads as `buildbot`:

  `chown buildbot /srv/ngfw_dev-repository/incoming/buster`

## Service

Processing incoming packages can be with the provided docker-compose
setup, but as package-server is still a 32bit machine we instead use the
`ngfw-dev-repository.service` systemd service:

  ```
  ln -sf /srv/ngfw_dev-repository/ngfw-dev-repository.service /etc/systemd/system/
  systemctl daemon-reload
  systemctl enable --now ngfw-dev-repository
  ```
  
## Logs

They are handled by systemd:

`journalctl -f -u ngfw-dev-repository`
