.PHONY: setup analyze init start
init:
	./sql/init.sh
setup: 
	export PATH=$(HOME)/local/golang/bin:$(HOME)/go/bin:$(PATH)
analyze: alpsave slow-show
start: slow-on build pprof


ALPSORT=sum
ALPM="/assets/.+,/images/.+,/api/app/rides/[-A-Z0-9]+/evaluation,/api/chair/rides/[-A-Z0-9]+/status,/api/app/nearby-chairs\?,/api/owner/sales\?"
OUTFORMAT=count,method,uri,min,max,sum,avg,p99
.PHONY: alp alpsave alpload
alp: 
	sudo alp ltsv --file=/var/log/nginx/access.log --nosave-pos --pos /tmp/alp.pos --sort $(ALPSORT) --reverse -o $(OUTFORMAT) -m $(ALPM) -q
alpsave:
	sudo alp ltsv --file=/var/log/nginx/access.log --pos /tmp/alp.pos --dump /tmp/alp.dump --sort $(ALPSORT) --reverse -o $(OUTFORMAT) -m $(ALPM) -q
alpload:
	sudo alp ltsv --load /tmp/alp.dump --sort $(ALPSORT) --reverse -o count,method,uri,min,max,sum,avg,p99 -q

# mydql関連
MYSQL_HOST="127.0.0.1"
MYSQL_PORT=3306
MYSQL_USER=isucon
MYSQL_DBNAME=isuride
MYSQL_PASS=isucon
MYSQL=mysql -h$(MYSQL_HOST) -P$(MYSQL_PORT) -u$(MYSQL_USER) -p$(MYSQL_PASS) $(MYSQL_DBNAME)
SLOW_LOG=/tmp/slow-query.log
# slow-wuery-logを取る設定にする
# DBを再起動すると設定はリセットされる
.PHONY: slow-on slow-off slow-show db-conn
slow-on:
	sudo rm $(SLOW_LOG)
	sudo systemctl restart mysql
	$(MYSQL) -e "set global slow_query_log_file = '$(SLOW_LOG)'; set global long_query_time = 0.001; set global slow_query_log = ON;"
slow-off:
	$(MYSQL) -e "set global slow_query_log = OFF;"
# mysqldumpslowを使ってslow wuery logを出力
# オプションは合計時間ソート
slow-show:
	sudo mysqldumpslow -s t $(SLOW_LOG) | head -n 20
db-conn:
	$(MYSQL)

# ビルドして、サービスのリスタートを行う
# リスタートを行わないと反映されないので注意
.PHONY: build pprof
build:
	cd /home/isucon/webapp/go; \
	go build -o isuride; \
	sudo systemctl restart isuride-go.service;
# pprofのデータをwebビューで見る
# サーバー上で sudo apt install graphvizが必要
pprof:
	go tool pprof -http=0.0.0.0:6070 -seconds 90 /home/isucon/webapp/go/isuride http://localhost:6060/debug/pprof/profile 
