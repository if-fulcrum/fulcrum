# Fulcrum installer.

## Note: Latest confirmed version for macOS Fulcrum is [Docker for Mac: 2.0.0.3 (31259) 2019-02-15](https://download.docker.com/mac/stable/31259/Docker.dmg)
## Install Fulcrum Hinge on Mac or Ubuntu
Run from terminal:
```bash
export FSCRIPT=https://raw.githubusercontent.com/if-fulcrum/install/master/unix.sh &&
bash -c "$(curl -fsSL $FSCRIPT || wget -q -O - $FSCRIPT)"
```

### Add ~/fulcrum/bin to path
This depends on zsh or bash, not required but does make commands easier to run

### More information
Run the help command to see options and get more information
```bash
fulcrum -h
```
