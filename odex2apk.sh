#!/bin/bash

APP=$1
FRAMWORK=$2
APILEVEL=$3
CLASSPATH=""

PRGDIR=`dirname "$0"`
JARDIR=$PRGDIR/jar
javaOpts="-Xmx256M"

if [ -z "$APP" -o ! -d "$APP" -o -z "$FRAMWORK" -o ! -d "$FRAMWORK" ] 
then
	echo "请指定 app 和 framework 路径！"
	exit 0
fi

function deodex_file
{
        FILE=$1; TOFILE=${FILE%.*}.$2
        
        echo "将 $FILE 生成 class 文件到 out 目录下"
        if [ -z "$APILEVEL" ]
        then
                java $javaOpts -jar $JARDIR/baksmali.jar -c $CLASSPATH -d $FRAMWORK -x $FILE || exit -1
        else
                java $javaOpts -jar $JARDIR/baksmali.jar -a $APILEVEL -c $CLASSPATH -d $FRAMWORK -x $FILE || exit -2
        fi
        
        echo "将 out 生成 classes.dex 文件 classes.dex"
        #dex=$out/classes.dex
        java $javaOpts -jar $JARDIR/smali.jar out -o classes.dex || exit -3
        
        echo "将 classes.dex 添加到对应的 $TOFILE 中"
        jar uf $TOFILE classes.dex 
        
        echo "清理生成的 out 和 classes.dex"
        rm -r out classes.dex $FILE
        
        echo "优化 ..."
        zipalign 4 $TOFILE $TOFILE.aligned
        mv $TOFILE.aligned $TOFILE
}

ls $FRAMWORK/core.odex 2>/dev/null
if [ $? -eq 0 ] 
then
	echo "一定要先合并$FRAMWORK/core.odex !!!"
        deodex_file $FRAMWORK/core.odex jar
else
	echo "没有获取到core.odex文件，可能已经合并完成！"
	exit 0 
fi

echo "获取BOOTCLASSPATH ..."
for f in `ls $FRAMWORK/*.jar`
do
    CLASSPATH=$CLASSPATH:$f
done
echo "BOOTCLASSPATH=$CLASSPATH"

for file in `ls $FRAMWORK/*.odex`
do
        deodex_file $file jar
done

echo "合并$APP ..."
for file in `ls $APP/*.odex`
do
        deodex_file $file apk
done
