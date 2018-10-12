#!/bin/sh
check_url="https://visitor.ai-ways.com/attendance/api/v1/search_employee/"

http_code(){
/usr/bin/curl -o /dev/null -s -w %{http_code} -X POST -H "Content-Type: application/json" $check_url  -d '{ "interviewee_name":"谷峰" }'
}

time_total(){
/usr/bin/curl -o /dev/null -s -w %{time_total} -X POST -H "Content-Type: application/json" $check_url  -d '{ "interviewee_name":"谷峰" }'
}
case $1 in

http_code)

        http_code

;;
time_total)
		time_total
;;
*)
echo "目前只支持 http_code 和 time_total 两个参数"
;;
esac