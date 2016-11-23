# The fulcrum/custom directory

This directory is intended for custom scripts that need to be run to support
everything that might need to be done. The structure should look like the
following:

fulcrum
  plugin
    doctor
      post-all
      post-linux
      post-mac
      post-win10
      pre-all
      pre-linux
      pre-mac
      pre-win10
    fulcrum-up
      post-all
      post-linux
      post-mac
      post-win10
      pre-all
      pre-linux
      pre-mac
      pre-win10
    site
      post-all
      post-linux
      post-mac
      post-win10
      pre-all
      pre-linux
      pre-mac
      pre-win10

An example is in order to be able to use Drush natively on the Mac, you would
you would need to have this in install file:

brew install mysql --client-only