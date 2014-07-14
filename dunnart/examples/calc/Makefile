calc: calc.d parser.d
	dmd -I../.. calc.d parser.d ../../../grallina/babs/lexan.d ../../../grallina/dunnart/templates.d

parser.d: parser.ddgs ../../ddpg
	../../ddpg -f --expect=1 parser.ddgs

test: calc test_data
	./calc test_data
