# WEB make targets, for Libreswan
#
# Copyright (C) 2017-2018 Andrew Cagney
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.  See <https://www.gnu.org/licenses/gpl2.txt>.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.

# If the $(LSW_WEBDIR) directory exists, publish the results in
# HTML/json form.
#
# Because web-page dependencies are very heavy (invoking git et.al.)
# much of this code needs to be made conditional.

LSW_WEBDIR ?= $(top_srcdir)/RESULTS
WEB_SUMMARYDIR ?= $(LSW_WEBDIR)
ifneq ($(wildcard $(WEB_SUMMARYDIR)),)
WEB_ENABLED ?= true
endif

WEB_UTILSDIR ?= testing/utils
WEB_SOURCEDIR ?= testing/web
WEB_REPODIR ?= .
# these are verbose so multiple invocations can be spotted
WEB_SUBDIR ?= $(shell $(WEB_SOURCEDIR)/gime-git-description.sh $(WEB_REPODIR))

# shortcuts to use when web is enabled, set up to evaluate once as
# they can be a little expensive.  These make variable can only be
# used inside of WEB_ENABLED blocks.

ifdef WEB_ENABLED
ifndef WEB_HASH
WEB_HASH := $(shell cd $(WEB_REPODIR) ; git show --no-patch --format=%H HEAD)
endif
ifndef WEB_RESULTSDIR
WEB_RESULTSDIR := $(WEB_SUMMARYDIR)/$(WEB_SUBDIR)
endif
ifndef WEB_SOURCES
WEB_SOURCES := $(wildcard $(addprefix $(WEB_SOURCEDIR)/, *.css *.js *.html))
endif
ifndef WEB_TIME
WEB_TIME := $(shell $(WEB_SOURCEDIR)/now.sh)
endif
ifndef WEB_TESTSDIR
WEB_TESTSDIR := $(WEB_SUMMARYDIR)/tests
endif
endif

#
# Force the creation and/or update of the web pages
#
# Since $(WEB_SUMMARYDIR) (aka $(LSW_WEBDIR)) is created (via a
# dependency) before invoking the sub-$(MAKE), the sub-$(MAKE) will
# always see a configuration where web pages are enabled.
#
# Order matters: the results directory is created first so that so
# that the web-summarydir will pick up its contents.

web web-page: | $(WEB_SUMMARYDIR)
	$(MAKE) web-resultsdir web-summarydir

$(WEB_SUMMARYDIR):
	mkdir $(WEB_SUMMARYDIR)

#
# Build or update the web pages ready for a new test run
#
# For the results directory, just install the HTML / javascript files
# (kvmrunner.py will fill in all the json files).  For the summary
# directory, do a full update so that all the previous runs are
# included.

.PHONY: web-test-prep web-test-post web-page web
web-test-prep:
web-test-post:
ifdef WEB_ENABLED
web-test-prep: web-results-html web-summarydir web-testsdir
web-test-post: web-tests-json
endif

#
# Update the web site
#
# Well almost everything, result .json files are not updated by
# default - very slow.
#

.PHONY: web-site
web-site:

#
# Create or update just the summary web page.
#
# This is a cheap short-cut that, unlike "web", doesn't update the
# sub-directory's html.
#

.PHONY: web-summarydir
web-summarydir:

#
# Create or update a test run's results page.
#

.PHONY: web-resultsdir
web-resultsdir:

#
# Create the tests directory
#

ifdef WEB_ENABLED

web-testsdir: | $(WEB_TESTSDIR)
$(WEB_TESTSDIR):
	mkdir $@

.PHONY:
web-tests-json:
	$(WEB_SOURCEDIR)/json-tests.sh $(WEB_REPODIR) $(WEB_TESTSDIR) $(WEB_RESULTSDIR)

endif

#
# Create or update just the summary web page.
#
# This is a cheap short-cut that, unlike "web", doesn't update the
# sub-directory's html.
#

ifdef WEB_ENABLED

.PHONY: web-summary-html
web-site web-summarydir: web-summary-html
web-summary-html: $(WEB_SUMMARYDIR)/index.html
$(WEB_SUMMARYDIR)/index.html: $(WEB_SOURCES) $(WEB_SUMMARYDIR)/tsconfig.json | $(WEB_SUMMARYDIR)
	tsc --project $(WEB_SUMMARYDIR)/tsconfig.json
	cp $(filter-out %.js, $(WEB_SOURCES)) $(WEB_SUMMARYDIR)
	cp $(WEB_SOURCEDIR)/summary.html $(WEB_SUMMARYDIR)/index.html

endif

#
# Update the pooled summary (summaries.json) of all the test runs
#
# Note that $(WEB_SUMMARYDIR) may be a soft-link.
#
# Because the number of summaries can get large a FIND and not a GLOB
# is used to generate the list.

ifdef WEB_ENABLED

.PHONY: web-summaries-json
web-site web-summarydir web-summaries-json: $(WEB_SUMMARYDIR)/summaries.json
$(WEB_SUMMARYDIR)/summaries.json: $(wildcard $(WEB_SUMMARYDIR)/*/summary.json) $(WEB_SOURCEDIR)/json-summaries.sh
	: -H - follow any $(WEB_SUMMARYDIR) link
	: -maxdepth 2 - stop before $(WEB_SUMMARYDIR)/*/*/
	find -H $(WEB_SUMMARYDIR) \
		-maxdepth 2 \
		\( -type f -name summary.json -print \) \
	| $(WEB_SOURCEDIR)/json-summaries.sh $(WEB_REPODIR) - > $@.tmp
	mv $@.tmp $@

endif

#
# update the status.json
#
# no dependencies, just ensure it exists.

ifdef WEB_ENABLED

.PHONY: web-status-json
web-site web-summarydir web-status-json: $(WEB_SUMMARYDIR)/status.json
$(WEB_SUMMARYDIR)/status.json:
	$(WEB_SOURCEDIR)/json-status.sh "initialized" > $@.tmp
	mv $@.tmp $@

endif

#
# Update $(WEB_SUMMARYDIR)/commits.json database
#
# Use the generated $(WEB_HASH).json containing the details of the
# most recent commit as the target.  That way, any new commits trigger
# an update.

ifdef WEB_ENABLED
web-site web-summarydir: $(WEB_SUMMARYDIR)/commits.json
endif

WEB_COMMITSDIR = $(WEB_SUMMARYDIR)/commits

.PHONY: web-commitsdir
web-commitsdir:
	rm -rf $(WEB_COMMITSDIR)
	$(MAKE) WEB_ENABLED=true $(WEB_SUMMARYDIR)/commits.json

$(WEB_SUMMARYDIR)/commits.json: $(WEB_COMMITSDIR)/$(WEB_HASH).json $(wildcard $(WEB_COMMITSDIR)/*.json)
	: pick up all commits unconditionally and unsorted.
	find $(WEB_COMMITSDIR) -name '*.json' \
		| xargs --no-run-if-empty cat \
		| jq -s 'unique_by(.hash)' > $@.tmp
	mv $@.tmp $@

FIRST_COMMIT = $(shell set -x ; $(WEB_SOURCEDIR)/earliest-commit.sh $(WEB_SUMMARYDIR) $(WEB_REPODIR))
$(WEB_COMMITSDIR)/$(WEB_HASH).json: | $(WEB_COMMITSDIR)
	: order hashes so HEAD is last
	( cd $(WEB_REPODIR) && git rev-list --reverse $(FIRST_COMMIT)^..$(WEB_HASH) ) \
	| while read hash ; do \
		json=$(WEB_COMMITSDIR)/$${hash}.json ; \
		if test -r $${json} ; then \
			echo $${hash} ; \
		else \
			echo generating $${json} ; \
			$(WEB_SOURCEDIR)/json-commit.sh \
				$(WEB_REPODIR) $${hash} \
				> $${json}.tmp ; \
			mv $${json}.tmp $${json} ; \
		fi ; \
	done

$(WEB_COMMITSDIR): | $(WEB_SUMMARYDIR)
	mkdir $(WEB_COMMITSDIR)

#
# Update the html in all the result directories
#
# Not part of web-summarydir, web-resultsdir or web-results-html

ifdef WEB_ENABLED

WEB_RESULTS_HTML = $(wildcard $(WEB_SUMMARYDIR)/*-g*/results.html)
web-site: $(WEB_RESULTS_HTML)

$(WEB_SUMMARYDIR)/%/results.html: $(WEB_SOURCES)
	$(MAKE) web-resultsdir \
		WEB_SUMMARYDIR=$(WEB_SUMMARYDIR) WEB_RESULTSDIR=$(dir $@)

endif

#
# Conditional rules for building an individual test run's results
# page.  Requires WEB_SUMMARYDIR or WEB_RESULTSDIR.
#

ifdef WEB_ENABLED

.PHONY: web-resultsdir web-results-html web-results-json
web-resultsdir: web-results-html web-results-json
web-results-html: $(WEB_RESULTSDIR)/index.html
web-results-json: $(WEB_RESULTSDIR)/summary.json

$(WEB_RESULTSDIR)/index.html: $(WEB_SOURCES) $(WEB_RESULTSDIR)/tsconfig.json | $(WEB_RESULTSDIR)
	tsc --project $(WEB_RESULTSDIR)/tsconfig.json
	cp $(filter-out %.js, $(WEB_SOURCES)) $(WEB_RESULTSDIR)
	cp $(WEB_SOURCEDIR)/results.html $(WEB_RESULTSDIR)/index.html

$(WEB_RESULTSDIR)/summary.json: | $(WEB_RESULTSDIR)
	$(WEB_UTILSDIR)/kvmresults.py \
		--exit-ok \
		--quick \
		--test-kind '' \
		--test-status '' \
		--publish-summary $@.tmp \
		--publish-status $(WEB_SUMMARYDIR)/status.json \
		--publish-results $(WEB_RESULTSDIR) \
		--publish-hash $(WEB_HASH) \
		testing/pluto
	mv $@.tmp $@

%/tsconfig.json: $(WEB_SOURCEDIR)/tsconfig.json.in mk/web-targets.mk | %
	sed -e 's;@@DEST_DIR@@;$(realpath $(dir $@));' \
	    -e 's;@@SOURCE_DIR@@;$(realpath $(WEB_SOURCEDIR));' \
	    $(WEB_SOURCEDIR)/tsconfig.json.in \
	    > $@.tmp
	mv $@.tmp $@

$(WEB_RESULTSDIR): | $(WEB_SUMMARYDIR)
	mkdir $(WEB_RESULTSDIR)

endif

#
# update the json in all the results directories; very slow so only
# enabled when WEB_SCRATCH_REPODIR is set and things are not pointing
# at this directory.
#

ifdef WEB_ENABLED
ifdef WEB_SCRATCH_REPODIR
ifneq ($(abspath $(WEB_SCRATCH_REPODIR)),$(abspath .))

.PHONY: web-results-json
web-site web-results-json: $(sort $(wildcard $(WEB_SUMMARYDIR)/*-g*/results.json))

$(WEB_SUMMARYDIR)/%/results.json: $(WEB_UTILSDIR)/kvmresults.py $(WEB_UTILSDIR)/fab/*.py
	$(WEB_SOURCEDIR)/json-results.sh $(WEB_SCRATCH_REPODIR) $(dir $@)

endif
endif
endif

#
# Equivalent of help
#

define web-config

Web Configuration:

    The test results can be published as a web page using either of
    the make variables:

    $(call kvm-var-value,LSW_WEBDIR)
    $(call kvm-var-value,WEB_SUMMARYDIR)

        The top-level html directory containing a summary of all test
        runs.

	The results from individual test runs are stored under this
        directory.

    $(call kvm-var-value,WEB_SUBDIR)
    $(call kvm-var-value,WEB_RESULTSDIR)

        Sub-directory to store the current test run's results.

	By default, the test run's results are stored as the
	sub-directory $$(WEB_SUBDIR) under $$(WEB_SUMMARYDIR), and
	$$(WEB_SUBDIR) is formatted as TAG-OFFSET-gREV-BRANCH using
	information from $$(WEB_REPODIR)'s current commit (see also
	`git describe --long`).

    $(call kvm-var-value,WEB_REPODIR)

        The git repository to use when constructing the web pages (for
        instance the list of commits).

	By default, the current directory is used.

Internal targets:

    web-site:

        update the web site

    web-results-html:

        update the HTML files in all the test run sub-directories
	under $$(WEB_SUMMARYDIR)

    web-results-json:

        update the results.json in all the test run sub-directories
        under $$(WEB_SUMMARYDIR)

	very slow

	requires $$(WEB_SCRATCH_REPODIR) set and pointing at a
	dedicated git repository

Web targets:

    web-summarydir:

	build or update the top-level summary web page under
	$$(WEB_SUMMARYDIR) (the test run sub-directories are not
	updated, see above).

    web-resultsdir:

        build or update $$(WEB_RESULTSDIR)

    web-commitsdir:

        build or update both $$(WEB_COMMITSDIR) and
	$$(WEB_SUMMARYDIR)/commits.json

    web-page:

        build or update the web page in $(LSW_WEBDIR) including the
        results from the most recent test run

endef

.PHONY: web-config web-help
web-config web-help:
	$(info $(web-config))
