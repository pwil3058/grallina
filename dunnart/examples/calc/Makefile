calc: calc.d parser.d
	dmd -I../.. calc.d parser.d ../../../grallina/babs/lexan.d ../../../grallina/dunnart/templates.d

parser.d: parser.ddgs ../../ddpg
	../../ddpg -f parser.ddgs

test: calc test_data
	./calc test_data
