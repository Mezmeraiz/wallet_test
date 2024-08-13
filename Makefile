gen:
	@echo "* Running build runner *"
	@dart run build_runner build --delete-conflicting-outputs

ffi_gen:
	@echo "* ffi generation *"
	@dart run ffigen