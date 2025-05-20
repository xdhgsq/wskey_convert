#!/bin/sh
#
#by:ITdesk
#
#获取当前脚本目录copy脚本之家

#set -x

Source="$0"
while [ -h "$Source"  ]; do
    dir_file="$( cd -P "$( dirname "$Source"  )" && pwd  )"
    Source="$(readlink "$Source")"
    [ $Source != /*  ] && Source="$dir_file/$Source"
done
dir_file="$( cd -P "$( dirname "$Source"  )" && pwd  )"
openwrt_script_config="/usr/share/jd_openwrt_script/script_config"
node="/usr/bin/node"
python3="/usr/bin/python3"

uname_if=$(cat /etc/profile | grep -o Ubuntu)

if [ "$uname_if" = "Ubuntu" ];then
	echo "当前环境为ubuntu"
	cron_file="/etc/crontab"
else
	cron_file="/etc/crontabs/root"
fi

red="\033[31m"
green="\033[32m"
yellow="\033[33m"
white="\033[0m" 

#企业微信
weixin_line="------------------------------------------------"

wrap="%0D%0A%0D%0A" #Server酱换行
wrap_tab="     "
current_time=$(date +"%Y-%m-%d")
by="#### 脚本BY ITdesk"

SCKEY=$(grep "let SCKEY" $openwrt_script_config/sendNotify.js  | awk -F "'" '{print $2}')
push_if=$(grep "push_if=" $openwrt_script_config/jd_openwrt_script_config.txt | awk -F "'" '{print $2}')
weixin2=$(grep "weixin2=" $openwrt_script_config/jd_openwrt_script_config.txt | awk -F "'" '{print $2}')


#使用那种进行转换wskey（py js）
if [ -z "$wskey_program" ];then
	echo  "${yellow}wskey_program=${green}py$white"
	wskey_program="py"
else
	echo  "$yellow检测到${green}wskey_program=$wskey_program$white"
fi


#是否再wskey转换失败的时候删除jdcookie.js里的失效ｃｋ（会打乱你的排序，wskey恢复以后会自己添加）
if [ -z "$ck_del" ];then
	echo  "$yellow${green}ck_del=no$white"
	ck_del="no"
else
	echo  "$yellow检测到${green}ck_del=$ck_del$white"
fi

#wskey白名单，用于转换失效但不删jdcookie.js里的ｃｋ（格式：pin1@pin2）
if [ -z "$wskey_ck_white" ];then
	echo  "$yellow${green}wskey_ck_white=""$white"
	wskey_ck_white=""
else
	echo  "$yellow检测到${green}wskey_ck_white=$wskey_ck_white$white"
fi

task() {
	cron_version="2.0"
	if [ `grep -o "wskey的定时任务$cron_version" $cron_file |wc -l` = "0" ]; then
		echo "不存在计划任务开始设置"
		task_delete
		task_add
		echo "计划任务设置完成"
	else
			echo "计划任务与设定一致，不做改变"
			cron_help="$green定时任务与设定一致$white"
	fi
}


task_add() {
cat >>$cron_file <<EOF
#**********这里是wskey的定时任务$cron_version版本#120#**********#
15 3,14 * * * $dir_file/wskey.sh run >/tmp/wskey.log 2>&1 #3点,14点15分执行全部脚本#120#
15 22 * * * $dir_file/wskey.sh  update_script >/tmp/wskey_update_script.log 2>&1 #21点15分更新脚本#120#
#**********这里是wskey的定时任务$cron_version版本#120#**********#
EOF
	/etc/init.d/cron restart
	cron_help="$yellow定时任务更新完成，记得看下你的定时任务$white"
}

task_delete() {
        sed -i '/#120#/d' $cron_file >/dev/null 2>&1
}

wskey_Conversion() {
	task
	rm -rf /tmp/you_cookie.txt
	rm -rf /tmp/wskey_error_pin.txt

	if [ ! `cat $dir_file/jdwskey.txt |grep -v "格式" | grep -v "#" |grep "wskey=" | wc -l` -ge "1" ];then
		echo  "$red$dir_file/jdwskey.txt 没有填写wskey$white"
		exit 0
	
	fi
	echo "-----------------------------------"
	echo "  　　　　　wskey　转换"
	echo "-----------------------------------"
	cat $dir_file/jdwskey.txt | grep -v "格式" | grep -v "#" |grep "wskey=" >/tmp/sort_wskey.txt

	wscookie_num=$(cat /tmp/sort_wskey.txt | wc -l)
	num="1"
	while [ $wscookie_num -ge $num ];do
		wskcookie=$(sed -n "$num p" /tmp/sort_wskey.txt | awk -F "//" '{print $1}' )
		pin=$(echo "$wskcookie" | awk -F "pin=" '{print $2}' | awk -F ";" '{print $1}')
		wskey=$(echo "$wskcookie" | awk -F "wskey=" '{print $2}' | awk -F ";" '{print $1}')

		if [ "${pin}" = "" ];then
			echo  "$pin$red用户名为空$white"
		elif [ "${wskey}" = "" ];then
			echo  "$wskeyn$red wskey值为空$white"
		else
			echo  "$yellow你一共有$wscookie_num个wskey，$white开始转换第$num个$green$pin$white的wskey"
			export WSCOOKIE="pin=${pin};wskey=${wskey};"
			
			if [ ${wskey_program} = "js" ];then
				run_cookie_result=$($node $dir_file/js/jd_wskey.js | grep "转换后的Cookie " | sed "s/转换后的Cookie //g")
			elif [ ${wskey_program} = "py" ];then
				run_cookie_result=$($python3 $dir_file/js/wskey.py | sed "s/转换后的Cookie: //g")
			else
				echo "wskey_program值填写错误"
				exit 0
			fi
			pt_pin=$(echo "$run_cookie_result" | awk -F "pt_pin=" '{print $2}' | awk -F ";" '{print $1}')
			pt_key=$(echo "$run_cookie_result" | awk -F "pt_key=" '{print $2}' | awk -F ";" '{print $1}')

			if [ "$pt_pin" = "xxx" ];then
				echo  "转换$pin$red异常，请检测你的pin和wskey有没有填错$white"
			elif [ "$pt_pin" = "******" ];then
				echo  "转换$pin$red异常，请检测你的pin和wskey有没有填错$white"
			elif [ "$pt_key" = "" ];then
				echo  "$red转换出来的pt_key为空异常，跳过这个$white"
				you_remark=$(cat $dir_file/jdwskey.txt | grep "$pin" | awk -F "\/\/" '{print $2}')
				if [ -z "$you_remark" ];then
					you_remark="没有备注"
				fi
				echo "$pin $you_remark$wrap" >>/tmp/wskey_error_pin.txt

				#删除转换过期ｃｋ
				if [ "$ck_del" = "yes" ];then
					wskey_ck_white_if=$(echo "$wskey_ck_white" | grep -o "$pin" | wc -l)
					if [ $wskey_ck_white_if = "1" ];then
						echo "白名单内ck，不进行删除"
					else
						ck_if=$(grep "$pin" $openwrt_script_config/jdCookie.js | wc -l )
						if [ "1"  -ge "$ck_if" ];then
							echo  "$yellow先删除一下$openwrt_script_config/jdCookie.js里的$pin，后面正常了以后会添加回去$white"
							echo ""
							sed -i "/$pin/d" $openwrt_script_config/jdCookie.js
						fi
					fi
				else
					echo "wskey转换失败，不删除jdCookie.js里的$pin"
				fi
			else
				if [ "$pin" = "$pt_pin" ];then
					echo "$run_cookie_result" >>/tmp/you_cookie.txt
				else
					echo "pt_key=$pt_key;pt_pin=$pin;" >>/tmp/you_cookie.txt
				fi
				echo  "第$num个$green$pin$white的wskey转换完成$white"
			fi
		fi
		
		num=$(($num + 1))
	done
	wskey_push

	echo  "$yellow\n开始为你查找是否存在这个cookie，有就更新，没有就新增。。。$white\n"
	if_you_cookie=$(cat /tmp/you_cookie.txt | wc -l)
	if [ $if_you_cookie = "1" ];then
		you_cookie=$(cat /tmp/you_cookie.txt)
		new_pt=$(echo $you_cookie)
		pt_pin=$(echo $you_cookie | awk -F "pt_pin=" '{print $2}' | awk -F ";" '{print $1}')
		pt_key=$(echo $you_cookie | awk -F "pt_key=" '{print $2}' | awk -F ";" '{print $1}')
		if [ `echo "$pt_pin" | wc -l` = "1"  ] && [ `echo "$pt_key" | wc -l` = "1" ];then
			addcookie_replace
		else
			echo "$pt_pin $pt_key　$red异常$white"
		fi
	else
		num="1"
		while [ $if_you_cookie -ge $num ];do
			clear
			echo  "------------------------------------------------------------------------------"
			echo  "你一共输入了$yellow$if_you_cookie$white条cookie现在开始替换第$green$num$white条cookie"
			you_cookie=$(sed -n "$num p" /tmp/you_cookie.txt)
			new_pt=$(echo $you_cookie)
			pt_pin=$(echo $you_cookie | awk -F "pt_pin=" '{print $2}' | awk -F ";" '{print $1}')
			pt_key=$(echo $you_cookie | awk -F "pt_key=" '{print $2}' | awk -F ";" '{print $1}')

			if [ `echo "$pt_pin" | wc -l` = "1"  ] && [ `echo "$pt_key" | wc -l` = "1" ];then
				addcookie_replace
			else
				echo  "$pt_pin $pt_key　$red异常$white"
			fi
			num=$(( $num + 1))
		done

	fi
	echo  "$green你一共有$wscookie_num个wskey，已经替换完成$white"
	sleep 2
	echo  "$green开始更新并发文件夹$white"
	sh /usr/share/jd_openwrt_script/JD_Script/jd.sh update
}


wskey_push() {

	if [ -f /tmp/wskey_error_pin.txt ];then
		text=$(cat /tmp/wskey_error_pin.txt)
		content="#### wskey转换失败的有:$wrap$wrap_tab$text"
		#开始推送异常的wskey名单
		server_content=$(echo "$content${by}" | sed "s/$wrap_tab####/####/g" )
		weixin_content_sort=$(echo  "$content" |sed "s/####/<hr\/><b>/g" |sed "s/$wrap$wrap_tab/<br>/g" |sed "s/$wrap/<br>/g" |sed "s/:/:<hr\/><\/b>/g"  )
		weixin_content=$(echo "$weixin_content_sort<br><b>$by" | sed "s/https\:<hr\\/><\\/b>/https:/g" | sed "s/#### /<br><b>/g")
		weixin_desp=$(echo "$weixin_content" | sed "s/<hr\/><b>/$weixin_line\n/g" |sed "s/<hr\/><\/b>/\n$weixin_line\n/g"| sed "s/<b>/\n/g"| sed "s/<br>/\n/g" | sed "s/<br><br>/\n/g" | sed "s/#/\n/g" )
		title="wskey转换检测"
		push_menu
	fi
}


addcookie_replace(){
	if [ `cat $openwrt_script_config/jdCookie.js | grep "$pt_pin" | wc -l` = "1" ];then
		echo  "$green检测到 $yellow${pt_pin}$white 已经存在，开始更新cookie。。$white\n"
		old_pt=$(cat $openwrt_script_config/jdCookie.js | grep "$pt_pin" | sed -e "s/',//g" -e "s/'//g")
		old_pt_key=$(cat $openwrt_script_config/jdCookie.js | grep "$pt_pin" | awk -F "pt_key=" '{print $2}' | awk -F ";" '{print $1}')
		sed -i "s/$old_pt_key/$pt_key/g" $openwrt_script_config/jdCookie.js
		echo  "$green 旧cookie：$yellow${old_pt}$white\n\n$green更新为$white\n\n$green   新cookie：$yellow${new_pt}$white\n"
		echo  "------------------------------------------------------------------------------"
	else
		echo  "$green检测到 $yellow${pt_pin}$white 不存在，开始新增cookie。。$white\n"
		cookie_quantity=$( cat $openwrt_script_config/jdCookie.js | sed -e "s/pt_key=XXX;pt_pin=XXX//g" -e "s/pt_pin=(//g" -e "s/pt_key=xxx;pt_pin=xxx//g"| grep "pt_pin" | wc -l)
		i=$(expr $cookie_quantity + 5)
		you_remark=$(cat $dir_file/jdwskey.txt |grep "${pt_pin}"| awk -F ";" '{print $3}' | sed "s/\/\///g")
		if [ ! $you_remark ];then
			you_remark1=""
		else
			you_remark1="\/\/$you_remark"
		fi
		
		if [ $i = "5" ];then
			sed -i "5a \  '$you_cookie\',$you_remark1" $openwrt_script_config/jdCookie.js
		else
			sed -i "$i a\  '$you_cookie\',$you_remark1" $openwrt_script_config/jdCookie.js
		fi
		echo  "\n已将新cookie：$green${you_cookie}$white\n\n插入到$yellow$openwrt_script_config/jdCookie.js$white 第$i行\n"
		cookie_quantity1=$( cat $openwrt_script_config/jdCookie.js | sed -e "s/pt_key=XXX;pt_pin=XXX//g" -e "s/pt_pin=(//g" -e "s/pt_key=xxx;pt_pin=xxx//g"| grep "pt_pin" | wc -l)
		echo  "------------------------------------------------------------------------------"
		echo  "$yellow你增加了账号：$green${pt_pin}$white$yellow 现在cookie一共有$cookie_quantity1个，具体以下：$white"
		cat $openwrt_script_config/jdCookie.js | sed -e "s/pt_key=XXX;pt_pin=XXX//g" -e "s/pt_pin=(//g" -e "s/pt_key=xxx;pt_pin=xxx//g"| grep "pt_pin" | sed -e "s/',//g" -e "s/'//g"
		echo  "------------------------------------------------------------------------------"
	fi

	check_cooike
	sed -n  '1p' $openwrt_script_config/check_cookie.txt
	grep "$pt_pin" $openwrt_script_config/check_cookie.txt
}


check_cooike() {
#将cookie获取时间导入文本
	if [ ! -f $openwrt_script_config/check_cookie.txt  ];then
		echo "备注      Cookie             添加时间      预计到期时间(不保证百分百准确)" > $openwrt_script_config/check_cookie.txt
	fi
	sed -i "/添加时间/d" $openwrt_script_config/check_cookie.txt
	sed -i "1i\备注      Cookie             添加时间      预计到期时间(不保证百分百准确)" $openwrt_script_config/check_cookie.txt
	Current_date=$(date +%Y-%m-%d)
	Current_date_m=$(echo $Current_date | awk -F "-" '{print $2}')
	if [ "$Current_date_m" = "12"  ];then
		Expiration_date=$(date +%Y-01-%d)
	else
		m=$(expr $Current_date_m + 1)
		Expiration_date=$(date +%Y-$m-%d)
		#$这个不要改动，没有写错
	fi
	sed -i "/$pt_pin/d" $openwrt_script_config/check_cookie.txt
	remark=$(grep "$pt_pin" $openwrt_script_config/jdCookie.js | awk -F "," '{print $2}' | sed "s/\/\///g" | sed 's/[:space:]//g')
	echo "$remark    $pt_pin    $Current_date    $Expiration_date" >> $openwrt_script_config/check_cookie.txt
}

addwskey() {
	cat /tmp/jdck.txt > /tmp/jdck_wskey.txt
	echo  "${yellow}\n开始为你查找是否存在这个wskey，有就更新，没有就新增。。。${white}\n"
	sleep 2
	if_jdck_wskey=$(cat /tmp/jdck_wskey.txt | wc -l)
	if [ $if_jdck_wskey = "1" ];then
		jdck_wskey=$(cat /tmp/jdck_wskey.txt)
		new_pt=$(echo $jdck_wskey)
		pin=$(echo $jdck_wskey | awk -F "pin=" '{print $2}' | awk -F ";" '{print $1}')
		wskey=$(echo $jdck_wskey | awk -F "wskey=" '{print $2}' | awk -F ";" '{print $1}')
		you_remark=$(echo $jdck_wskey | awk -F "\/\/" '{print $2}')
		if [ `echo "$pin" | wc -l` = "1"  ] && [ `echo "$wskey" | wc -l` = "1" ];then
			addwskey_replace
		else
			echo "$pin $wskey　$you_remark $red异常${white}"
			sleep 2
		fi
	else
		num="1"
		while [ $if_jdck_wskey -ge $num ];do
			clear
			echo  "------------------------------------------------------------------------------"
			echo  "你一共输入了${yellow}$if_jdck_wskey${white}条wskey现在开始替换第${green}$num${white}条wskey"
			jdck_wskey=$(sed -n "$num p" /tmp/jdck_wskey.txt)
			new_pt=$(echo $jdck_wskey)
			pin=$(echo $jdck_wskey | awk -F "pin=" '{print $2}' | awk -F ";" '{print $1}')
			wskey=$(echo $jdck_wskey | awk -F "wskey=" '{print $2}' | awk -F ";" '{print $1}')
			you_remark=$(echo $jdck_wskey | awk -F "\/\/" '{print $2}')

			if [ `echo "$pin" | wc -l` = "1"  ] && [ `echo "$wskey" | wc -l` = "1" ];then
				addwskey_replace
				sleep 2
			else
				echo  "$pin $wskey $you_remark　$red异常${white}"
				sleep 2
			fi
			num=$(( $num + 1))
		done
	fi
}

addwskey_replace(){
	if [ `cat $dir_file/jdwskey.txt | grep "$pin;" | wc -l` = "1" ];then
		echo  "${green}检测到 ${yellow}${pin}${white} 已经存在，开始更新cookie。。${white}\n"
		sleep 2
		old_pt=$(cat $dir_file/jdwskey.txt | grep "$pin" | sed -e "s/',//g" -e "s/'//g")
		old_pt_key=$(cat $dir_file/jdwskey.txt | grep "$pin" | awk -F "wskey=" '{print $2}' | awk -F ";" '{print $1}')
		sed -i "s/$old_pt_key/$wskey/g" $dir_file/jdwskey.txt
		echo  "${green} 旧cookie：${yellow}${old_pt}${white}\n\n${green}更新为${white}\n\n${green}   新cookie：${yellow}${new_pt}${white}\n"
		echo  "------------------------------------------------------------------------------"
	else
		echo  "${green}检测到 ${yellow}${pin}${white} 不存在，开始新增cookie。。${white}\n"
		sleep 2
		cookie_quantity=$( cat $dir_file/jdwskey.txt | wc -l)
		i="$cookie_quantity"
		if [ $i = "5" ];then
			sed -i "5a pin=${pin};wskey=${wskey};" $dir_file/jdwskey.txt
		else
			sed -i "${i}a pin=${pin};wskey=${wskey};" $dir_file/jdwskey.txt
		fi
		echo  "\n已将新cookie：${green}${jdck_wskey}${white}\n\n插入到${yellow}$dir_file/jdwskey.txt${white} 第$i行\n"
		cookie_quantity1=$( cat $dir_file/jdwskey.txt | grep -v "pin=xxx;wskey=xxxx;" | grep "pin" | wc -l)
		echo  "------------------------------------------------------------------------------"
		echo  "${yellow}你增加了账号：${green}${pin}${white}${yellow} 现在cookie一共有$cookie_quantity1个，具体以下：${white}"
		cat $dir_file/jdwskey.txt | grep -v "pin=xxx;wskey=xxxx;"
		echo  "------------------------------------------------------------------------------"
	fi

}

push_menu() {
case "$push_if" in
		0)
			#server酱和微信同时推送
			server_push
			weixin_push
			push_if="3"
			weixin_push
		;;
		1)
			#server酱推送
			server_push
		;;
		2)
			#微信推送
			weixin_push
		;;
		3)
			#将shell模块检测推送到另外一个小程序上（举个例子，一个企业号，两个小程序，小程序１填到sendNotify.js,这样子js就会推送到哪里，小程序２填写到jd_openwrt_config这样jd.sh写的模块就会推送到小程序2
			weixin_push
		;;
		*)
			echo  "$red填写错误，不进行推送$white"
		;;
	esac

}

server_push() {

if [ ! $SCKEY ];then
	echo "没找到Server酱key不做操作"
else
	echo  "$green server酱开始推送$title$white"
	curl -s "http://sc.ftqq.com/$SCKEY.send?text=$title++`date +%Y-%m-%d`++`date +%H:%M`" -d "&desp=$server_content" >/dev/null 2>&1

	if [ $? -eq 0 ]; then
		echo  "$green server酱推送完成$white"
	else
		echo  "$red server酱推送失败。请检查报错代码$title$white"
	fi
fi

}

weixin_push() {
current_time=$(date +%s)
expireTime="7200"
if [ $push_if = "3" ];then
	weixinkey=$(grep "weixin2" $openwrt_script_config/jd_openwrt_script_config.txt | awk -F "'" '{print $2}')
else
	weixinkey=$(grep "let QYWX_AM" $openwrt_script_config/sendNotify.js | awk -F "'" '{print $2}')
fi

#企业名
corpid=$(echo $weixinkey | awk -F "," '{print $1}')
#自建应用，单独的secret
corpsecret=$(echo $weixinkey | awk -F "," '{print $2}')
# 接收者用户名,@all 全体成员
touser=$(echo $weixinkey | awk -F "," '{print $3}')
#应用ID
agentid=$(echo $weixinkey | awk -F "," '{print $4}')
#图片id
media_id=$(echo $weixinkey | awk -F "," '{print $5}')

weixin_file="$openwrt_script_config/weixin_token.txt"
time_before=$(cat $weixin_file |grep "$corpsecret" | awk '{print $4}')


if [ ! $time_before ];then
	#获取access_token
	access_token=$(curl "https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=${corpid}&corpsecret=${corpsecret}" | sed "s/,/\n/g" | grep "access_token" | awk -F ":" '{print $2}' | sed "s/\"//g")
	sed -i "/$corpsecret/d" $weixin_file
	echo "$corpid $corpsecret $access_token `date +%s`" >> $weixin_file
	echo ">>>刷新access_token成功<<<"
else
	if [ $(($current_time - $time_before)) -gt "$expireTime" ];then
		#获取access_token
		access_token=$(curl "https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=${corpid}&corpsecret=${corpsecret}" | sed "s/,/\n/g" | grep "access_token" | awk -F ":" '{print $2}' | sed "s/\"//g")
		sed -i "/$corpsecret/d" $weixin_file
		echo "$corpid $corpsecret $access_token `date +%s`" >>$weixin_file
		echo ">>>刷新access_token成功<<<"
	else
		echo "access_token 还没有过期，继续用旧的"
		access_token=$(cat $weixin_file |grep "$corpsecret" | awk '{print  $3}')
	fi
fi

if [ ! $media_id ];then
	msg_body="{\"touser\":\"$touser\",\"agentid\":$agentid,\"msgtype\":\"text\",\"text\":{\"content\":\"$title\n$weixin_desp\"}}"
else
	msg_body="{\"touser\":\"$touser\",\"agentid\":$agentid,\"msgtype\":\"mpnews\",\"mpnews\":{\"articles\":[{\"title\":\"$title\",\"thumb_media_id\":\"$media_id\",\"content\":\"$weixin_content\",\"digest\":\"$weixin_desp\"}]}}"
fi
	echo  "$green 企业微信开始推送$title$white"
	curl -s "https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token=$access_token" -d "$msg_body"

	if [ $? -eq 0 ]; then
		echo  "$green 企业微信推送成功$title$white"
	else
		echo  "$red 企业微信推送失败。请检查报错代码$title$white"
	fi

}


update_script() {
	echo  "$green update_script $white"
	cd $dir_file
	git fetch --all
	git reset --hard origin/main
	echo  "$green update_script$white"
}


if_system() {

	if [ -f $dir_file/jdwskey.txt ];then
		echo "jdwskey.txt文件存在，不做操作"
	else
		echo "格式是 pin=xxx;wskey=xxxx;" >$dir_file/jdwskey.txt
	fi

	#添加系统变量
	wskey_path=$(cat /etc/profile | grep -o wskey.sh | wc -l)
	if [ "$wskey_path" = "0" ]; then
		echo "export wskey_file=$dir_file" >> /etc/profile
		echo "export wskey=$dir_file/wskey.sh" >> /etc/profile
		source /etc/profile
	fi
}

run() {
	wskey_Conversion
}


if_system
action1="$1"
if [ -z $action1 ]; then
	wskey_Conversion
else
	case "$action1" in
		addwskey|run|if_system|update_script)
		$action1
		;;
		*)
		echo "命令不存在"
		;;
	esac
fi


















