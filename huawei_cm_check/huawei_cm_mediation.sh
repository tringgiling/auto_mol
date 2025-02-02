#!/bin/bash
tanggal=`date "+%d_%b_%Y"`; jam=`date "+%T"`  #buat detail kapan pemeriksaan dilakukan

####Khusus SOCKS Proxy Linux
#default_ip_socks="192.168.42.129"		#Khusus vpn iqbal
#default_port_socks="1080"					#Khusus vpn iqbal
#echo -n "Masukan IP SOCKS Proxy untuk terhubung ke mediation server, default ($default_ip_socks) : "
#read -r ip_socks; if [[ -z $ip_socks ]] ; then ip_socks="$default_ip_socks" ; else echo "IP Socks = $ip_socks"; fi
#echo -n "Masukan Port SOCKS proxy, default ($default_port_socks) : "
#read -r port_socks ; if [[ -z $port_socks ]] ; then port_socks="$default_port_socks" ; else echo "Port Socks = $port_socks"; fi

#sftp -oProxyCommand="netcat -v -x $ip_socks:$port_socks %h %p" sse@10.62.101.88 22 > "file_check.txt" << EOF
####

(lftp -c "set sftp:connect-program 'ssh -o StrictHostKeyChecking=no'; open -u sse,Tsel2020! sftp://10.62.101.88; 
cls -l --sort=date /opt/nfs-data/shares/raw_data/huawei/sd/2g/oss_Bali;
cls -l --sort=date /opt/nfs-data/shares/raw_data/huawei/sd/2g/oss_East_Java;
cls -l --sort=date /opt/nfs-data/shares/raw_data/huawei/sd/2g/oss_South_Sumatera;
cls -l --sort=date /opt/nfs-data/shares/raw_data/huawei/sd/2g/oss_Central_Java;
cls -l --sort=date /opt/nfs-data/shares/raw_data/huawei/sd/2g/oss_Jabodetabek_18;
cls -l --sort=date /opt/nfs-data/shares/raw_data/huawei/sd/2g/oss_North_Sumatera;
cls -l --sort=date /opt/nfs-data/shares/raw_data/huawei/sd/2g/oss_West_Java;
cls -l --sort=date /opt/nfs-data/shares/raw_data/huawei/sd/2g/oss_Central_Sumatera;
cls -l --sort=date /opt/nfs-data/shares/raw_data/huawei/sd/2g/oss_Jabodetabek_23;
cls -l --sort=date /opt/nfs-data/shares/raw_data/huawei/sd/2g/oss_Jabodetabek_26;
cls -l --sort=date /opt/nfs-data/shares/raw_data/huawei/sd/2g/oss_Nusa_Tenggara;
cls -l --sort=date /opt/nfs-data/shares/raw_data/huawei/sd/3g/oss_Bali;
cls -l --sort=date /opt/nfs-data/shares/raw_data/huawei/sd/3g/oss_East_Java;
cls -l --sort=date /opt/nfs-data/shares/raw_data/huawei/sd/3g/oss_South_Sumatera;
cls -l --sort=date /opt/nfs-data/shares/raw_data/huawei/sd/3g/oss_Central_Java;
cls -l --sort=date /opt/nfs-data/shares/raw_data/huawei/sd/3g/oss_Jabodetabek_18;
cls -l --sort=date /opt/nfs-data/shares/raw_data/huawei/sd/3g/oss_North_Sumatera;
cls -l --sort=date /opt/nfs-data/shares/raw_data/huawei/sd/3g/oss_West_Java;
cls -l --sort=date /opt/nfs-data/shares/raw_data/huawei/sd/3g/oss_Central_Sumatera;
cls -l --sort=date /opt/nfs-data/shares/raw_data/huawei/sd/3g/oss_Jabodetabek_23;
cls -l --sort=date /opt/nfs-data/shares/raw_data/huawei/sd/3g/oss_Jabodetabek_26;
cls -l --sort=date /opt/nfs-data/shares/raw_data/huawei/sd/3g/oss_Nusa_Tenggara;
quit") >> "file_check.txt"


## Pengelompokan sesuai MBSC/RNC dilanjut pengelompokan sesuai OSS
( mkdir "cfgmml" 
grep "MBSC" "file_check.txt" > "cfgmml/file_check_MBSC.txt"
grep "RNC" "file_check.txt" > "cfgmml/file_check_RNC.txt"
cd cfgmml/ || return

kelompok_oss()
{
	echo "sedang mengelompokan OSS $1"
	grep "$1" file_check_MBSC.txt >> "2G_$1.txt" 
	grep "$1" file_check_RNC.txt >> "3G_$1.txt"
}

kelompok_oss "Jabodetabek_23"
kelompok_oss "Nusa_Tenggara"
kelompok_oss "North_Sumatera"
kelompok_oss "East_Java"
kelompok_oss "South_Sumatera"
kelompok_oss "Jabodetabek_26" 
kelompok_oss "Central_Java"
kelompok_oss "Jabodetabek_18"
kelompok_oss "Bali"
kelompok_oss "West_Java"
kelompok_oss "Central_Sumatera"
kelompok_oss "South_Sumatera"
kelompok_oss "North_Sumatera"
)

## Mencocokan antara database dan CFGMML, bila ada yang kurang, lempar ke file csv untuk dilaporkan
(
cd database/ || return
(echo "Diperiksa Pada ,$tanggal" ; echo "Jam ,$jam" ; echo " ";echo "OSS,BSC/RNC,Part of 66 City?,Status Mediation,Time_Stamp Mediation" ) >> "file_check.csv"
for list in $(cat list_database.txt) ; do
echo "Sedang mengecek OSS $list"
	for item in $(cat $list) ; do
	echo "Lagi check $item"
	echo "$list" | sed 's/.txt//g' | sed 's/_non_66//g' |tr "\n" "," >> "file_check.csv"       #Kolom OSS
	echo "$item" | tr '\n' ',' >> "file_check.csv"     #Kolom BSC/RNC
	(echo "$list" | grep -q "non_66";  if [ $? -eq 1 ] ; then echo "Yes" | tr '\n' ',' ; else echo "No" | tr '\n' ',' ; fi ) >> "file_check.csv" # Kolom Part 66 City
	clear_list=$(echo "$list" | sed 's/_non_66//g') #pengaman untuk proses membanding database dengan file non 66 city
	clear_item=$(echo "$item" | sed 's/\#//g') #pengaman untuk MBSC yang dikasih tanda "#" karna statusnya lagi dc sementara
	grep "$clear_item"_ "../cfgmml/$clear_list"  ; if [ $? -eq 0 ] ; then echo "ada" | tr '\n' ',' >> "file_check.csv" ; else echo "tidak ditemukan" | tr '\n' ',' >> "file_check.csv"; fi #Kolom Status
	(grep -oP "(?<="$clear_item"_)[^ ][0-9]{1,8}"  "../cfgmml/$clear_list" || if [ $? -eq 1 ] ; then echo "-"  ; else return; fi) | head -1>> "file_check.csv" #Kolom Time_stamp
	done
done
echo "Mencocokan file selesai, saatnya save file ke folder yang diinginkan"
mv "file_check.csv" ../"file_medi_check_$tanggal.csv"
)

##aktifitas selesai, saatnya simpen file penting dan bersih bersih
simpen_file=$(zenity --file-selection --directory --title="Pilih tempat simpan file" --filename=/home/iqbal/Kerja/imobi/task/Operation/log/)
zip -r file_medi_check.zip cfgmml/ file_check.txt
mv file_medi_check_$tanggal.csv file_medi_check.zip "$simpen_file" #pindahin file csv ke folder pilihan pengguna
rm --recursive cfgmml file_check.txt #bersihin folder tempat ekstrak file, dll

