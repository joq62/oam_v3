all:
#	service
	rm -rf ebin/* src/*.beam *.beam test_src/*.beam test_ebin;
	rm -rf *.applications ~/*.applications *configurations test_src/test_configurations;
	rm -rf  *~ */*~  erl_cra*;
#	common
#	cp ../common/src/*.app ebin;
	erlc -I ../../include -o ebin ../../common/src/*.erl;
#	sd
	cp ../sd/src/*.app ebin;
	erlc -I ../../include -o ebin ../sd/src/*.erl;
#	dbase_infra
	cp ../dbase_infra/src/*.app ebin;
	erlc -I ../../include -I ../controller/include -I ../dbase_infra/include -o ebin ../dbase_infra/src/*.erl;
#	host
	erlc -o ebin ../host/src/pod.erl;
#	app
	cp src/*.app ebin;
	erlc -I ../../include -I ../controller/include -I ../dbase_infra/include -o ebin src/*.erl;
	echo Done
unit_test:
	rm -rf ebin/* src/*.beam *.beam test_src/*.beam test_ebin;
	rm -rf *.applications ~/*.applications *configurations;
	rm -rf  *~ */*~  erl_cra*;
	mkdir test_ebin;
	cp -R ../test_configurations .;
#	common
#	cp ../common/src/*.app ebin;
	erlc -D unit_test -I ../../include -o ebin ../../common/src/*.erl;
#	sd
	cp ../sd/src/*.app ebin;
	erlc -D unit_test -I ../../include -o ebin ../sd/src/*.erl;
#	dbase_infra
	cp ../dbase_infra/src/*.app ebin;
	erlc -D unit_test -I ../../include -I ../controller/include -I ../dbase_infra/include -o ebin ../dbase_infra/src/*.erl;
#	host
	erlc -D unit_test -o ebin ../host/src/pod.erl;
#	app
	cp src/*.app ebin;
	erlc -I ../../include -I ../controller/include -I ../dbase_infra/include -o ebin src/*.erl;
#	test application
	cp test_src/*.app test_ebin;
	erlc -D unit_test -I ../../include -I ../controller/include -o test_ebin test_src/*.erl;
	erl -pa ebin -pa test_ebin\
	    -setcookie cookie_test\
	    -hidden\
	    -sname oam\
	    -unit_test monitor_node test\
	    -unit_test cluster_id test\
	    -unit_test cookie cookie_test\
	    -run unit_test start_test test_src/test.config
