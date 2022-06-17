all:
	rm -rf  *~ */*~ src/*.beam src/*~ test/*.beam erl_cra*;
	rm -rf _build/default/lib/node/ebin;
	rm -rf   rebar.lock;
	rm -rf  test_ebin ebin;
	mkdir ebin;		
	rebar3 compile;	
	cp _build/default/lib/node/ebin/* ebin;
	rm -rf _build test_ebin logs log;
	echo Done
check:
	rebar3 check

eunit:
	rm -rf  *~ */*~ src/*.beam src/*~ test/*.beam erl_cra*;
	rm -rf _build/default/lib/node/ebin;
	rm -rf   rebar.lock;
	rm -rf  test_ebin ebin;
	rebar3 compile;
	mkdir test_ebin;
	mkdir ebin;
	cp _build/default/lib/node/ebin/* ebin;
	erlc -o test_ebin test/*.erl;
	erl -pa ebin -pa test_ebin\
	    -pa /home/joq62/erlang/infrastructure/nodelog/ebin\
	    -pa /home/joq62/erlang/infrastructure/common/ebin\
	    -sname node -run basic_eunit start -setcookie cookie_test
