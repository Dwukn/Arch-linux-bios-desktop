##
# change {user} before running the commands

 sudo cp -r /run/media/{user}/SharedDrive/lunix/.ssh /home/{user}/
[sudo] password for dawu:
❯ sudo chown -R dawu:dawu /home/{user}/.ssh
❯ chmod 700 ~/.ssh
❯ chmod 600 ~/.ssh/*
❯ ssh -T git@github.com
