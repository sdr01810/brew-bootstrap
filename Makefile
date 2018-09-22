## GNU makefile for this package.
##
## See Makefile.core for usage guidelines.
##

distribution_candidate_top_files_and_dirs_glob := $(strip \
	*.md *.txt $(wildcard bin etc lib libexec share) \
)

##

include Makefile.core

## EOF
