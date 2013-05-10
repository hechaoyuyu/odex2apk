#!/bin/sh

APP=$1
FRAMWORK=$2
PRGDIR=`dirname "$0"`
JARDIR=$PRGDIR/jar
javaOpts="-Xmx256M"
LOCAL_CERTIFICATE="$3"

if [ -z "$APP" -o ! -d "$APP" -o -z "$FRAMWORK" -o ! -d "$FRAMWORK" ] 
then
	echo "请指定 app 和 framework 路径！"
	exit 0
fi

if [ -z "$LOCAL_CERTIFICATE" ]
then
	LOCAL_CERTIFICATE="testkey"
fi

for file in `ls $APP/*.odex`
do
	apk=${file%.*}.apk
	if [ ! -r "$apk" ]
	then
		echo "$file 没有对应的 apk 文件！"
		continue
	fi

	echo "将 $file 生成 class 文件到 out 目录下"
	#out=$file.out
	java $javaOpts -jar $JARDIR/baksmali.jar -d $FRAMWORK -x $file

	echo "将 out 生成 classes.dex 文件 classes.dex"
	#dex=$out/classes.dex
	java $javaOpts -jar $JARDIR/smali.jar out -o classes.dex

	echo "将 classes.dex 添加到对应的 $apk 中"
	7z a -tzip $apk classes.dex 1>/dev/null

	echo "清理生成的 out 和 classes.dex"
	rm -r out classes.dex

	echo "对 $apk 重新进行数名签名为 $apk.signed"
	java $javaOpts -jar $JARDIR/signapk.jar $JARDIR/$LOCAL_CERTIFICATE.x509.pem $JARDIR/$LOCAL_CERTIFICATE.pk8 $apk $apk.signed
		
	echo "清理 。。。。。。"
	mv $apk.signed $apk
	rm $file
done
