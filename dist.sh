
cd ..

VERSION=0.8
PROJNAME=monitor4tomcat
TARFILE=$PROJNAME-$VERSION.tar.gz

rm -f $TARFILE

find $PROJNAME -name "*~" -exec rm {} \; -print

tar -cvzf $TARFILE $PROJNAME

