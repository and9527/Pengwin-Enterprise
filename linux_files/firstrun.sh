#!/bin/bash

# Add wslu repository and install wslu
echo "Downloading and installing wslu repository"
curl -L https://packagecloud.io/install/repositories/whitewaterfoundry/wslu/script.rpm.sh | sudo bash
echo "Updating repositories"
sudo yum update
echo "Upgrading packages"
sudo yum upgrade -y
echo "Installing wslu"
sudo yum install wslu -y

# Get required application paths
echo "Getting required application paths"
wHomeDrive="$(cmd.exe /C 'echo %HOMEDRIVE%' | tr -d '\r')"
HomeDrive="/mnt/$(echo "${wHomeDrive}" | sed 's|\:||g' | tr '[:upper:]' '[:lower:]')"
wHomePath="$(cmd.exe /C 'echo %HOMEPATH%' | tr -d '\r')"
HomePath="$(echo "${wHomePath}" | sed 's|\\|\/|g')"
wHome="$wHomeDrive$wHomePath"
Home="$HomeDrive$HomePath"

# Install Putty's Pageant and weasel-pageant
echo "Installing Pageant (with weasel-pageant WSL integration) to ${Home}/.pageant"
mkdir "${Home}/.pageant"
cp /opt/pageant/* "${Home}/.pageant"
chmod +x "${Home}/.pageant/weasel-pageant"

# Add Pageant startup registry entry
echo "Configuring Pageant to execute on startup"
TMPDIR=$(mktemp -d)
cat << EOF >> "${TMPDIR}/Install.reg"
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run]
@="Pageant startup"
"Pageant"="${wHome}\\.pageant\\pageant.exe"
EOF
cp "${TMPDIR}/Install.reg" "$HomeDrive$(cmd.exe /C 'echo %TEMP%' 2>&1 | tr -d '\r' | sed 's|\\|\/|g' | sed 's|.\:||g')"
cmd.exe /C "Reg import %TEMP%\Install.reg"
rm -rf "${TMPDIR}"

# Add profile.d start script for weasel-pageant
echo "Configuring weasel-pageant WSL integration"
string="eval \$(\""${Home}/.pageant/weasel-pageant"\" -r --helper \"${Home}/.pageant\")"
sudo bash -c 'cat > /etc/profile.d/pageant.sh' << EOF
#!/bin/bash
$string
EOF

# Unzip vcxsrv to user's directory
echo "Installing vcxsrv to ${Home}/.vcxsrv"
mkdir "${Home}/.vcxsrv"
unzip /opt/vcxsrv/vcxsrv.zip -d "${Home}/.vcxsrv" > /dev/null 2>&1

# Add profile.d start script for vcxsrv
echo "Configuring vcxsrv integration"
sudo bash -c 'cat > /etc/profile.d/vcxsrv.sh' << EOF
#!/bin/bash
'$Home/.vcxsrv/vcxsrv.exe' :0 -silent-dup-error -multiwindow &> /dev/null &
disown
EOF

# Move firstrun.sh out of profile.d to /opt/pengwin
echo "Removing this script"
sudo mkdir /opt/pengwin
sudo mv /etc/profile.d/firstrun.sh /opt/pengwin/firstrun.sh
