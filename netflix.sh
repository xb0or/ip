#! /bin/bash


#############系统检测组件#############

#检查系统
check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
}

#检查Linux版本
check_version(){
	if [[ -s /etc/redhat-release ]]; then
		version=`grep -oE  "[0-9.]+" /etc/redhat-release | cut -d . -f 1`
	else
		version=`grep -oE  "[0-9.]+" /etc/issue | cut -d . -f 1`
	fi
	bit=`uname -m`
	if [[ ${bit} = "x86_64" ]]; then
		bit="x64"
	else
		bit="x32"
	fi
}



#############系统检测组件#############
check_sys
check_version
[[ ${release} != "debian" ]] && [[ ${release} != "ubuntu" ]] && [[ ${release} != "centos" ]] && echo -e "${Error} 本脚本不支持当前系统 ${release} !" && exit 1
start_menu



#安装wireguard

echo "检测wireguard安装情况" 
modprobe wireguard
if lsmod | grep wireguard ; then
    echo "wireguard 已安装"
else
    echo "wireguard 未安装"
    echo "请根据官网教程安装: https://www.wireguard.com/install/"
    if [[ "$release" == "centos" ]]; then
		sudo yum install epel-release elrepo-release -y
        sudo yum install yum-plugin-elrepo -y
        sudo yum install kmod-wireguard wireguard-tools -y
        modprobe wireguard
	if [[ "$release" == "debian" ]]; then
       echo "deb http://deb.debian.org/debian/ unstable main" > /etc/apt/sources.list.d/unstable-wireguard.list
       printf 'Package: *\nPin: release a=unstable\nPin-Priority: 150\n' > /etc/apt/preferences.d/limit-unstable
       apt-get update -y
       apt-get install wireguard-dkms wireguard-tools -y
       modprobe wireguard
     if [[ "$release" == "ubuntu" ]]; then
     add-apt-repository ppa:wireguard/wireguard
     apt-get update -y
     apt-get install wireguard -y
     modprobe wireguard
	fi
    exit
fi

mkdir netflixjs
cd netflixjs


wget -O wgcf https://github.com/ViRb3/wgcf/releases/download/v2.2.2/wgcf_2.2.2_linux_amd64
chmod +x wgcf
./wgcf register
./wgcf generate

if ls -l wgcf-profile.conf;then
    echo "注册成功"
else
    echo "warp注册失败"
    echo "请进入netflxjs文件夹 输入"
    echo "./wgcf register"
    echo "./wgcf generate"
    echo "来获取warp的wg文件"
    exit
fi

if ls -l netflixjs.conf; then
    rm -rf netflixjs.conf
fi

if ls -l all.txt; then
    rm -rf all.txt
fi

wget https://raw.githubusercontent.com/xb0or/ip/main/all.txt
var=$(cat all.txt)
if ls -l netflixjs.conf; then
    rm -rf netflixjs.conf
fi

cat wgcf-profile.conf | while read line
do
    if [ "$line"x = "AllowedIPs = 0.0.0.0/0"x ]; then
       echo "AllowedIPs = $var" >> netflixjs.conf
    else
        echo $line >> netflixjs.conf
    fi
done

rm -rf all.txt

mv netflixjs.conf /etc/wireguard/netflixjs.conf

wg-quick up netflixjs

result=`curl -m 10 -o /dev/null -s -w %{http_code} https://www.netflix.com/title/70143836`;
if [ "$result"x = "301"x ];then
    echo "***************"
    echo "解锁成功"
    echo "如果想开机启动请输入"
    echo "systemctl enable wg-quick@netflixjs.service"
    echo "***************"
else
    echo "解锁失败"
fi
