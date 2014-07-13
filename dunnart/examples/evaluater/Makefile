calc: evaluator.d parser.d
	dmd -I../.. evaluator.d parser.d ../../../grallina/babs/lexan.d ../../../grallina/dunnart/templates.d

parser.d: parser.ddgs ../../ddpg
	../../ddpg -f parser.ddgs
