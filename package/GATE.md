# Oracle JRE 8
# https://wiki.debian.org/JavaPackage

apt-get install -y libxslt1.1 java-common
wget http://ftp.de.debian.org/debian/pool/contrib/j/java-package/java-package_0.62_all.deb
dpkg -i java-package_0.62_all.deb

# As a user
# wget jre-8u121-linux-x64.tar.gz
fakeroot make-jpkg jre-8u121-linux-x64.tar.gz
# Builds oracle-java8-jre_8u121_amd64.deb

dpkg -i oracle-java8-jre_8u121_amd64.deb
java -version


# GATE
# https://gate.ac.uk/download/
java -jar gate-8.4-build5748-installer.jar
# Select target path: /usr/local/gate

# Cygwin SSH agent
#     eval "$(/usr/bin/ssh-pageant -r -a "/tmp/.ssh-pageant-${USERNAME}")"
ssh -p $SSH_PORT -C -X -Y user@upcloud.keszul.tk
/usr/local/gate/gate.sh
