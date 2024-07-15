# vim: set ft=make :

# Install the cross-shell Starship prompt
install-starship:
  curl -sS https://starship.rs/install.sh | sh

# Install go programming language
install-go:
    sudo rm -rf /usr/local/go
    wget https://go.dev/dl/go1.22.2.linux-amd64.tar.gz -O /tmp/go.tar.gz
    sudo tar -C /usr/local -xzf /tmp/go.tar.gz

# Kills all processes related to wine and proton. This forces it to restart next time you launch the game (you might still have to press STOP in steam to kill the game binary)
fix-proton-hang:
    #!/usr/bin/bash
    PROTONCORE=(pv-bwrap pressure-vessel reaper explorer.exe rpcss.exe plugplay.exe services.exe svchost.exe winedevice.exe winedevice.exe wineserver gamescope gamescope-wl)
    for PROG in "${PROTONCORE[@]}"; do
    killall -9 "$PROG"
    done

# Enable TAS2781 audio fix for Legion 9i
fix-legion-audio
    systemctl enable tas2781-fix.service
    systemctl daemon-reload
    systemctl start tas2781-fix.service