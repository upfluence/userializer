.PHONY: release

release:
	BUNDLE_FROZEN=false bundle exec rake release:rubygem_push
