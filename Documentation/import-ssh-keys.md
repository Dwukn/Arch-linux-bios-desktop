# SSH Key Setup for GitHub from External Drive

This guide walks you through copying your SSH keys from an external or USB drive into your Linux home directory, configuring permissions, and verifying your SSH setup with GitHub.

---

## 🔧 Prerequisites

* An external drive (e.g., USB or mounted storage) is connected and mounted at:

  ```
  /run/media/{user}/{DriveName}
  ```

* The `.ssh` directory exists **at the root of the drive**, like this:

  ```
  /run/media/{user}/{DriveName}/.ssh
  ```

* Replace `{user}` with your actual Linux username (e.g., `dwukn`).

* Replace `{DriveName}` with the actual name of the mounted drive (e.g., `USB`, `BackupDrive`, etc.).

---

## 📜 Step-by-step Commands with Explanations

```bash
# 1. Copy the .ssh directory from the mounted drive to your home directory
sudo cp -r /run/media/{user}/{DriveName}/.ssh /home/{user}/
# Explanation: Securely copies your SSH configuration and key files from the drive to your user’s home directory.

# 2. Change ownership of the .ssh directory and its contents to your user
sudo chown -R {user}:{user} /home/{user}/.ssh
# Explanation: Ensures that only your user account owns the files, which is required for SSH to function securely.

# 3. Set correct permissions on the .ssh directory
chmod 700 /home/{user}/.ssh
# Explanation: Restricts access to the .ssh directory so that only you can read, write, or execute it.

# 4. Set correct permissions on all files inside .ssh
chmod 600 /home/{user}/.ssh/*
# Explanation: Restricts key files so only your user can read or write them—SSH will reject insecure permissions.

# 5. Test SSH connection to GitHub
ssh -T git@github.com
# Explanation: Tries to authenticate with GitHub via SSH using the copied key. If successful, you'll see a welcome message.
```

---

## ✅ Example (For User: `dwukn`, Drive Name: `USB`)

```bash
sudo cp -r /run/media/dwukn/USB/.ssh /home/dwukn/
sudo chown -R dwukn:dwukn /home/dwukn/.ssh
chmod 700 /home/dwukn/.ssh
chmod 600 /home/dwukn/.ssh/*
ssh -T git@github.com
```

---

## 🛡️ Security Tips

* Never share your **private key** (e.g., `id_rsa`) with anyone.
* Do not leave your `.ssh` directory on a shared or public drive.
* SSH will **refuse to use** your key if permissions are too open.
